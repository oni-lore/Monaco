# Monaco — Setup Guide

## Prerequisites

- Node.js (v22+) and npm
- Flutter SDK (for Android development)
- Docker and Docker Compose (for local development)
- PostgreSQL database (Supabase or Neon, or local via Docker)
- Firebase project (for push notifications)
- Cloudflare R2 account (for media storage)

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/oni-lore/Monaco.git
cd Monaco
```

### 2. Initialize the backend

```bash
cd backend
cp .env.example .env
# Edit .env with your values
npm install
```

### 3. Initialize the Flutter client

```bash
cd client
flutter pub get
```

### 4. Start infrastructure with Docker

```bash
cd infra
docker compose up -d
```

This starts:
- **db**: PostgreSQL 16 instance
- **backend**: Node.js/Fastify server on port 3000

### 5. Run database migrations

```bash
# From the backend directory
npm run migrate   # needs DATABASE_URL; uses psql (see backend/scripts/migrate.sh)
```

### 6. Verify the backend is running

```bash
curl http://localhost:3000/
# Expected: {"status":"ok","service":"monaco-backend"}
```

### 7. Run the Flutter app

```bash
cd client
flutter run
# Or build debug APK:
flutter build apk --debug
```

## Development Workflow

### Backend

```bash
# Run with hot-reload (nodemon not included, use node directly)
node index.js

# Or with Docker
docker compose up backend
```

### Flutter

```bash
# Run the app
flutter run

# Analyze for lint issues
flutter analyze

# Run any available tests
flutter test
```

### Database Migrations

```bash
# Create a new migration
npx pg-make make add_users_table   # or manually create a new .up.sql file

# Apply pending migrations
npm run migrate   # needs DATABASE_URL; uses psql (see backend/scripts/migrate.sh)

# Rollback last migration
npm run migrate -- --skip-existing   # or use the migrate.sh script directly
```

### .gitignore

The root `.gitignore` excludes `node_modules/`, `.env*`, build artifacts, and IDE files so that real credentials and runtime dependencies are never committed.

### CI / GitHub Actions

The `.github/workflows/ci.yml` workflow runs on every push/PR to `kilo/fancy-bit-ku9` or `main`. It:

1. Installs Node.js, Flutter, and dependencies
2. Starts a PostgreSQL 16-alpine service
3. Waits for PostgreSQL to be ready
4. Runs `npm run migrate` (applies SQL migrations via `psql` with `ON_ERROR_STOP`)
5. Runs `npm run verify-schema` (checks required tables + trigger exist)
6. Runs `npm test` (executes the 6 authorization integration tests)
7. Builds an Android debug APK and uploads it as an artifact

All services, secrets, and database connections are free-tier compatible. No paid APIs or SMS fallbacks are used.

## Known Limitations (V1)

- Phone/SMS verification skipped (email-only), per D1 default
- No iOS build configured (Android-first)
- Media upload via pre-signed URLs not yet configured
- Real-time WebSocket events not yet implemented
- No Councils, polls, Enshrines in V1 MVP

## Feature Flags

| Flag | Default | Description |
|---|---|---|
| `ENABLE_PHONE_VERIFICATION` | `false` | Set to `true` to enable SMS (potentially paid) |
| `ENABLE_CLOUDINER` | `false` | Image CDN alternative to R2 |

## Compliance & Privacy

- Read receipts opt-out enforced server-side
- Typing indicator opt-out enforced server-side
- Birthday visibility controlled per user
- No public follower system, activity feed, or social profile
- All protected resources authorized server-side