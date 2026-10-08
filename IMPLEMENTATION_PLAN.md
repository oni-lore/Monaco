# Monaco — Implementation Plan
**Branch:** cline/j9pt9b19
**Status:** Planning only — no code written yet.
**Sources:** Monaco_Master_Product_Specification.md, Monaco_AI_Build_Prompt_Pack.md

---

## 1. Product Summary

Monaco is a **private Android messaging platform** for a specific friend group.
Full identity: *Moanark Council*.
Core idea: "WhatsApp is where you talk to people. Monaco is where your group lives."

### V1 Confirmed Features

- **Accounts:** Register (username, password, email+verify, phone+verify, birthday, optional avatar), login, logout, change password/email/phone, active sessions, logout other devices, delete account.
- **Monarch ID:** Rotating discovery identifier (~weekly). Platform creator's ID is permanent.
- **Connections:** Find by Monarch ID / username / 1-minute one-use link. Connection request + optional intro message. Accept/decline. Remove connection.
- **Private chats:** Real-time messages, replies (swipe), reactions, media, files, stickers, voice messages, edit (5-min window + Edited indicator), delete, read/typing status (both opt-outable), forward (Forwarded indicator), archive/delete/clear, Enshrines, search.
- **Councils:** Group chats. Name/icon/description, members, multiple admins, invitations (admin-only or all-members setting), polls, Enshrines, Archives, member management.
- **Polls:** Any member creates. Single/multi-choice. Anonymous or visible. Permanent (no auto-close). Vote changeable.
- **Enshrines:** Historical records. Custom title. Creator-only removal. Persists even if source message deleted.
- **Reactions:** 6 defaults (heart, laugh, cry, skull, suspicious, thumbs-up) + picker. Real-time. Private + Council.
- **Stickers:** Built-in packs + custom uploads. Frequent-first. No marketplace.
- **Voice messages:** Record, cancel, send, playback with speed control. Max 1 hour. Backend enforces limit.
- **Media/Files:** Images (JPG/PNG/WebP/GIF), Videos (MP4/WebM/MOV), Files (PDF/Office/TXT/ZIP). ~15 MB limit. MIME validated.
- **Achievements:** Funny/pointless milestones. No competitive leaderboard.
- **Easter eggs:** Rare unobtrusive system messages on special events.
- **Notifications:** FCM push. Per-conversation/Council mute. DND hours. Preview setting.
- **Privacy:** Read receipts opt-out, typing opt-out, profile visibility. All enforced server-side.
- **Offline:** Queue messages offline, auto-retry, deduplication, server authoritative.
- **Search:** People, messages, Councils, Enshrines, media/files. Categorized results.
- **Birthday:** Backend flags sender's messages on their birthday; client applies visual treatment.

### Explicitly NOT in V1
Voice/video calls, screen sharing, stories, custom themes, complex roles, reaction marketplace, Council Lore as separate system, bots, AI, public communities, monetization, social feed, public discovery.

---

## 2. Proposed Architecture

### Client — Flutter (Android-first)
Single codebase produces Android APK now; iOS/web possible later.
Strong ecosystem for WebSocket, SQLite (Drift), audio, media pickers, FCM.
APK sideloading is the V1 distribution method — no Play Store required.

### Backend — Node.js + Fastify
Hosted free on **Render** (free tier, spins down after 15 min inactivity — acceptable for private group) or Railway.
Full control over auth, permissions, Monarch ID logic, Council business rules.
WebSocket server (`ws` library) for real-time events.

### Database — PostgreSQL
**Supabase** recommended (500 MB free, hosted Postgres, optional Realtime channel).
Alternative: **Neon** (10 GB free, serverless, useful branch-per-environment feature).
Migrations via `node-pg-migrate`.
Full-text search via Postgres tsvector/tsquery — no external search engine needed.

### Authentication — Custom JWT
Issued by Monaco backend. Stored on device via Flutter Secure Storage.
Refresh token rotation. Sessions table in DB.
bcrypt password hashing. Changing password invalidates other sessions.
Re-authentication required for sensitive actions (account deletion, etc.).

### Email Verification — Resend
Free tier: 3,000 emails/month. Sufficient for a private group.

