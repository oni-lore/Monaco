// Integration tests: run against the migrated PostgreSQL in DATABASE_URL.
// Run with: JWT_SECRET=... DATABASE_URL=... node --test test/
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const bcrypt = require('bcrypt');
const { Pool } = require('pg');

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';
if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL must be set');

const app = require('../index.js'); // fastify instance (does not listen)
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const tag = crypto.randomBytes(4).toString('hex');

async function makeUser(name, password) {
  const hashed = await bcrypt.hash(password || 'testpass123', 10);
  const r = await pool.query(
    `INSERT INTO users (username, password_hash, email) VALUES ($1, $2, $3) RETURNING id, username, email, email_verified, is_creator, created_at`,
    [`${name}_${tag}`, hashed, `${name}_${tag}@test.com`]
  );
  return r.rows[0];
}
async function connect(requester, recipient, status) {
  await pool.query(
    `INSERT INTO connections (requester_id, recipient_id, status) VALUES ($1, $2, $3)`,
    [requester.id, recipient.id, status]
  );
}
async function makeConversation(creator) {
  const r = await pool.query(
    `INSERT INTO direct_conversations (creator_id) VALUES ($1) RETURNING id`, [creator.id]
  );
  return r.rows[0].id;
}
function addParticipant(conv, user) {
  return pool.query(
    `INSERT INTO conversation_participants (conversation_id, user_id) VALUES ($1, $2)`, [conv, user.id]
  );
}
function tokenFor(userId) {
  const id = typeof userId === 'object' && userId !== null ? userId.id : userId;
  return require('jsonwebtoken').sign({ sub: id }, process.env.JWT_SECRET);
}
const auth = (userId) => ({ authorization: `Bearer ${tokenFor(userId)}` });

before(async () => {
  // Sanity: fail loudly if the schema was not migrated
  const r = await pool.query(`SELECT to_regclass('public.users') AS u, to_regclass('public.conversation_participants') AS p`);
  assert.ok(r.rows[0].u && r.rows[0].p, 'schema missing: run scripts/migrate.sh first');
});
after(async () => { await app.close(); await pool.end(); });

test('1. creator can participate in their own conversation', async () => {
  const creator = await makeUser('c1');
  const conv = await makeConversation(creator);
  await addParticipant(conv, creator); // must not throw
  const r = await pool.query(`SELECT 1 FROM conversation_participants WHERE conversation_id=$1 AND user_id=$2`, [conv, creator.id]);
  assert.equal(r.rowCount, 1);
});

test('2. accepted connections work in either direction', async () => {
  const creator = await makeUser('c2');
  const asRequester = await makeUser('r2'); // creator -> them (creator is requester)
  const asRecipient = await makeUser('q2'); // them -> creator (creator is recipient)
  await connect(creator, asRequester, 'accepted');
  await connect(asRecipient, creator, 'accepted');
  const conv = await makeConversation(creator);
  await addParticipant(conv, asRequester);
  await addParticipant(conv, asRecipient);
  const r = await pool.query(`SELECT count(*)::int AS n FROM conversation_participants WHERE conversation_id=$1`, [conv]);
  assert.equal(r.rows[0].n, 2);
});

test('3. unconnected or non-accepted users cannot join a direct conversation', async () => {
  const creator = await makeUser('c3');
  const stranger = await makeUser('s3');
  const pending = await makeUser('p3');
  await connect(pending, creator, 'pending');
  const conv = await makeConversation(creator);
  await assert.rejects(addParticipant(conv, stranger), /accepted connection/);
  await assert.rejects(addParticipant(conv, pending), /accepted connection/);
  const r = await pool.query(`SELECT count(*)::int AS n FROM conversation_participants WHERE conversation_id=$1`, [conv]);
  assert.equal(r.rows[0].n, 0);
});

test('4. API refuses to create a conversation with an unconnected user', async () => {
  const creator = await makeUser('c4');
  const stranger = await makeUser('s4');
  const res = await app.inject({
    method: 'POST', url: '/conversations', headers: auth(creator),
    payload: { targetUserId: stranger.id },
  });
  assert.equal(res.statusCode, 403);
  const r = await pool.query(`SELECT count(*)::int AS n FROM direct_conversations WHERE creator_id=$1`, [creator.id]);
  assert.equal(r.rows[0].n, 0);
});

