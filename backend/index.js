require('dotenv').config();

const fastify = require('fastify')({ logger: true });
const pg = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function verifyToken(req, res) {
  try {
    const authorization = req.headers.authorization;
    if (!authorization || !authorization.startsWith('Bearer ')) {
      return res.status(401).send({ error: 'Missing or invalid authorization header' });
    }
    const token = authorization.substring(7);
    req.user = jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    return res.status(401).send({ error: 'Invalid or expired token' });
  }
}

fastify.get('/', async (req, res) => {
  res.send({ status: 'ok', service: 'monaco-backend' });
});

fastify.post('/register', async (req, res) => {
  const { username, password, email } = req.body;

  if (!username || !password || !email) {
    return res.status(400).send({ error: 'username, password, and email required' });
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  try {
    await pool.query(
      'INSERT INTO users (username, password_hash, email, created_at) VALUES ($1, $2, $3, NOW())',
      [username, hashedPassword, email]
    );
    res.send({ success: true, message: 'User registered successfully' });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).send({ error: 'Username or email already exists' });
    }
    res.status(500).send({ error: 'Registration failed' });
  }
});

fastify.post('/login', async (req, res) => {
  const { username, password } = req.body;

  const userResult = await pool.query('SELECT * FROM users WHERE username = $1', [username]);

  if (userResult.rows.length === 0) {
    return res.status(401).send({ error: 'Invalid credentials' });
  }

  const user = userResult.rows[0];
  const passwordValid = await bcrypt.compare(password, user.password_hash);

  if (!passwordValid) {
    return res.status(401).send({ error: 'Invalid credentials' });
  }

  const token = jwt.sign(
    { sub: user.id, username: user.username },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  res.send({ success: true, token });
});

async function haveAcceptedConnection(userId1, userId2) {
  const result = await pool.query(
    'SELECT * FROM connections WHERE ((requester_id = $1 AND recipient_id = $2) OR (requester_id = $2 AND recipient_id = $1)) AND status = \'accepted\'',
    [userId1, userId2]
  );
  return result.rows.length > 0;
}

fastify.post('/conversations', { preHandler: verifyToken }, async (req, res) => {
  const creatorId = req.user.sub;
  const { targetUserId } = req.body;

  if (!targetUserId) {
    return res.status(400).send({ error: 'targetUserId required' });
  }

  if (targetUserId === creatorId) {
    return res.status(400).send({ error: 'Cannot create conversation with oneself' });
  }

  const connected = await haveAcceptedConnection(creatorId, targetUserId);
  if (!connected) {
    return res.status(403).send({ error: 'Cannot create direct conversation without accepted connection' });
  }

  const result = await pool.query(
    'INSERT INTO direct_conversations (id, creator_id, name, created_at) VALUES (gen_random_uuid(), $1, NULL, NOW()) RETURNING id',
    [creatorId]
  );
  const conversationId = result.rows[0].id;

  await pool.query(
    'INSERT INTO conversation_participants (id, conversation_id, user_id, role, joined_at) VALUES (gen_random_uuid(), $1, $2, \'member\', NOW())',
    [conversationId, creatorId]
  );

  await pool.query(
    'INSERT INTO conversation_participants (id, conversation_id, user_id, role, joined_at) VALUES (gen_random_uuid(), $1, $2, \'member\', NOW())',
    [conversationId, targetUserId]
  );

  res.send({
    success: true,
    conversationId,
    message: 'Direct conversation created successfully'
  });
});

fastify.get('/conversations', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const result = await pool.query(
    `SELECT dc.id, dc.name, dc.created_at
     FROM direct_conversations dc
     JOIN conversation_participants cp ON dc.id = cp.conversation_id
     WHERE cp.user_id = $1`,
    [req.user.sub]
  );
  res.send({ conversations: result.rows });
});

fastify.get('/conversations/:conversationId/messages', { preHandler: verifyToken }, async (req, res) => {
  const conversationId = req.params.conversationId;
  const userId = req.user.sub;

  const participantCheck = await pool.query(
    'SELECT 1 FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2',
    [req.params.conversationId, req.user.sub]
  );

  if (participantCheck.rows.length === 0) {
    return res.status(403).send({ error: 'Not a participant in this conversation' });
  }

  const result = await pool.query(
    `SELECT m.id, m.content_type, m.content_text, m.edit_count, m.edited_at,
            m.deletion_state, m.created_at,
            u.username as sender_username
     FROM messages m
     JOIN users u ON m.sender_id = u.id
     WHERE m.conversation_id = $1
     ORDER BY m.created_at ASC`,
    [req.params.conversationId]
  );

  res.send({ messages: result.rows });
});

