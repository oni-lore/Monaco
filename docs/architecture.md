# Monaco — Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Client (Flutter)                       │
│  • Android APK (first-class target)                         │
│  • Dart + Flutter framework                                  │
│  • Local caching: Drift/SQLite                               │
│  • Offline message queue with idempotency keys              │
│  • FCM push notification registration                       │
│  • Secure token storage: Flutter Secure Storage              │
└───────────────────────┬───────────────────────────────────┘
                      │ HTTPS + TLS
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend (Node.js + Fastify)              │
│  • JWT authentication                                        │
│  • bcrypt password hashing                                   │
│  • Custom WebSocket real-time server                        │
│  • PostgreSQL via Supabase (or Neon)                        │
│  • Cloudflare R2 pre-signed URLs for media                 │
│  • Session management (refresh tokens)                      │
│  • Rate limiting + abuse prevention                         │
└───────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Database (PostgreSQL)                    │
│  • Users, sessions, Monarch IDs                             │
│  • Connections, conversations, messages                     │
│  • Councils, council members, council settings              │
│  • Polls, poll options, poll votes                          │
│  • Enshrines, reactions, read receipts                      │
│  • Audit log                                                │
└───────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    External Services                        │
│  • Cloudflare R2: Media file storage (10 GB free, 0 egress)│
│  • Firebase Cloud Messaging: Push notifications (free)      │
│  • Supabase/Neon: PostgreSQL + optional Realtime             │
└─────────────────────────────────────────────────────────────┘
```

## Client-Server Data Flow

### 1. Authentication Flow

```
Client ──► POST /register {username, password, email}
         ──► POST /login {username, password}
         ◄── JWT access token + refresh token

Client stores JWT securely. Token sent as Bearer auth header
on all subsequent API requests.
```

### 2. Connection Flow

```
Client ──► Search by Monarch ID (restricted profile)
         ──► Send connection request (with intro message)
         ──► Recipient accepts/declines via WebSocket/UI
         ◄── Acceptance creates connection record
         ◄── Post-connection: full profile + messaging unlocked
```

### 3. Private Conversation Flow

```
Client ──► WebSocket auth handshake (JWT validation)
         ──► Join direct conversation
         ──► Send message (optimistic UI, server ack)
         ──► Receive real-time messages
         ──► Read receipts, typing indicators
         ──► Edit (5-min window, backend enforced)
         ──► Delete (per policy D2)
         ──► Forward (Forwarded indicator)
         └──► Ensure participant-based access control
```

### 4. Council Flow

```
Client ──► Create Council (creator becomes Admin)
         ──► Invite members (admin-only or all-members setting)
         ──► Manage council members (promote/demote/remove)
         ──► Create polls (any member)
         ──► Ensure participant-based access to messages
         └──► Prevent last Admin from leaving without promoting another
```

## Security Architecture

### Authorization Model

- **Never trust client-supplied role/admin/ownership fields** (security.md §920-923)
- **Participant-based access**: A user can only access conversation/council data
  if they are a participant (explicitly joined, not removed)
- **Server-side enforcement**: All sensitive operations validated server-side
  before data is returned to the client

### Key Protections

1. **Message access**: A user can only read messages from conversations
   they participate in. Conversation participants are enforced via
   foreign keys + application-level checks.

2. **Conversation creation**: Direct conversations are created between
   two users who have an accepted connection. No conversation can be
   joined without prior connection acceptance.

3. **Council membership**: Users must be council members (via
   council_members table) to send messages or read council history.

4. **Monarch ID search**: Pre-connection profile data is restricted.
   Backend must withhold protected data; do not send sensitive profile
   data to the client and merely hide it visually.

5. **JWT validation**: All WebSocket connections and API requests
   must validate the JWT before authorizing any data access.

### Secrets Management

- All secrets via `.env` files, never committed to source control
- `DATABASE_URL`, `JWT_SECRET`, `R2_CREDENTIALS`, `FIREBASE_CREDENTIALS`
- `.env.example` committed with variable names only (no values)
- CI/CD injects secrets at runtime, not built into the APK

## Deployment Architecture

### Environments

| Environment | Backend | Database | Storage |
|---|---|---|---|
| Local dev | Node local + Docker Postgres | Local or Supabase dev | R2 dev bucket |
| Staging | Render free tier | Supabase staging | R2 staging bucket |
| Production | Render free tier | Supabase production | R2 production bucket |

### Render Configuration

- Free tier: spins down after 15 min inactivity (acceptable for private group)
- Health check endpoint: `GET /` keeps service warm
- Separate DATABASE_URL per environment
- No hard-coded dev URLs in production

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