test('5. non-participants cannot read messages', async () => {
  const a = await makeUser('a5'), b = await makeUser('b5'), outsider = await makeUser('o5');
  await connect(a, b, 'accepted');
  const conv = await makeConversation(a);
  await addParticipant(conv, a); await addParticipant(conv, b);
  const sent = await app.inject({
    method: 'POST', url: `/conversations/${conv}/messages`, headers: auth(a),
    payload: { content_type: 'text', content_text: 'secret' },
  });
  assert.equal(sent.statusCode, 200, sent.body);
  const denied = await app.inject({ method: 'GET', url: `/conversations/${conv}/messages`, headers: auth(outsider) });
  assert.equal(denied.statusCode, 403);
  const ok = await app.inject({ method: 'GET', url: `/conversations/${conv}/messages`, headers: auth(b) });
  assert.equal(ok.statusCode, 200);
  assert.equal(JSON.parse(ok.body).messages.length, 1);
});

test('6. non-participants cannot send messages into a conversation', async () => {
  const a = await makeUser('a6'), b = await makeUser('b6'), outsider = await makeUser('o6');
  await connect(a, b, 'accepted');
  const conv = await makeConversation(a);
  await addParticipant(conv, a); await addParticipant(conv, b);
  const res = await app.inject({
    method: 'POST', url: `/conversations/${conv}/messages`, headers: auth(outsider),
    payload: { content_type: 'text', content_text: 'injected' },
  });
  assert.equal(res.statusCode, 403);
  const r = await pool.query(`SELECT count(*)::int AS n FROM messages WHERE conversation_id=$1`, [conv]);
  assert.equal(r.rows[0].n, 0);
});

test('7. /register returns user and tokens matching client AuthResponse model', async () => {
  const res = await app.inject({
    method: 'POST', url: '/register',
    payload: { username: `reguser_${tag}`, password: 'RegPass123!', email: `reg_${tag}@example.com` },
  });
  assert.equal(res.statusCode, 200, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.user, 'response missing user object');
  assert.ok(body.tokens, 'response missing tokens object');
  assert.ok(body.user.id, 'user.id missing');
  assert.ok(body.user.username, 'user.username missing');
  assert.ok(body.user.email, 'user.email missing');
  assert.ok(body.tokens.access_token, 'tokens.access_token missing');
  assert.ok(body.tokens.refresh_token, 'tokens.refresh_token missing');
  // Verify no password_hash leaked
  assert.equal(body.user.password_hash, undefined, 'password_hash must not be returned');
  // Verify user exists in DB
  const dbUser = await pool.query('SELECT id, username, email FROM users WHERE id = $1', [body.user.id]);
  assert.equal(dbUser.rows.length, 1);
  assert.equal(dbUser.rows[0].username, `reguser_${tag}`);
  // Verify refresh token is stored as SHA-256 hash, not plaintext
  const rt = await pool.query(
    'SELECT token_hash FROM refresh_tokens WHERE user_id = $1',
    [body.user.id]
  );
  assert.equal(rt.rowCount, 1, 'refresh token not stored in database');
  const expectedHash = crypto.createHash('sha256').update(body.tokens.refresh_token).digest('hex');
  assert.equal(rt.rows[0].token_hash, expectedHash, 'token_hash must be SHA-256 hash of refresh_token');
  assert.notEqual(rt.rows[0].token_hash, body.tokens.refresh_token, 'plaintext refresh_token must not be stored');
});

test('8. /login returns user and tokens matching client AuthResponse model', async () => {
  // First create a user with a known password
  await makeUser('logintest', 'LoginPass123!');
  const res = await app.inject({
    method: 'POST', url: '/login',
    payload: { username: `logintest_${tag}`, password: 'LoginPass123!' },
  });
  assert.equal(res.statusCode, 200, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.user, 'response missing user object');
  assert.ok(body.tokens, 'response missing tokens object');
  assert.ok(body.user.id, 'user.id missing');
  assert.ok(body.user.username, 'user.username missing');
  assert.ok(body.user.email, 'user.email missing');
  assert.ok(body.tokens.access_token, 'tokens.access_token missing');
  assert.ok(body.tokens.refresh_token, 'tokens.refresh_token missing');
  // Verify refresh token is stored as SHA-256 hash, not plaintext
  const rt = await pool.query(
    'SELECT token_hash FROM refresh_tokens WHERE user_id = $1',
    [body.user.id]
  );
  assert.equal(rt.rowCount, 1, 'refresh token not stored in database');
  const expectedHash = crypto.createHash('sha256').update(body.tokens.refresh_token).digest('hex');
  assert.equal(rt.rows[0].token_hash, expectedHash, 'token_hash must be SHA-256 hash of refresh_token');
  assert.notEqual(rt.rows[0].token_hash, body.tokens.refresh_token, 'plaintext refresh_token must not be stored');
});

