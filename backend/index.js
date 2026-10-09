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
async function verifyToken(req, res, next) {
  try {
    const authorization = req.headers.authorization;
    if (!authorization || !authorization.startsWith('Bearer ')) {
      return res.status(401).send({ error: 'Missing or invalid authorization header' });
    }
    const token = authorization.substring(7);
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = payload;
    next();
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
    'INSERT INTO direct_conversations (id, creator_id, name, created_at) VALUES (UUID_GENERATE_V4(), $1, NULL, NOW()) RETURNING id',
    [creatorId]
  );
  const conversationId = result.rows[0].id;

  // Add creator as participant
  await pool.query(
    'INSERT INTO conversation_participants (id, conversation_id, user_id, role, joined_at) VALUES (UUID_GENERATE_V4(), $1, $2, \'member\', NOW())',
    [conversationId, creatorId]
  );

  // Add target as participant (they already have accepted connection, trigger will verify)
  await pool.query(
    'INSERT INTO conversation_participants (id, conversation_id, user_id, role, joined_at) VALUES (UUID_GENERATE_V4(), $1, $2, \'member\', NOW())',
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
     VALUES (UUID_GENERATE_V4(), $1, $2, $3, $4, NOW()) RETURNING id, created_at`,
    [conversationId, userId, content_type, content_text || null]
  );

  res.send({ success: true, messageId: result.rows[0].id, created_at: result.rows[0].created_at });
});

// Login required middleware already defined above
// Export the fastify instance
module.exports = fastify;