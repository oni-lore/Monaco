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
    [requester, recipient, status]
  );
}
async function makeConversation(creator) {
  const r = await pool.query(
    `INSERT INTO direct_conversations (creator_id) VALUES ($1) RETURNING id`, [creator]
  );
  return r.rows[0].id;
}
function addParticipant(conv, user) {
  return pool.query(
    `INSERT INTO conversation_participants (conversation_id, user_id) VALUES ($1, $2)`, [conv, user]
  );
}
function tokenFor(userId) {
  return require('jsonwebtoken').sign({ sub: userId }, process.env.JWT_SECRET);
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
  const r = await pool.query(`SELECT 1 FROM conversation_participants WHERE conversation_id=$1 AND user_id=$2`, [conv, creator]);
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
    payload: { targetUserId: stranger },
  });
  assert.equal(res.statusCode, 403);
  const r = await pool.query(`SELECT count(*)::int AS n FROM direct_conversations WHERE creator_id=$1`, [creator]);
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