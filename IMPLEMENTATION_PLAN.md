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

- **Accounts:** Register (username, password, email+verify, birthday, optional avatar), login, logout, change password/email, active sessions, logout other devices, delete account. Phone number is collected during registration and stored with the account but **not** verified via SMS/OTP in V1. Email verification is the actual account verification mechanism. Phone number is retained because it may be useful for future calling/communication functionality.
- **Monarch Identifiers:** Founder has permanent Monarch identifier: MOANARK1. Normal users initially receive their Monarch number based on account join order. Monarch identifiers are automatically assigned by the system. Normal users' Monarch identifiers can automatically rotate. Founder remains MOANARK1 and does not rotate. Founder/platform owner has administrative control over the Monarch system. The system must prevent duplicate active Monarch identifiers. Exact rotation frequency/algorithm remains an implementation detail to be finalized later unless another requirement depends on it.
- **Connections:** Find by Monarch ID / username / 1-minute one-use link. Connection request + optional intro message. Accept/decline. Remove connection.
- **Private chats:** Real-time messages, replies (swipe), reactions, media, files, stickers, voice messages, edit (5-min window + Edited indicator), delete (Delete for me: disappears from that user's view only; Delete for everyone: disappears for all participants). Backend authorization enforces who can perform each action., read/typing status (both opt-outable), forward (Forwarded indicator), archive/delete/clear, Enshrines, search.
- **Councils:** Group chats. Name/icon/description, members, multiple admins, invitations (admin-only or all-members setting), polls, Enshrines, Archives, member management.
- **Polls:** Any member creates. Single/multi-choice. Anonymous or visible. Permanent (no auto-close). Vote changeable. Poll creator can delete their own poll. Founder can delete any poll. Deleted polls must no longer be votable. Show a small Monaco-style historical/poetic indication that the poll has ended/been removed. Example wording direction: Its question has been laid to rest. The exact final wording can be decided during UI/content design.
- **Enshrines:** Historical records. Custom title. Creator-only removal. Persists even if source message deleted.
- **Reactions:** 6 defaults (heart, laugh, cry, skull, suspicious, thumbs-up) + picker. Real-time. Private + Council.
- **Sticker Library:** Monaco has a shared sticker library. Basic/default stickers are included. Founder can upload/add stickers. Founder can authorize specific members to manage/add stickers. Authorized members can upload/add stickers. Normal members cannot add stickers unless explicitly authorized. Custom GIF stickers and other appropriate sticker formats are supported. Founder can revoke sticker-management authorization. Keep sticker permissions simple; do not create a complex role hierarchy.
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

### Backend — Supabase Edge Functions
Planned backend runtime: Supabase Edge Functions.
Do not add Vercel, Cloudflare Workers, or another backend hosting layer unless a genuine technical requirement later justifies it.
Supabase should remain the central backend platform for V1 where practical.
Backend must enforce authorization and security; the client must never be trusted for permissions.
WebSocket/realtime via Supabase Supabase Realtime or custom Edge Functions.

### Database — PostgreSQL (Supabase Free)
PostgreSQL is the database via Supabase Free tier. Design around the published Free-tier limits.
Monaco should support deliberate export/archive/cleanup of old data when storage limits become relevant.
Important data must not be deleted as the only copy; export/backup should exist before destructive cleanup.
Do not assume the free tier is unlimited.
Migrations via `node-pg-migrate`.
Full-text search via Postgres tsvector/tsquery — no external search engine needed.

### Authentication — Custom JWT
Issued by Monaco backend. Stored on device via Flutter Secure Storage.
Refresh token rotation. Sessions table in DB.
bcrypt password hashing. Changing password invalidates other sessions.
Re-authentication required for sensitive actions (account deletion, etc.).

### Email Verification — Resend
Free tier: 3,000 emails/month. Sufficient for a private group.

### Phone Number Collection (no SMS/OTP verification in V1)
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
### Username Uniqueness
- Founder username: ONI_Emrys
- Usernames are globally unique.
- Username uniqueness is CASE-INSENSITIVE.
- ONI_Emrys, oni_emrys, Oni_Emrys, etc. must be treated as the same username for uniqueness purposes.
- A username cannot be claimed by another account while it is taken.
- Users are allowed to change their username later.
- Username uniqueness must be enforced at the backend/database level, not only in the client UI.
- Do not make usernames permanently immutable.


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

---

## 9. Founder Account Seed Information
Record the intended Founder account information in the plan as setup information/placeholders:
- Username: ONI_Emrys
- Email: onieleven2@gmail.com
- Phone: 9427555466
- Birthday: 29-05-2007
- Profile picture: added later
- Password: must be created privately during setup; NEVER hard-code it, commit it, or request it in the repository.

---

## 10. Security Requirement
Do not place the Founder password, OTPs, tokens, API keys, service credentials, or other secrets in source code, Git history, documentation intended for public repositories, or .env files committed to Git.

---

---

## 11. Optional Monaco App Lock

### 1. App Lock is optional
- App Lock is OFF by default unless the user enables it.
- Users can enable or disable App Lock from Monaco's security settings.
- Users can configure when the lock activates.
- Sensible lock conditions may include:
  - immediately when leaving Monaco
  - after a configurable period of inactivity
  - when Monaco is reopened after being backgrounded
- Exact timeout values and final UI wording can be decided during implementation/UI design.
- Do not force App Lock on every user.

### 2. Multiple unlock methods are supported
- The user must be able to choose which supported unlock methods they want.
- The user may enable: only ONE unlock method OR MULTIPLE unlock methods simultaneously.
- These methods are alternatives.
- If multiple methods are enabled, successful authentication using ANY enabled method should unlock Monaco.
- For example: PIN + fingerprint + face means the user can unlock Monaco with:
  - their PIN
  - their fingerprint
  - their face authentication.
- The user should not be required to complete every enabled method.

### 3. Supported unlock methods
The App Lock system should support the following categories where technically available:

#### A. Monaco PIN
- User-created numeric PIN.
- Monaco manages this credential.
- The actual PIN must never be stored in plaintext.
- Store only a secure representation suitable for authentication.

#### B. Monaco alphanumeric passcode/password
- User-created passcode.
- May contain: letters, numbers, or both.
- Monaco manages this credential.
- The actual secret must never be stored in plaintext.

#### C. Fingerprint
- Use the device operating system's secure biometric authentication facilities where available.
- Monaco must NOT collect, store, or process raw fingerprint data.
- Monaco only receives the authentication result from the platform.

#### D. Face recognition
- Use the device operating system's secure biometric authentication facilities where available.
- Monaco must NOT collect, store, or process raw facial biometric data.
- Monaco only receives the authentication result from the platform.

#### E. Device credentials
Where the operating system supports it, Monaco may use the device's own secure authentication mechanism, such as:
- device PIN
- device pattern
- device password
- These are OS/device credentials and are NOT Monaco credentials.

#### F. Pattern
- Support a pattern-based unlock method where the target platform allows Monaco to implement it securely.
- If the platform already provides pattern authentication as part of its device credential system, use the platform mechanism rather than unnecessarily implementing a duplicate system.
- Do not expose or store the user's device pattern.

#### G. Passkey / platform authentication
- Support passkey/platform authentication where supported by the target platform and architecture.
- Do not assume passkeys are available on every device or platform.
- The implementation should detect availability and only present supported methods.

### 4. Platform capability detection
The App Lock settings must not show authentication methods that the current device/platform cannot actually use.
- A device without biometric hardware should not show an unusable fingerprint option.
- A device without face authentication should not show an unusable face option.
- Platform-specific authentication capabilities should be detected at runtime.
- The exact platform APIs and implementation approach should be selected during implementation based on the actual target platform.
- For Android, prefer the operating system's secure biometric/device-credential facilities rather than implementing custom biometric recognition.

### 5. Security boundary
App Lock must be a real security boundary, not merely a visual screen.
Before successful authentication:
- Do not display private messages.
- Do not display private media.
- Do not display private profiles.
- Do not display private Council content.
- Do not display private notifications.
- Do not expose protected cached data through the UI.
- Do not treat an unlocked-looking UI as authenticated.
- Authentication and authorization must be enforced correctly.

### 6. Credential security
For Monaco-managed credentials such as PINs and alphanumeric passcodes:
- Never store plaintext credentials.
- Never put them in source code.
- Never put them in Git.
- Never log them.
- Never send them to the Founder.
- Never expose them through ordinary backend responses.
- Use an appropriate secure credential-verification design.
- The exact hashing/key-management approach can be selected during implementation.

For biometric, device-credential, and passkey authentication:
- Monaco must rely on secure platform authentication mechanisms.
- Monaco must not receive or store raw biometric information.
- Monaco must not attempt to reconstruct fingerprints, faces, or device credentials.

### 7. App Lock recovery — Founder-controlled recovery
A user must have a recovery option if they lose access to all enabled Monaco unlock methods.
The App Lock screen must provide a recovery option such as:
"Can't unlock Monaco?"
→ "Request Founder Recovery"

When selected:
- The user submits a recovery request.
- The request is sent to the Monaco Founder/platform owner.
- The request should identify the relevant account/device/session sufficiently for the Founder to make an informed decision.
- Do NOT send the user's actual PIN, password, biometric data, device credential, or other secret to the Founder.
- The request should contain only the information necessary for recovery and security review.

### 8. Founder recovery controls
The Founder must have an administrative recovery capability for App Lock.
The Founder should be able to:
- view pending App Lock recovery requests
- review the account/device/request information
- approve a recovery request
- reject a recovery request

If the Founder approves the recovery request:
1. The App Lock protection for the affected device must be disabled or reset through an authenticated recovery process.
2. Monaco-managed App Lock credentials for that device must be invalidated/reset.
3. Any previously configured Monaco PIN/passcode/pattern credentials associated with that App Lock configuration must no longer unlock Monaco.
4. The user must be allowed to enter Monaco after recovery.
5. The user can then configure App Lock again and create new credentials.
6. Existing account authentication must remain intact.
7. This recovery operation must not reveal the user's previous credentials to the Founder.

The recovery action must be authenticated and authorized by the backend.

### 9. Device-specific recovery
App Lock recovery should be associated with the affected account and device/session where practical.
The Founder should not accidentally disable App Lock on every device belonging to the user when the request concerns only one device.
The implementation should distinguish between:
- account identity
- Monaco App Lock configuration
- individual device/session authorization

Exact device-identification mechanics can be finalized during implementation.

### 10. Recovery audit/security
Founder recovery actions are sensitive administrative operations.
The system should maintain an appropriate security/audit record containing information such as:
- who requested recovery
- which account was affected
- which device/session was affected
- when the request was made
- whether it was approved or rejected
- which Founder/admin performed the action
- when the action occurred

Do not store the user's actual secrets in the audit record.

### 11. Lock state behavior
When Monaco is locked:
- Private application content must remain inaccessible.
- Failed authentication must keep Monaco locked.
- Successful authentication using any enabled method unlocks Monaco.
- Lock state must be handled correctly when the application moves between foreground/background states.
- The implementation must avoid accidentally exposing cached content during app startup or transitions.
- The exact session/timeout behavior can be finalized during implementation.

### 12. Relationship to account password
App Lock does NOT replace the Monaco account authentication system.
A user can have:
- Monaco account password
AND
- Monaco App Lock

These are separate security layers.
Changing the normal Monaco account password must not automatically reveal or reset the App Lock credentials unless the final security architecture explicitly requires such behavior.
Similarly, resetting App Lock must not automatically change the user's Monaco account password.

### 13. Recovery after all methods are lost
The intended recovery path is:
User cannot unlock Monaco
→ selects "Can't unlock Monaco?"
→ sends Founder Recovery Request
→ Founder reviews request
→ Founder approves
→ affected App Lock configuration/credentials are reset
→ user enters Monaco
→ user configures new App Lock methods if desired

The Founder does NOT learn the old credentials.

### 14. Do not overengineer the authentication choices
The goal is to support multiple secure authentication options without creating a custom biometric/security framework.
Use platform-provided authentication mechanisms wherever possible.
Do not build Monaco's own fingerprint scanner, face-recognition system, or biometric database.

Voice recognition is NOT a required V1 unlock method.
Voice recognition may be investigated as a future experimental feature, but it must not be required for V1 and must not be treated as a trusted primary security mechanism unless a genuinely secure implementation is established.

### 15. Plan review
- Search the entire IMPLEMENTATION_PLAN.md for contradictory authentication/security assumptions.
- Make sure App Lock is clearly separate from account authentication.
- Make sure multiple unlock methods are explicitly supported.
- Make sure the user can choose one or multiple methods.
- Make sure Founder recovery is explicitly documented.
- Make sure recovery resets/invalidate Monaco-managed App Lock credentials.
- Make sure Founder recovery does not expose the user's old credentials.
- Make sure biometric/device credentials are handled by the platform rather than stored by Monaco.
- Mark genuinely unresolved implementation details as unresolved instead of inventing answers.

---

## 8. Immediate Next Steps After This Plan
1. Owner answers D1–D7 above (SMS provider, deletion model, DB host, hosting, Monarch creator, sticker scope, poll deletion).
2. Set up external service accounts: Resend (email verification, free tier sufficient), Cloudflare R2 bucket (media storage, 10 GB free, 0 egress), Firebase project (FCM for push; optionally Phone Auth if D1 chooses it), GitHub account (for CI Actions).
3. Begin Phase 0: Repository structure + Flutter app scaffold + Node.js/Fastify backend + Docker Compose + first DB migration.
4. Create .env.example documenting all required env vars before any code is written.
*No application code has been written. Implementation begins only after owner decisions D1–D7 are confirmed.*