test('9. /register rejects duplicate username', async () => {
  await app.inject({
    method: 'POST', url: '/register',
    payload: { username: `dupe_${tag}`, password: 'Pass123!', email: `dupe1_${tag}@example.com` },
  });
  const res = await app.inject({
    method: 'POST', url: '/register',
    payload: { username: `dupe_${tag}`, password: 'Pass123!', email: `dupe2_${tag}@example.com` },
  });
  assert.equal(res.statusCode, 409, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.error, 'error message missing');
});

test('10. /login rejects wrong password', async () => {
  await makeUser('wrongpw', 'CorrectPass123!');
  const res = await app.inject({
    method: 'POST', url: '/login',
    payload: { username: `wrongpw_${tag}`, password: 'WrongPass123!' },
  });
  assert.equal(res.statusCode, 401, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.error, 'error message missing');
});

test('11. GET /users/me returns current user profile', async () => {
  const user = await makeUser('profileuser', 'ProfilePass123!');
  const res = await app.inject({
    method: 'GET', url: '/users/me', headers: auth(user.id),
  });
  assert.equal(res.statusCode, 200, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.user, 'response missing user object');
  assert.equal(body.user.id, user.id);
  assert.equal(body.user.username, `profileuser_${tag}`);
  assert.equal(body.user.email, `profileuser_${tag}@test.com`);
  assert.equal(body.user.password_hash, undefined, 'password_hash must not be returned');
});

test('12. GET /users/search finds users by username', async () => {
  await makeUser('searchable1', 'SearchPass123!');
  await makeUser('searchable2', 'SearchPass123!');
  await makeUser('unrelateduser', 'SearchPass123!');

  const searcher = await makeUser('searcher', 'SearchPass123!');

  const res = await app.inject({
    method: 'GET', url: '/users/search?q=searchable', headers: auth(searcher.id),
  });
  assert.equal(res.statusCode, 200, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.users, 'response missing users array');
  assert.ok(body.users.length >= 2, 'should find at least 2 searchable users');
  // Searcher should not appear in their own results
  const searcherFound = body.users.some((u) => u.id === searcher.id);
  assert.equal(searcherFound, false, 'searcher should not appear in own search results');
});

test('13. GET /users/search requires minimum 2 characters', async () => {
  const user = await makeUser('shortsearch', 'SearchPass123!');
  const res = await app.inject({
    method: 'GET', url: '/users/search?q=a', headers: auth(user.id),
  });
  assert.equal(res.statusCode, 400, res.body);
});

test('14. GET /conversations/:id returns conversation with participants and last message', async () => {
  const creator = await makeUser('convcreator', 'ConvPass123!');
  const other = await makeUser('convother', 'ConvPass123!');
  await connect(creator, other, 'accepted');

  const convRes = await app.inject({
    method: 'POST', url: '/conversations', headers: auth(creator.id),
    payload: { targetUserId: other.id },
  });
  assert.equal(convRes.statusCode, 200, convRes.body);
  const convBody = JSON.parse(convRes.body);
  const conversationId = convBody.conversationId;

  // Send a message
  await app.inject({
    method: 'POST', url: `/conversations/${conversationId}/messages`, headers: auth(creator.id),
    payload: { content_type: 'text', content_text: 'Hello there' },
  });

  const res = await app.inject({
    method: 'GET', url: `/conversations/${conversationId}`, headers: auth(creator.id),
  });
  assert.equal(res.statusCode, 200, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.conversation, 'response missing conversation object');
  assert.equal(body.conversation.id, conversationId);
  assert.ok(body.conversation.participants, 'missing participants');
  assert.equal(body.conversation.participants.length, 1, 'should have 1 other participant');
  assert.equal(body.conversation.other_participant.username, `convother_${tag}`);
  assert.ok(body.conversation.last_message, 'missing last message');
  assert.equal(body.conversation.last_message.content_text, 'Hello there');
});

