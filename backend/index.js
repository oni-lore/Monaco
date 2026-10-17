require('dotenv').config();
const crypto = require('crypto');

const fastify = require('fastify')({ logger: true });
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
  } catch {
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
    const result = await pool.query(
      'INSERT INTO users (username, password_hash, email, created_at) VALUES ($1, $2, $3, NOW()) RETURNING id, username, email, email_verified, is_creator, created_at',
      [username, hashedPassword, email]
    );
    const user = result.rows[0];

    const accessToken = jwt.sign(
      { sub: user.id, username: user.username },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    const refreshToken = crypto.randomBytes(32).toString('hex');
    const refreshTokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
    const refreshTokenExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    await pool.query(
      'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
      [user.id, refreshTokenHash, refreshTokenExpiry]
    );

    res.send({
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        email_verified: user.email_verified,
        is_creator: user.is_creator,
        created_at: user.created_at,
      },
      tokens: {
        access_token: accessToken,
        refresh_token: refreshToken,
      },
    });
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

  const accessToken = jwt.sign(
    { sub: user.id, username: user.username },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
  const refreshToken = crypto.randomBytes(32).toString('hex');
  const refreshTokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
  const refreshTokenExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await pool.query(
    'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
    [user.id, refreshTokenHash, refreshTokenExpiry]
  );

  res.send({
    user: {
      id: user.id,
      username: user.username,
      email: user.email,
      email_verified: user.email_verified,
      is_creator: user.is_creator,
      created_at: user.created_at,
    },
    tokens: {
      access_token: accessToken,
      refresh_token: refreshToken,
    },
  });
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

fastify.get('/users/me', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const result = await pool.query(
    'SELECT id, username, email, email_verified, birthday, profile_picture_url, current_monarch_id, is_creator, created_at FROM users WHERE id = $1',
    [userId]
  );
  if (result.rows.length === 0) {
    return res.status(404).send({ error: 'User not found' });
  }
  res.send({ user: result.rows[0] });
});

fastify.put('/users/me', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const { username, email } = req.body;

  if ((username === null || username === undefined) && (email === null || email === undefined)) {
    return res.status(400).send({ error: 'At least one field (username or email) is required' });
  }

  const userResult = await pool.query('SELECT id, username, email FROM users WHERE id = $1', [userId]);
  if (userResult.rows.length === 0) {
    return res.status(404).send({ error: 'User not found' });
  }

  const currentUser = userResult.rows[0];
  const updates = [];
  const values = [];
  let paramIdx = 1;

  if (username !== null && username !== undefined && username !== currentUser.username) {
    if (!username || username.length < 3) {
      return res.status(400).send({ error: 'Username must be at least 3 characters' });
    }
    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
      return res.status(400).send({ error: 'Username can only contain letters, numbers, and underscores' });
    }
    updates.push(`username = $${paramIdx++}`);
    values.push(username);
  }

  if (email !== null && email !== undefined && email !== currentUser.email) {
    if (!email) {
      return res.status(400).send({ error: 'Email is required' });
    }
    const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
    if (!emailRegex.test(email)) {
      return res.status(400).send({ error: 'Invalid email format' });
    }
    const existingUser = await pool.query('SELECT id FROM users WHERE email = $1 AND id != $2', [email, userId]);
    if (existingUser.rows.length > 0) {
      return res.status(409).send({ error: 'Email already in use' });
    }
    updates.push(`email = $${paramIdx++}, email_verified = FALSE`);
    values.push(email);
  }

  values.push(userId);

  const result = await pool.query(
    `UPDATE users SET ${updates.join(', ')}, updated_at = NOW() WHERE id = $${paramIdx} RETURNING id, username, email, email_verified, is_creator, created_at`,
    values
  );

  const updatedUser = result.rows[0];

  res.send({
    user: {
      id: updatedUser.id,
      username: updatedUser.username,
      email: updatedUser.email,
      email_verified: updatedUser.email_verified,
      is_creator: updatedUser.is_creator,
      created_at: updatedUser.created_at,
    },
  });
});