### Phone/SMS Verification — OPEN DECISION (see D1)
- Firebase Phone Auth: free up to 10 verifications/day.
- MSG91 (India): ~₹0.20⃢0.50/SMS.
- Twilio: ~₹5⃢8/SMS.
- Skip phone in V1 (email-only): safest free option.

### Real-time — Custom WebSocket
Events: new message, edit, delete, reaction, typing, read receipt, poll update, member changes.
Idempotency keys prevent duplicates on reconnect.
Typing indicators cleared server-side on disconnect.

### Media/File Storage — Cloudflare R2
10 GB free, zero egress fees — best free option for media.
Backend generates pre-signed URLs; client never holds R2 credentials directly.

### Push Notifications — Firebase Cloud Messaging (FCM)
Free. Service account key lives on backend only; never in APK.

### Local Storage — Drift (SQLite for Flutter)
Message queue, conversation cache, contact cache, sticker metadata.
Offline queue with idempotency keys.

### Environments

| Environment | Backend | Database | Storage |
|---|---|---|---|
| Local dev | Node local + Docker Postgres | Local or Supabase dev project | R2 dev bucket |
| Staging | Render/Railway free | Supabase staging | R2 staging bucket |
| Production | Render/Railway free | Supabase production | R2 production bucket |

Secrets in .env files; never committed. .env.example committed with all required variable names.

---

## 3. Technology Stack Summary

| Concern | Choice | Cost |
|---|---|---|
| Client | Flutter | Free |
| Backend | Node.js + Fastify | Free |
| Backend hosting | Render (or Railway) free tier | Free* |
| Database | Supabase Postgres (or Neon) | Free tier |
| Auth | Custom JWT + bcrypt | Free |
| Email verification | Resend | Free (3k/month) |
| **SMS verification** | **Owner decision — see D1** | **Possibly paid** |
| Real-time | Custom WebSocket | Free |
| Media storage | Cloudflare R2 | Free (10 GB, 0 egress) |
| Push notifications | Firebase Cloud Messaging | Free |
| Local storage | Drift (SQLite) | Free |
| Search | Postgres full-text | Free |
| CI | GitHub Actions | Free |

*Render free tier sleeps after 15 min inactivity. Acceptable for a private closed group.

---

## 4. Phased Implementation Plan

### Phase 0 — Project Foundation (Week 1)
Repository structure, toolchain working, CI-ready, environments separated.

- Repo layout: /client (Flutter), /backend (Node.js), /docs, /infra
- Flutter project initialized; Android target confirmed
- Node.js/Fastify backend scaffolded
- Docker Compose: backend + Postgres for local dev
- DB migration tool wired up; initial empty migration
- .env.example documenting all required variables
- Lint + format configured
- GitHub Actions CI: build + lint + test on push
- README, setup.md, architecture.md stubs

**Deliverable:** Empty but buildable app + backend from a fresh clone.

### Phase 1 — Authentication & Accounts (Weeks 2–3)

- DB: users, sessions, verification_tokens
- Registration: username, password (bcrypt), email, phone, birthday
- Email verification (Resend); phone verification (per D1)
- Login → JWT access token + refresh token; rotation
- Logout; logout all other sessions
- Change password (invalidates other sessions)
- Forgot password (email recovery)
- Change email / change phone (re-verify)
- Active sessions list
- Delete account (re-auth + warning + confirmation + data removal)
- Rate limiting on auth endpoints
- Flutter: registration, verification, login, secure token storage, session persistence
- Tests: registration, login, session rules, password change, rate limits, account deletion

**Deliverable:** Working auth system.

### Phase 2 — Monarch ID & Connections (Weeks 3–4)

- DB: monarch_ids, connection_requests, connections, direct_links
- Assign Monarch IDs at registration; platform creator gets fixed permanent ID
- Weekly rotation job (non-creator users only)
- Search by Monarch ID → restricted profile (no real data before connection)
- One-use 1-minute connection link generation
- Connection request with optional intro message; accept/decline
- Post-connection: full profile + messaging unlocked
- Remove connection
- Flutter: search screen, people list, connection request flow
- Tests: rotation uniqueness, pre-connection data restriction, link expiry, one-use enforcement

**Deliverable:** Users can find and connect with each other.

### Phase 3 — Core Messaging (Weeks 4–6)

