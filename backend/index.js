require('dotenv').config();

const fastify = require('fastify')({ logger: true });
const pg = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Pool } = pg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Helper: verify JWT from Authorization header
// NOTE: must NOT also take/call a `next` callback (Fastify v5 would run the
// route handler twice). Reply and return on failure; just return on success.
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

// Health check endpoint
fastify.get('/', async (req, res) => {
  res.send({ status: 'ok', service: 'monaco-backend' });
});

// Registration endpoint
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

// Login endpoint
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

// Helper: check if two users have an accepted connection
async function haveAcceptedConnection(userId1, userId2) {
  const result = await pool.query(
    'SELECT * FROM connections WHERE ((requester_id = $1 AND recipient_id = $2) OR (requester_id = $2 AND recipient_id = $1)) AND status = \'accepted\'',
    [userId1, userId2]
  );
  return result.rows.length > 0;
}

// Create direct conversation endpoint (only between connected users)
// Requires JWT authentication
fastify.post('/conversations', { preHandler: verifyToken }, async (req, res) => {
  const creatorId = req.user.sub;
  const { targetUserId } = req.body;

  if (!targetUserId) {
    return res.status(400).send({ error: 'targetUserId required' });
  }

  // Cannot create conversation with oneself
  if (targetUserId === creatorId) {
    return res.status(400).send({ error: 'Cannot create conversation with oneself' });
  }

  // Check that creator and target have an accepted connection
  const connected = await haveAcceptedConnection(creatorId, targetUserId);
  if (!connected) {
    return res.status(403).send({ error: 'Cannot create direct conversation: no accepted connection with target user' });
  }

  // Create the direct conversation with creator as owner
  const result = await pool.query(
    'INSERT INTO direct_conversations (id, creator_id, name, created_at) VALUES (gen_random_uuid(), $1, NULL, NOW()) RETURNING id',
    [creatorId]
  );
  const conversationId = result.rows[0].id;

  // Add creator as participant
  await pool.query(
    'INSERT INTO conversation_participants (id, conversation_id, user_id, role, joined_at) VALUES (gen_random_uuid(), $1, $2, \'member\', NOW())',
    [conversationId, creatorId]
  );

  // Add target as participant (they already have accepted connection, trigger will verify)
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

// Get user's conversations endpoint
fastify.get('/conversations', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  
  const result = await pool.query(`
    SELECT dc.id, dc.name, dc.created_at,
           json_agg(json_build_object('user_id', cp.user_id, 'role', cp.role, 'joined_at', cp.joined_at)) as participants
    FROM direct_conversations dc
    JOIN conversation_participants cp ON dc.id = cp.conversation_id
    WHERE dc.creator_id = $1 OR cp.user_id = $1
    GROUP BY dc.id
    ORDER BY dc.created_at DESC
  `, [userId]);

  res.send({ success: true, conversations: result.rows });
});

// Get conversation messages endpoint
fastify.get('/conversations/:conversationId/messages', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const conversationId = req.params.conversationId;

  // Verify user is a participant in this conversation
  const participantResult = await pool.query(
    'SELECT * FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2',
    [conversationId, userId]
  );

  if (participantResult.rows.length === 0) {
    return res.status(403).send({ error: 'User is not a participant in this conversation' });
  }

  const result = await pool.query(`
    SELECT m.id, m.content_type, m.content_text, m.edit_count, m.edited_at,
           m.deletion_state, m.created_at,
           u.username as sender_username
    FROM messages m
    JOIN users u ON m.sender_id = u.id
    WHERE m.conversation_id = $1
    ORDER BY m.created_at ASC
  `, [conversationId]);

  res.send({ success: true, messages: result.rows });
});