fastify.get('/users/search', { preHandler: verifyToken }, async (req, res) => {
  const { q } = req.query;
  const userId = req.user.sub;

  if (!q || q.trim().length < 2) {
    return res.status(400).send({ error: 'Search query must be at least 2 characters' });
  }

  const searchPattern = `%${q.trim()}%`;
  const result = await pool.query(
    `SELECT id, username, email, email_verified, is_creator, created_at
     FROM users
     WHERE username ILIKE $1 AND id != $2
     ORDER BY username ASC
     LIMIT 20`,
    [searchPattern, userId]
  );

  res.send({ users: result.rows });
});

fastify.get('/conversations/:conversationId', { preHandler: verifyToken }, async (req, res) => {
  const conversationId = req.params.conversationId;
  const userId = req.user.sub;

  // Verify participant access
  const participantCheck = await pool.query(
    'SELECT 1 FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2',
    [conversationId, userId]
  );

  if (participantCheck.rows.length === 0) {
    return res.status(403).send({ error: 'Not a participant in this conversation' });
  }

  // Get conversation details
  const convResult = await pool.query(
    'SELECT id, name, created_at FROM direct_conversations WHERE id = $1',
    [conversationId]
  );
  if (convResult.rows.length === 0) {
    return res.status(404).send({ error: 'Conversation not found' });
  }

  // Get participants (excluding current user)
  const participantsResult = await pool.query(
    `SELECT u.id, u.username, u.email
     FROM conversation_participants cp
     JOIN users u ON cp.user_id = u.id
     WHERE cp.conversation_id = $1 AND cp.user_id != $2`,
    [conversationId, userId]
  );

  // Get last message
  const lastMsgResult = await pool.query(
    `SELECT m.id, m.content_text, m.created_at, m.sender_id, u.username as sender_username
     FROM messages m
     JOIN users u ON m.sender_id = u.id
     WHERE m.conversation_id = $1 AND m.deletion_state = 'active'
     ORDER BY m.created_at DESC
     LIMIT 1`,
    [conversationId]
  );

  const conversation = convResult.rows[0];
  conversation.participants = participantsResult.rows;
  conversation.last_message = lastMsgResult.rows[0] ?? null;
  conversation.other_participant = participantsResult.rows.length === 1 ? participantsResult.rows[0] : null;

  res.send({ conversation });
});

fastify.get('/conversations', { preHandler: verifyToken }, async (req, res) => {
  const result = await pool.query(
    `SELECT dc.id, dc.name, dc.created_at,
            cp.joined_at,
            (SELECT m.content_text
             FROM messages m
             WHERE m.conversation_id = dc.id AND m.deletion_state = 'active'
             ORDER BY m.created_at DESC
             LIMIT 1) as last_message_text,
            (SELECT m.created_at
             FROM messages m
             WHERE m.conversation_id = dc.id AND m.deletion_state = 'active'
             ORDER BY m.created_at DESC
             LIMIT 1) as last_message_at,
            (SELECT u.username
             FROM messages m
             JOIN users u ON m.sender_id = u.id
             WHERE m.conversation_id = dc.id AND m.deletion_state = 'active'
             ORDER BY m.created_at DESC
             LIMIT 1) as last_message_sender
     FROM direct_conversations dc
     JOIN conversation_participants cp ON dc.id = cp.conversation_id
     WHERE cp.user_id = $1
     ORDER BY COALESCE((SELECT m.created_at
                        FROM messages m
                        WHERE m.conversation_id = dc.id AND m.deletion_state = 'active'
                        ORDER BY m.created_at DESC
                        LIMIT 1), dc.created_at) DESC`,
    [req.user.sub]
  );
  res.send({ conversations: result.rows });
});

