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
npx pg-migrate apply -- migrations/
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
npx pg-migrate make add_users_table

# Apply pending migrations
npx pg-migrate apply -- migrations/

# Rollback last migration
npx pg-migrate redo -- migrations/
```

## Directory Reference

```
├── client/           ← Flutter Android app
├── backend/          ← Node.js + Fastify API
├── docs/             ← This guide + generated docs
├── infra/            ← Docker Compose + scripts
├── migrations/       ← SQL database migrations
└── docs/             ← Project documentation
```

## Known Limitations (V1)

- Phone/SMS verification skipped (email-only), per D1 default
- No iOS build configured (Android-first)
- Media upload via pre-signed URLs not yet configured
- Real-time WebSocket events not yet implemented
- No Councils, polls, Enshrines in V1 MVP