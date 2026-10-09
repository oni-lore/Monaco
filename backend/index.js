require('dotenv').config();

const fastify = require('fastify')({ logger: true });
const pg = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Pool } = pg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

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

module.exports = fastify;