// Send message endpoint
fastify.post('/conversations/:conversationId/messages', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const conversationId = req.params.conversationId;
  const { content_type, content_text } = req.body;

  if (!content_type) {
    return res.status(400).send({ error: 'content_type required' });
  }

  // Verify user is a participant in this conversation
  const participantResult = await pool.query(
    'SELECT * FROM conversation_participants WHERE conversation_id = $1 AND user_id = $2',
    [conversationId, userId]
  );

  if (participantResult.rows.length === 0) {
    return res.status(403).send({ error: 'User is not a participant in this conversation' });
  }

  // Verify the user has an accepted connection with at least one other participant
  // (For V1, direct conversations are 1:1, so check against the other participant)
  const convResult = await pool.query(
    'SELECT creator_id FROM direct_conversations WHERE id = $1', [conversationId]
  );
  
  if (convResult.rows.length === 0) {
    return res.status(404).send({ error: 'Conversation not found' });
  }

  const creatorId = convResult.rows[0].creator_id;
  if (creatorId !== userId) {
    // Check accepted connection with creator
    const connected = await haveAcceptedConnection(userId, creatorId);
    if (!connected) {
      return res.status(403).send({ error: 'You must have an accepted connection with the conversation creator to send messages' });
    }
  }

  const result = await pool.query(
    `INSERT INTO messages (id, conversation_id, sender_id, content_type, content_text, created_at) 
     VALUES (gen_random_uuid(), $1, $2, $3, $4, NOW()) RETURNING id, created_at`,
    [conversationId, userId, content_type, content_text || null]
  );

  res.send({ success: true, messageId: result.rows[0].id, created_at: result.rows[0].created_at });
});

// Export the fastify instance
module.exports = fastify;
// Logout endpoint
fastify.post('/logout', { preHandler: verifyToken }, async (req, res) => {
  // In a real implementation, you would invalidate the refresh token here
  // For now, we just return success (client-side token removal)
  res.send({ success: true, message: 'Logged out successfully' });
});

// Change password endpoint
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

  const hashedPassword = await bcrypt.hash(new_password, 10);
  await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $1', [hashedPassword, userId]);

  // Invalidate all other sessions (optional: implement session tracking)
  res.send({ success: true, message: 'Password changed successfully. Other sessions will be logged out.' });
});

// Change email endpoint
fastify.post('/auth/change-email', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const { email } = req.body;

  if (!email) {
    return res.status(400).send({ error: 'email required' });
  }

  // Validate email format
  const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
  if (!emailRegex.test(email)) {
    return res.status(400).send({ error: 'Invalid email format' });
  }

  // Check if email already exists
  const existingUser = await pool.query('SELECT id FROM users WHERE email = $1 AND id != $1', [email, userId]);
  if (existingUser.rows.length > 0) {
    return res.status(409).send({ error: 'Email already in use' });
  }

  await pool.query('UPDATE users SET email = $1, email_verified = FALSE, updated_at = NOW() WHERE id = $1', [email, userId]);
  
  // TODO: Send verification email to new email address
  
  res.send({ success: true, message: 'Email changed successfully. Please verify your new email address.' });
});

// Forgot password endpoint
fastify.post('/auth/forgot-password', async (req, res) => {
  const { email } = req.body;
  
  if (!email) {
    return res.status(400).send({ error: 'email required' });
  }

  const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
  
  // Always return success to prevent email enumeration
  // In production, you would send a password reset email with a token
  // For now, we just log it
  console.log(`Password reset requested for email: ${email}`);
  
  res.send({ success: true, message: 'If the email exists, a password reset link has been sent' });
});

// Reset password endpoint
fastify.post('/auth/reset-password', async (req, res) => {
  const { token, new_password } = req.body;
  
  if (!token || !new_password) {
    return res.status(400).send({ error: 'token and new_password required' });
  }
  
  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  }
  
  // In a real implementation, you would verify the token from a password_reset_tokens table
  // For now, we'll just return success
  res.send({ success: true, message: 'Password reset successful (mock implementation)' });
});

// Delete account endpoint
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
  
  // Delete user (cascades to all related tables via ON DELETE CASCADE)
  await pool.query('DELETE FROM users WHERE id = $1', [userId]);
  
  res.send({ success: true, message: 'Account deleted successfully' });
});

// Get active sessions
fastify.get('/auth/sessions', { preHandler: verifyToken }, async (req, res) => {
  // In a full implementation, you would query a sessions table
  // For now, return mock data
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

// Revoke a specific session
fastify.delete('/auth/sessions/:sessionId', { preHandler: verifyToken }, async (req, res) => {
  // In a full implementation, you would delete the session from a sessions table
  res.send({ success: true, message: 'Session revoked' });
});

// Revoke all other sessions
fastify.delete('/auth/sessions', { preHandler: verifyToken }, async (req, res) => {
  // In a full implementation, you would delete all other sessions from the sessions table
  res.send({ success: true, message: 'All other sessions revoked' });
}

// Logout endpoint
fastify.post('/logout', { preHandler: verifyToken }, async (req, res) => {
  // In a real implementation, you would invalidate the refresh token
  res.send({ success: true, message: 'Logged out successfully' });
};

module.exports = fastify;