- DB: messages, read_receipts; typing is ephemeral (WebSocket only)
- WebSocket server + auth handshake
- Send/receive text messages in real time
- Message status: Sent → Delivered → Read
- Read receipts with opt-out (server enforces)
- Typing indicators with opt-out; cleared on disconnect
- Replies (swipe-to-reply; original message reference)
- Edit message: 5-minute window; Edited indicator
- Delete message: per owner decision D2
- Forward message: Forwarded indicator (not editable)
- Reactions: 6 defaults + picker; add/remove own; real-time counts; no duplicates per user per message
- Offline message queue; idempotency keys; auto-retry; deduplication
- Paginated message history
- Flutter: conversation screen, message bubbles, reply/edit/delete/forward UI, reaction picker, offline state
- Tests: all critical messaging business rules

**Deliverable:** Working real-time private messaging.

### Phase 4 — Media, Files, Voice, Stickers (Weeks 6–8)

- Cloudflare R2 setup; backend pre-signed URL generation
- Image upload/download + thumbnail
- Video upload/download + thumbnail
- File upload/download; ~15 MB limit enforced backend-side
- MIME type validation (not filename-only)
- Voice: record (Flutter mic), upload, playback, speed control; 1-hour limit enforced backend-side
- Sticker system: built-in packs, custom uploads, frequent-first, metadata in DB
- Flutter: media picker, image/video preview, file attachment, voice record UI, sticker picker
- Tests: file size limits, MIME validation, voice duration limit

**Deliverable:** Rich media messaging.

### Phase 5 — Councils (Weeks 8–10)

- DB: councils, council_members, council_settings
- Create Council → creator = Admin
- Council info: name, icon, description
- Invite members (Admin-only or all-members setting)
- Multiple Admins: promote, demote
- Prevent last Admin from leaving without promoting another
- Remove member; member leave
- Empty Council auto-deletion
- Council deletion = local hide only (not global)
- Councils share message engine with private chats
- Mentions (@username); historical mention handling after removal
- Polls: any member; single/multi-choice; anonymous/visible; permanent; vote-changeable; anonymous identity never exposed by backend
- Flutter: Council list, Council screen, member management, poll creation/voting UI
- Tests: admin rules, last-admin protection, empty-Council deletion, anonymous poll enforcement, mention behavior

**Deliverable:** Full Council group system with polls.

### Phase 6 — Enshrines & Achievements (Weeks 10–11)

- DB: enshrines, achievements, achievement_events
- Enshrine: any user; custom title; creator-only removal; persists if source message unavailable
- Jump-to-original if source message still exists
- Achievements: event triggers (message count, Enshrine count, sticker count, time-of-day, etc.)
- Achievement display on profile
- Easter egg event triggers (unanimous poll, 4 AM message, immediate delete, 10,000th message)
- Birthday flag: backend exposes is_sender_birthday on message responses
- Flutter: Enshrine UI, Archive view, achievement section, birthday visual treatment
- Tests: Enshrine ownership/persistence, achievement triggers, Easter egg conditions

**Deliverable:** Enshrines, achievements, Easter eggs, birthday treatment.

### Phase 7 — Notifications & Privacy (Weeks 11–12)

- FCM integration; service account key on backend only
- Push on: new message, reaction, connection request, Council invite
- Per-conversation/Council mute; DND hours; notification preview setting
- All privacy settings (read receipts, typing, profile visibility) enforced server-side
- Tests: mute enforcement, privacy enforcement

**Deliverable:** Notifications and privacy controls fully functional.

### Phase 8 — Search, Offline Polish, Performance (Weeks 12–13)

- Postgres full-text search for messages and Enshrines
- People/Council/media search with categorized results
- DB indexes on hot query paths; paginated queries everywhere
- Offline reconnect: restore last context, re-sync, no duplicates
- Flutter: search screen, lazy loading, offline state UX

**Deliverable:** Search functional; offline/reconnect solid.

### Phase 9 — Security Hardening & Test Suite (Weeks 13–14)

- Audit: every API endpoint has server-side authorization check
- Rate limiting on all sensitive endpoints
- Input validation on all user-controlled fields
- Pre-connection profile data strictly withheld
- Anonymous poll identity strictly withheld
- Secret audit: no credentials in source control
- security.md written
- Full test suite run; all failures fixed
- Debug/mock paths removed from production code