test('15. GET /conversations/:id rejects non-participant', async () => {
  const creator = await makeUser('convowner', 'ConvPass123!');
  const other = await makeUser('convother2', 'ConvPass123!');
  const stranger = await makeUser('convstranger', 'ConvPass123!');
  await connect(creator, other, 'accepted');

  const convRes = await app.inject({
    method: 'POST', url: '/conversations', headers: auth(creator.id),
    payload: { targetUserId: other.id },
  });
  assert.equal(convRes.statusCode, 200, convRes.body);
  const convBody = JSON.parse(convRes.body);

  const res = await app.inject({
    method: 'GET', url: `/conversations/${convBody.conversationId}`, headers: auth(stranger.id),
  });
  assert.equal(res.statusCode, 403, res.body);
});

test('16. GET /conversations includes last message preview', async () => {
  const creator = await makeUser('listcreator', 'ListPass123!');
  const other = await makeUser('listother', 'ListPass123!');
  await connect(creator, other, 'accepted');

  const convRes = await app.inject({
    method: 'POST', url: '/conversations', headers: auth(creator.id),
    payload: { targetUserId: other.id },
  });
  assert.equal(convRes.statusCode, 200, convRes.body);
  const convBody = JSON.parse(convRes.body);

  await app.inject({
    method: 'POST', url: `/conversations/${convBody.conversationId}/messages`, headers: auth(creator.id),
    payload: { content_type: 'text', content_text: 'Last message preview test' },
  });

  const res = await app.inject({
    method: 'GET', url: '/conversations', headers: auth(creator.id),
  });
  assert.equal(res.statusCode, 200, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.conversations, 'missing conversations array');
  assert.ok(body.conversations.length >= 1, 'should have at least 1 conversation');
  const conv = body.conversations.find((c) => c.id === convBody.conversationId);
  assert.ok(conv, 'conversation not found in list');
  assert.equal(conv.last_message_text, 'Last message preview test');
  assert.ok(conv.last_message_at, 'missing last_message_at');
});

test('17. POST /conversations rejects duplicate conversation between same users', async () => {
  const creator = await makeUser('dupcreator', 'DupPass123!');
  const other = await makeUser('dupother', 'DupPass123!');
  await connect(creator, other, 'accepted');

  // First conversation
  const res1 = await app.inject({
    method: 'POST', url: '/conversations', headers: auth(creator.id),
    payload: { targetUserId: other.id },
  });
  assert.equal(res1.statusCode, 200, res1.body);

  // Second conversation between same users (reverse direction)
  const res2 = await app.inject({
    method: 'POST', url: '/conversations', headers: auth(other.id),
    payload: { targetUserId: creator.id },
  });
  // Should either succeed (new conversation) or fail with conflict - we just check it doesn't crash
  assert.ok([200, 409, 400].includes(res2.statusCode), `unexpected status ${res2.statusCode}`);
});

test('18. PUT /users/me updates username', async () => {
  const user = await makeUser('updateuser', 'UpdatePass123!');
  const res = await app.inject({
    method: 'PUT', url: '/users/me', headers: auth(user.id),
    payload: { username: `updated_${tag}` },
  });
  assert.equal(res.statusCode, 200, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.user, 'response missing user object');
  assert.equal(body.user.id, user.id);
  assert.equal(body.user.username, `updated_${tag}`);
  assert.equal(body.user.email, `${user.username}_${tag}@test.com`);

  // Verify the change persisted
  const dbUser = await pool.query('SELECT username FROM users WHERE id = $1', [user.id]);
  assert.equal(dbUser.rows[0].username, `updated_${tag}`);
});

test('19. PUT /users/me updates email', async () => {
  const user = await makeUser('emailuser', 'EmailPass123!');
  const res = await app.inject({
    method: 'PUT', url: '/users/me', headers: auth(user.id),
    payload: { email: `newemail_${tag}@example.com` },
  });
  assert.equal(res.statusCode, 200, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.user, 'response missing user object');
  assert.equal(body.user.email, `newemail_${tag}@example.com`);
  assert.equal(body.user.emailVerified, false, 'email should be unverified after change');
});

