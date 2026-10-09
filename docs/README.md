# Monaco — Project Setup

## Repository Structure

```
/Monaco/              ← Root workspace
  /client/            ← Flutter Android application
  /backend/           ← Node.js + Fastify API
  /docs/              ← Generated documentation
  /infra/             ← Docker, scripts, configs
  / migrations/       ← PostgreSQL database migrations
```

## Phase 0: Project Foundation (Completed)

### Setup Checklist

- [x] Repository structure created
- [x] Flutter project initialized (Android-first)
- [x] Node.js/Fastify backend scaffolded
- [x] Docker Compose for local development (backend + Postgres)
- [x] Initial database migration (001_initial_schema) created
- [x] `.env.example` documented with all required environment variables
- [x] Lint/formatting configured (Dart analysis, ESLint, Prettier)
- [x] GitHub Actions CI workflow ready
- [x] Documentation stubs created (README, setup.md, architecture.md)

### Quick Start

```bash
# 1. Start infrastructure (backend + Postgres)
docker compose -f infra/docker-compose.yml up -d

# 2. Install Flutter dependencies
cd client && flutter pub get

# 3. Install Node.js dependencies
cd backend && npm install

# 4. Set up environment variables
cp backend/.env.example backend/.env
# Edit .env with your values (DATABASE_URL, JWT_SECRET, etc.)

# 5. Run database migration
cd backend && npx pg-migrate apply -- migrations/

# 6. Start the backend server
cd backend && node index.js
```

### Environment Variables

See `backend/.env.example` for all required variables. Key variables:

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `JWT_SECRET` | Yes | Secret for JWT token signing |
| `ENABLE_PHONE_VERIFICATION` | No | Set to `true` to enable SMS verification (may incur costs) |

### Flutter Development

- Android APK: `cd client && flutter build apk`
- iOS simulator: `cd client && flutter run`
- Hot reload is supported during development

### Backend Development

- Server runs on `http://localhost:3000`
- Health check: `GET /` returns `{ status: 'ok' }`
- Registration: `POST /register` with `{ username, password, email }`
- Login: `POST /login` with `{ username, password }`

### Database Migrations

New migrations are added to `backend/migrations/` following the naming convention `NNN_description.up.sql`. Use `pg-migrate` to manage applied migrations.

### Security Notes

- Never commit `.env` files with real secrets
- `JWT_SECRET` must be a strong random string in production
- Passwords are bcrypt-hashed never stored in plaintext
- Row Level Security policies must be configured after Supabase project creation
- Credentials and secrets are managed via `.env` files, never committed