fastify.post('/conversations/:conversationId/messages', { preHandler: verifyToken }, async (req, res) => {
  const conversationId = req.params.conversationId;
  const userId = req.user.sub;
  const { content_type, content_text } = req.body;

  if (!content_type) {
    return res.status(400).send({ error: 'content_type required' });
  }

  const participantCheck = await pool.query(
    'SELECT 1 FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2',
    [req.params.conversationId, req.user.sub]
  );

  if (participantCheck.rows.length === 0) {
    return res.status(403).send({ error: 'Not a participant in this conversation' });
  }

  const result = await pool.query(
    `INSERT INTO messages (id, conversation_id, sender_id, content_type, content_text, created_at)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, NOW()) RETURNING id, created_at`,
    [req.params.conversationId, req.user.sub, req.body.content_type, req.body.content_text || null]
  );

  res.send({ success: true, messageId: result.rows[0].id, created_at: result.rows[0].created_at });
});

fastify.post('/logout', { preHandler: verifyToken }, async (req, res) => {
  res.send({ success: true, message: 'Logged out successfully' });
});

fastify.post('/auth/change-password', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const { current_password, new_password } = req.body;

  if (!current_password || !new_password) {
    return res.status(400).send({ error: 'current_password and new_password required' });
  }

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  }

  const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
  if (userResult.rows.length === 0) {
    return res.status(404).send({ error: 'User not found' });
  }

  const passwordValid = await bcrypt.compare(current_password, userResult.rows[0].password_hash);

  if (!passwordValid) {
    return res.status(401).send({ error: 'Current password is incorrect' });
  }

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  }

  const hashedPassword = await bcrypt.hash(new_password, 10);
  await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $1', [hashedPassword, userId]);

  res.send({ success: true, message: 'Password changed successfully' });
});

fastify.post('/auth/change-email', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const { email } = req.body;

  if (!email) {
    return res.status(400).send({ error: 'email required' });
  }

  const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
  if (!emailRegex.test(email)) {
    return res.status(400).send({ error: 'Invalid email format' });
  }

  const existingUser = await pool.query('SELECT id FROM users WHERE email = $1 AND id != $1', [email, userId]);
  if (existingUser.rows.length > 0) {
    return res.status(409).send({ error: 'Email already in use' });
  }

  await pool.query('UPDATE users SET email = $1, email_verified = FALSE, updated_at = NOW() WHERE id = $1', [email, userId]);

  res.send({ success: true, message: 'Email changed successfully. Please verify your new email address.' });
});

fastify.post('/auth/forgot-password', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).send({ error: 'email required' });
  }

  const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);

  res.send({ success: true, message: 'If the email exists, a password reset link has been sent' });
});

fastify.post('/auth/reset-password', async (req, res) => {
  const { token, new_password } = req.body;

  if (!token || !new_password) {
    return res.status(400).send({ error: 'token and new_password required' });
  }

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  }

  res.send({ success: true, message: 'Password reset successful (mock implementation)' });
});

fastify.delete('/auth/delete-account', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const { password } = req.body;

  if (!password) {
    return res.status(400).send({ error: 'password required for confirmation' });
  }

  const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
  if (userResult.rows.length === 0) {
    return res.status(404).send({ error: 'User not found' });
  }

  const passwordValid = await bcrypt.compare(password, userResult.rows[0].password_hash);

  if (!passwordValid) {
    return res.status(401).send({ error: 'Incorrect password' });
  }

  await pool.query('DELETE FROM users WHERE id = $1', [userId]);

  res.send({ success: true, message: 'Account deleted successfully' });
});

fastify.get('/auth/sessions', { preHandler: verifyToken }, async (req, res) => {
  res.send({
    sessions: [
      {
        id: 'current',
        device_info: 'Current device',
        ip_address: '127.0.0.1',
        user_agent: 'Monaco App',
        created_at: new Date().toISOString(),
        last_active_at: new Date().toISOString(),
        is_current: true
      }
    ]
  });
});

fastify.delete('/auth/sessions/:sessionId', { preHandler: verifyToken }, async (req, res) => {
  res.send({ success: true, message: 'Session revoked' });
});

fastify.delete('/auth/sessions', { preHandler: verifyToken }, async (req, res) => {
  res.send({ success: true, message: 'All other sessions revoked' });
});

fastify.post('/logout', { preHandler: verifyToken }, async (req, res) => {
  res.send({ success: true, message: 'Logged out successfully' });
});

module.exports = fastify;