**Deliverable:** Security-reviewed, fully tested codebase.

### Phase 10 — Android Build, Deployment, Documentation (Weeks 14–15)

- Release signing strategy documented (keystore stored outside repo)
- Debug APK builds and installs on device
- Release APK builds cleanly
- Production backend deployed
- Production DB, R2 bucket, FCM config all set
- No hard-coded dev URLs in production
- All documentation files completed
- Final release audit against all spec requirements
- APK distributed to friend group

**Deliverable:** Monaco V1 usable by the group.


---

## 5. Owner Decisions Required Before Implementation (D1-D7)
| # | Decision | Impact | Default If No Answer |
|---|---|---|---|
| **D1** | **SMS/phone verification provider:** Firebase Phone Auth (free, 10/day quota), MSG91 (paid, ৱুাু/SMS for India), Twilio (ৱুাুু/SMS), or skip phone in V1 (email-only verification)? | Phase 1 auth blocked until decided. | Skip phone in V1; email-only verification (safest free path). |
| **D2** | **Message deletion model:** Delete for everyone (WhatsApp-style), delete only for sender (local hide), or both options to sender? | Phase 3 core design | Delete for everyone (matches expectations). |
| **D3** | **Database host:** Supabase (500 MB free Postgres + optional Realtime), Neon (10 GB free serverless + branching), or Railway Postgres (~500 MB free)? | Phase 0 setup | Supabase (best free tier + Realtime). |
| **D4** | **Backend hosting:** Render free tier (spins down after 15 min inactivity) or Railway free tier (always-on dyno option)? | Phase 0 setup | Render (more predictable for private group). |
| **D5** | **Monarch ID creator:** Single platform founder with fixed permanent ID, or each Council creator? | Phase 2 Monarch logic | Single platform founder; one fixed permanent ID total. |
| **D6** | **Custom sticker scope:** Per-user personal uploads only, or shareable packs visible to all group members? | Phase 4 sticker design | Personal uploads visible to the whole group. |
| **D7** | **Poll deletion:** Can the creator delete their own poll? | Phase 5 polls | Yes, creator can delete (mechanism isolated for later policy change). |

### If all D1-D7 default to the right column, implementation can proceed without further decisions.


---

## 6. Genuine Ambiguities Found in Spec (Clarified with Safe Defaults)
### A1 — Message Deletion vs. Enshrine
If D2 = delete-for-everyone: a deleted message could appear orphaned to Enshrine references.
Resolution: Enshrine spec already handles this — it persists and indicates unavailability. Consistent with all choices.
### A2 — Monarch ID “Creator”
Spec says “The creator’s number does not change.” Context: platform founder or Council creators?
Resolution: Treated as single platform founder with one fixed permanent ID (D5 default).
### A3 — Typing Indicator Variants
Spec mentions optional Monaco variants (“Alex is consulting the Council...”).
Resolution: V1 ships standard “Alex is typing...” off by default; funny variants are later UI toggle.
### A4 — Custom Sticker Pack Limits
Spec does not define per-user sticker count or size limits.
Resolution: Sensible defaults (e.g., 512 KB/sticker, 50 stickers/user) applied unless owner overrides.


---

## 7. Documentation Files to Create During Build
Per spec requirements (Section 30 of Build Prompt Pack):
- README.md (update existing)
- docs/architecture.md
- docs/setup.md
- docs/environment.example
- docs/database-schema.md
- docs/api.md
- docs/security.md
- docs/deployment.md
- docs/testing.md
- docs/troubleshooting.md
- docs/known-limitations.md
- CHANGELOG.md


---

## 8. Immediate Next Steps After This Plan
1. Owner answers D1–D7 above (SMS provider, deletion model, DB host, hosting, Monarch creator, sticker scope, poll deletion).
2. Set up external service accounts: Resend (email verification, free tier sufficient), Cloudflare R2 bucket (media storage, 10 GB free, 0 egress), Firebase project (FCM for push; optionally Phone Auth if D1 chooses it), GitHub account (for CI Actions).
3. Begin Phase 0: Repository structure + Flutter app scaffold + Node.js/Fastify backend + Docker Compose + first DB migration.
4. Create .env.example documenting all required env vars before any code is written.
*No application code has been written. Implementation begins only after owner decisions D1–D7 are confirmed.*
