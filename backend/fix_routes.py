with open('index.js', 'r') as f:
    content = f.read()

# Fix 1: Remove the first (duplicate) logout endpoint
old_logout1 = """fastify.post('/logout', { preHandler: verifyToken }, async (req, res) => {
  res.send({ success: true, message: 'Logged out successfully' });
});

fastify.post('/auth/change-password', { preHandler: verifyToken }, async (req, res) => {"""

new_logout1 = """fastify.post('/auth/change-password', { preHandler: verifyToken }, async (req, res) => {"""

content = content.replace(
    '''fastify.post('/logout', { preHandler: verifyToken }, async (req, res) => {
  res.send({ success: true, message: 'Logged out successfully' });
});

fastify.post('/auth/change-password', { preHandler: verifyToken }, async (req, res) => {""",
    '''fastify.post('/auth/change-password', { preHandler: verifyToken }, async (req, res) => {''',
    1)

# Fix 2: Remove duplicate logout at the end
old_logout2 = '''fastify.post('/logout', { preHandler: verifyToken }, async (req, res) => {
  res.send({ success: true, message: 'Logged out successfully' });
});

module.exports = fastify;"""

new_logout2 = '''module.exports = fastify;"""

content = content.replace(
    '''fastify.post('/logout', { preHandler: verifyToken }, async (req, res) => {
  res.send({ success: true, message: 'Logged out successfully' });
});

module.exports = fastify;''',
    '''module.exports = fastify;''',
    1)

with open('index.js', 'w') as f:
    f.write(content)
print('Fixed')
PYEOF