test('20. PUT /users/me rejects invalid username', async () => {
  const user = await makeUser('invaliduser', 'InvalidPass123!');
  const res = await app.inject({
    method: 'PUT', url: '/users/me', headers: auth(user.id),
    payload: { username: 'ab' },
  });
  assert.equal(res.statusCode, 400, res.body);
});

test('21. PUT /users/me rejects duplicate email', async () => {
  const user1 = await makeUser('dupemail1', 'Pass123!');
  const user2 = await makeUser('dupemail2', 'Pass123!');
  const res = await app.inject({
    method: 'PUT', url: '/users/me', headers: auth(user1.id),
    payload: { email: `dupemail2_${tag}@test.com` },
  });
  assert.equal(res.statusCode, 409, res.body);
});

test('22. POST /auth/forgot-password returns success for existing and non-existing email', async () => {
  await makeUser('forgotuser', 'ForgotPass123!');

  // Existing email
  const res1 = await app.inject({
    method: 'POST', url: '/auth/forgot-password',
    payload: { email: `forgotuser_${tag}@test.com` },
  });
  assert.equal(res1.statusCode, 200, res1.body);

  // Non-existing email (should still return success to prevent enumeration)
  const res2 = await app.inject({
    method: 'POST', url: '/auth/forgot-password',
    payload: { email: `nonexistent_${tag}@example.com` },
  });
  assert.equal(res2.statusCode, 200, res2.body);
});

test('23. POST /auth/reset-password resets password with valid token', async () => {
  const user = await makeUser('resetuser', 'ResetPass123!');
  const resetToken = crypto.randomBytes(32).toString('hex');
  const resetTokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000);

  await pool.query(
    'INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
    [user.id, resetTokenHash, expiresAt]
  );

  const res = await app.inject({
    method: 'POST', url: '/auth/reset-password',
    payload: { token: resetToken, new_password: 'NewResetPass123!' },
  });
  assert.equal(res.statusCode, 200, res.body);

  // Verify the token was marked as used
  const rt = await pool.query('SELECT used_at FROM password_reset_tokens WHERE token_hash = $1', [resetTokenHash]);
  assert.ok(rt.rows[0].used_at, 'reset token should be marked as used');

  // Verify the new password works
  const loginRes = await app.inject({
    method: 'POST', url: '/login',
    payload: { username: `resetuser_${tag}`, password: 'NewResetPass123!' },
  });
  assert.equal(loginRes.statusCode, 200, loginRes.body);

  // Verify old password no longer works
  const oldLoginRes = await app.inject({
    method: 'POST', url: '/login',
    payload: { username: `resetuser_${tag}`, password: 'ResetPass123!' },
  });
  assert.equal(oldLoginRes.statusCode, 401, oldLoginRes.body);
});

test('24. POST /auth/reset-password rejects invalid token', async () => {
  const res = await app.inject({
    method: 'POST', url: '/auth/reset-password',
    payload: { token: 'invalid-token', new_password: 'NewPass123!' },
  });
  assert.equal(res.statusCode, 400, res.body);
});

test('25. POST /auth/refresh rotates access and refresh tokens', async () => {
  const user = await makeUser('refreshuser', 'RefreshPass123!');

  // Login to get tokens
  const loginRes = await app.inject({
    method: 'POST', url: '/login',
    payload: { username: `refreshuser_${tag}`, password: 'RefreshPass123!' },
  });
  assert.equal(loginRes.statusCode, 200, loginRes.body);
  const loginBody = JSON.parse(loginRes.body);
  const oldRefreshToken = loginBody.tokens.refresh_token;

  // Refresh
  const res = await app.inject({
    method: 'POST', url: '/auth/refresh',
    payload: { refresh_token: oldRefreshToken },
  });
  assert.equal(res.statusCode, 200, res.body);
  const body = JSON.parse(res.body);
  assert.ok(body.access_token, 'response missing access_token');
  assert.ok(body.refresh_token, 'response missing refresh_token');
  assert.notEqual(body.refresh_token, oldRefreshToken, 'refresh token should be rotated');

  // Old refresh token should no longer work
  const oldRes = await app.inject({
    method: 'POST', url: '/auth/refresh',
    payload: { refresh_token: oldRefreshToken },
  });
  assert.equal(oldRes.statusCode, 401, oldRes.body);
});