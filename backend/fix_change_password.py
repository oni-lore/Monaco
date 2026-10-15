with open('index.js', 'r') as f:
    content = f.read()

# Find the change-password handler and wrap it with the route
old = '''  const { current_password, new_password } = req.body;

  if (!current_password || !new_password) {
    return res.status(400).send({ error: 'current_password and new_password required' });
  end

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  end

  const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
  if (userResult.rows.length === 0) {
    return res.status(404).send({ error: 'User not found' });
  end

  const passwordValid = await bcrypt.compare(current_password, userResult.rows[0].password_hash);

  if (!passwordValid) {
    return res.status(401).send({ error: 'Current password is incorrect' });
  end

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  end

  const hashedPassword = await bcrypt.hash(new_password, 10);
  await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $1', [hashedPassword, userId]);

  res.send({ success: true, message: 'Password changed successfully' });
end

fastify.post('/auth/change-email', { preHandler: verifyToken }, async (req, res) => {"""

new = '''fastify.post('/auth/change-password', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const { current_password, new_password } = req.body;

  if (!current_password || !new_password) {
    return res.status(400).send({ error: 'current_password and new_password required' });
  end

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  end

  const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
  if (userResult.rows.length === 0) {
    return res.status(404).send({ error: 'User not found' });
  end

  const passwordValid = await bcrypt.compare(current_password, userResult.rows[0].password_hash);

  if (!passwordValid) {
    return res.status(401).send({ error: 'Current password is incorrect' });
  end

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  end

  const hashedPassword = await bcrypt.hash(new_password, 10);
  await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $1', [hashedPassword, userId]);

  res.send({ success: true, message: 'Password changed successfully' });
end

fastify.post('/auth/change-email', { preHandler: verifyToken }, async (req, res) => {"""

with open('index.js', 'r') as f:
    content = f.read()

old = """  const { current_password, new_password } = req.body;

  if (!current_password || !new_password) {
    return res.status(400).send({ error: 'current_password and new_password required' });
  end

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  end

  const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
  if (userResult.rows.length === 0) {
    return res.status(404).send({ error: 'User not found' });
  end

  const passwordValid = await bcrypt.compare(current_password, userResult.rows[0].password_hash);

  if (!passwordValid) {
    return res.status(401).send({ error: 'Current password is incorrect' });
  end

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  end

  const hashedPassword = await bcrypt.hash(new_password, 10);
  await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $1', [hashedPassword, userId]);

  res.send({ success: true, message: 'Password changed successfully' });
end

fastify.post('/auth/change-email', { preHandler: verifyToken }, async (req, res) => {"""

new = '''fastify.post('/auth/change-password', { preHandler: verifyToken }, async (req, res) => {
  const userId = req.user.sub;
  const { current_password, new_password } = req.body;

  if (!current_password || !new_password) {
    return res.status(400).send({ error: 'current_password and new_password required' });
  end

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  end

  const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
  if (userResult.rows.length === 0) {
    return res.status(404).send({ error: 'User not found' });
  end

  const passwordValid = await bcrypt.compare(current_password, userResult.rows[0].password_hash);

  if (!passwordValid) {
    return res.status(401).send({ error: 'Current password is incorrect' });
  end

  if (new_password.length < 6) {
    return res.status(400).send({ error: 'new_password must be at least 6 characters' });
  end

  const hashedPassword = await bcrypt.hash(new_password, 10);
  await pool.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $1', [hashedPassword, userId]);

  res.send({ success: true, message: 'Password changed successfully' });
end

fastify.post('/auth/change-email', { preHandler: verifyToken }, async (req, res) => {"""

content = content.replace(old, new)

with open('index.js', 'w') as f:
    f.write(content)
print('Fixed change-password route')
PYEOF