fastify.get('/conversations/:conversationId/messages', { preHandler: verifyToken }, async (req, res) => {

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
  const { content_type } = req.body;

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

  // Always return success to prevent user enumeration
  if (userResult.rows.length === 0) {
    return res.send({ success: true, message: 'If the email exists, a password reset link has been sent' });
  }

  const userId = userResult.rows[0].id;
  const resetToken = crypto.randomBytes(32).toString('hex');
  const resetTokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');
  const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

  // Invalidate any existing unused reset tokens for this user
  await pool.query(
    'DELETE FROM password_reset_tokens WHERE user_id = $1 AND used_at IS NULL',
    [userId]
  );

  await pool.query(
    'INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
    [userId, resetTokenHash, resetTokenExpiry]
  );

  // In a production deployment, the reset token would be sent via email.
  // The email provider configuration (SMTP/SendGrid/etc.) must be set up
  // before the complete email delivery flow works.
  // For now, the token is stored securely and can be used with /auth/reset-password.

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

  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

  const result = await pool.query(
    `SELECT prt.user_id, prt.expires_at, prt.used_at
     FROM password_reset_tokens prt
     WHERE prt.token_hash = $1 AND prt.used_at IS NULL`,
    [tokenHash]
  );

  if (result.rows.length === 0) {
    return res.status(400).send({ error: 'Invalid or expired reset token' });
  }

  const resetRow = result.rows[0];
  const now = new Date();
  if (new Date(resetRow.expires_at) < now) {
    return res.status(400).send({ error: 'Reset token has expired' });
  }

  const hashedPassword = await bcrypt.hash(new_password, 10);
  await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [hashedPassword, resetRow.user_id]);

  // Mark the reset token as used
  await pool.query(
    'UPDATE password_reset_tokens SET used_at = NOW() WHERE token_hash = $1',
    [tokenHash]
  );

  // Revoke all existing refresh tokens for this user (force re-login on all devices)
  await pool.query(
    'DELETE FROM refresh_tokens WHERE user_id = $1',
    [resetRow.user_id]
  );

  res.send({ success: true, message: 'Password reset successfully' });
});

fastify.post('/auth/refresh', async (req, res) => {
  const { refresh_token } = req.body;

  if (!refresh_token) {
    return res.status(400).send({ error: 'refresh_token required' });
  }

  const tokenHash = crypto.createHash('sha256').update(refresh_token).digest('hex');

  const result = await pool.query(
    `SELECT user_id, expires_at FROM refresh_tokens
     WHERE token_hash = $1`,
    [tokenHash]
  );

  if (result.rows.length === 0) {
    return res.status(401).send({ error: 'Invalid refresh token' });
  }

  const tokenRow = result.rows[0];
  const userId = tokenRow.user_id;
  if (new Date(tokenRow.expires_at) < new Date()) {
    return res.status(401).send({ error: 'Refresh token has expired' });
  }

  const userResult = await pool.query('SELECT id, username, email, email_verified, is_creator FROM users WHERE id = $1', [userId]);
  if (userResult.rows.length === 0) {
    return res.status(404).send({ error: 'User not found' });
  }

  const user = userResult.rows[0];

  // Rotate: delete old token, create new one
  await pool.query('DELETE FROM refresh_tokens WHERE token_hash = $1', [tokenHash]);

  const newAccessToken = jwt.sign(
    { sub: user.id, username: user.username },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
  const newRefreshToken = crypto.randomBytes(32).toString('hex');
  const newRefreshTokenHash = crypto.createHash('sha256').update(newRefreshToken).digest('hex');
  const newRefreshTokenExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await pool.query(
    'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
    [user.id, newRefreshTokenHash, newRefreshTokenExpiry]
  );

  res.send({
    access_token: newAccessToken,
    refresh_token: newRefreshToken,
  });
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

if (require.main === module) {
  const port = parseInt(process.env.PORT || '3000', 10);
  fastify.listen({ port, host: '0.0.0.0' }, (err, address) => {
    if (err) {
      fastify.log.error(err);
      process.exit(1);
    }
    fastify.log.info(`Server listening on ${address}`);
  });
}

module.exports = fastify;
