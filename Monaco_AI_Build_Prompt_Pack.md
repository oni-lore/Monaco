# MONACO — AI BUILD PROMPT PACK

Moanark Council • Complete construction prompts for a coding agent


PURPOSE

This document is not a product description. It is a sequence of prompts intended to be given to an AI coding agent that can inspect and modify project files, run terminal commands, install dependencies, build the project, run tests, and fix errors.

The agent must treat this document as the construction specification for Monaco.

IMPORTANT OPERATING RULE:
Do not skip requirements, silently invent conflicting behavior, or replace a requirement with a simpler approximation. If something is genuinely unresolved and affects correctness, stop at that point, explain the exact conflict, and ask for a decision. Otherwise use the defaults stated in this document.

PRIMARY GOAL:
Build Monaco as a real Android application/platform for a private friend group, with a real backend, database, authentication, real-time communication, media/file handling, notifications, Councils, Enshrines, polls, stickers, achievements, privacy controls, and reliable offline/reconnection behavior.

COST GOAL:
Design the initial deployment to be free or as close to ₹0 as realistically possible. Prefer free/open-source/local tooling and free service tiers. Do not introduce a paid dependency when a reasonable free alternative exists. Clearly identify any unavoidable paid service, especially SMS/phone verification.

PRODUCT IDENTITY:
Monaco is the private digital headquarters of the friend group. The full joke name is Moanark Council. It is not a public social network and should not become one by accident.

BUILD PHILOSOPHY:
Reliability first. Communication is infrastructure. Council features sit above communication. Monaco personality sits above both. Keep V1 controlled; do not add calls, games, AI, public feeds, marketplaces, or other future features unless explicitly requested.



## 1. MASTER INSTRUCTION — GIVE THIS FIRST

```text
You are the lead coding agent for the Monaco project.

You have permission to inspect the entire repository, create and edit files, run terminal commands, install dependencies, run builds/tests, inspect errors, and iteratively repair the project.

Before changing code:
1. Inspect the repository.
2. Read all Monaco specification/prompt files provided to you.
3. Identify the current implementation state.
4. Create or update a clear project plan.
5. Do not overwrite useful existing work without inspecting it.
6. Keep secrets out of source control.
7. Keep the application buildable after each major phase.
8. Prefer small, verifiable increments over one enormous untestable implementation.

When implementing:
- Do not invent product features.
- Do not remove required features because they are inconvenient.
- Do not turn Monaco into a generic chat clone.
- Do not create fake backend behavior where real persistence/realtime/auth is required.
- Do not use mock data in production paths.
- Do not expose protected personal data merely because it is convenient for the client.
- Enforce permissions on the server/backend, not only in UI.
- Validate all user-controlled input.
- Handle network failure and retries.
- Write tests for important business rules.
- Document setup and environment variables.
- Never commit credentials, API keys, service-role keys, signing keys, or verification secrets.

At the end of each phase:
- build the project;
- run relevant tests;
- fix errors;
- report exactly what was completed;
- report anything blocked;
- do not claim completion if the feature is only mocked.

Do not redesign product behavior unless the specification explicitly leaves a decision open.
```


## 2. ARCHITECTURE GATE — DO THIS BEFORE FEATURE CODING

```text
First determine and document the technical architecture required for Monaco.

The target is a real Android application, not a website that is later wrapped as an afterthought.

Prefer a cross-platform-capable client architecture if it materially reduces future work, while ensuring Android is a first-class target.

The architecture must support:
- secure account authentication;
- verified email;
- verified phone number;
- persistent database;
- real-time messaging;
- media/file storage;
- push notifications;
- offline caching/queueing;
- background synchronization where platform rules allow;
- secure server-side authorization;
- scalable message history;
- voice-message storage/playback;
- search;
- Councils;
- polls;
- Enshrines;
- achievements;
- stickers.

Free-first constraint:
- Prefer open-source/local development tools.
- Prefer free service tiers for the first private deployment.
- Avoid paid infrastructure unless technically necessary.
- Explicitly identify unavoidable recurring costs.
- Phone/SMS verification must be treated as a potentially paid dependency; do not pretend it is free.

Before implementation, produce:
- chosen client framework;
- backend strategy;
- database;
- authentication strategy;
- storage;
- realtime mechanism;
- push notification mechanism;
- local/offline storage;
- search strategy;
- deployment strategy;
- development/staging/production separation;
- backup strategy;
- environment-variable strategy;
- testing strategy;
- why each choice satisfies Monaco's requirements.

If an architecture choice would lock Monaco into a poor future path, explain it before proceeding.
```


## 3. PROJECT FOUNDATION

```text
Create the real Monaco project foundation.

Required:
- clean repository structure;
- client application;
- backend/service layer;
- database migrations/schema;
- environment configuration;
- development configuration;
- production configuration;
- test configuration;
- lint/formatting;
- error handling;
- logging;
- README/setup documentation;
- secure secret handling;
- CI-ready build/test commands.

The project must have a reproducible setup from a clean machine.

Create an explicit setup guide covering:
- prerequisites;
- installation;
- environment variables;
- local database/backend setup;
- development run;
- test run;
- Android build;
- release build;
- deployment.

Do not bury configuration in code.
```


## 4. DATA MODEL / DATABASE

```text
Design a normalized persistent database for Monaco.

At minimum the data model must support:

Users:
- internal immutable user ID;
- username;
- password/auth reference;
- email;
- email verification state;
- phone number;
- phone verification state;
- profile picture reference;
- birthday;
- automatic join date;
- current Monarch identifier;
- account status;
- privacy/settings state;
- created/updated timestamps.

Devices/sessions:
- authenticated sessions;
- device/session metadata required for security;
- push-notification token registration;
- last activity where needed.

Connections:
- requester;
- recipient;
- pending/accepted/declined state;
- timestamps;
- optional introductory message;
- connection/removal state/history as needed.

Conversations:
- private conversation identity;
- participants;
- created time;
- archived state per user;
- local deletion/visibility state per user;
- last-message metadata.

Messages:
- immutable message ID;
- conversation;
- sender;
- message type;
- content/reference;
- creation time;
- edit time;
- deletion state;
- reply target;
- forwarded state/source reference;
- delivery/read state;
- media/file references where applicable.

Councils:
- council ID;
- name;
- icon;
- description;
- creator;
- creation time;
- current status.

Council membership:
- council;
- user;
- membership state;
- admin state;
- joined/left/removed timestamps;
- permission-relevant fields.

Council settings:
- member/admin invitation setting;
- council-info editing setting;
- notification/mute settings as appropriate.

Polls:
- poll;
- question;
- options;
- single/multiple choice;
- anonymous/visible mode;
- creator;
- permanent active state;
- votes;
- vote timestamps;
- change-vote support.

Enshrines:
- source message;
- title;
- creator;
- created time;
- removed state/time;
- historical availability if source message later disappears.

Reactions:
- message;
- user;
- reaction;
- unique-per-user behavior;
- timestamps.

Stickers:
- sticker packs;
- stickers;
- ownership/availability;
- custom pack metadata;
- usage/frequency data.

Voice messages:
- message reference;
- media storage reference;
- duration;
- metadata needed for playback.

Notifications:
- recipient;
- notification type;
- source object;
- read state;
- created time;
- delivery metadata where required.

Achievements:
- achievement definition;
- user achievement;
- earned timestamp;
- progress where needed.

Files/media:
- owner/message reference;
- storage object;
- media type;
- size;
- upload state;
- metadata;
- safe access mechanism.

Privacy/settings:
- read receipts;
- online status;
- typing indicator;
- birthday visibility;
- notification preview;
- per-Council notification preference.

The database must enforce integrity with foreign keys/constraints where appropriate, unique constraints, indexes, and authorization policies.

Do not store secrets or plaintext passwords.
```


## 5. ACCOUNT + AUTHENTICATION

```text
Implement real account creation and login.

Registration must support:
- username;
- password;
- phone number;
- email/Gmail;
- email verification;
- phone verification;
- birthday;
- optional profile picture;
- automatic join date.

Required behavior:
- username validation;
- duplicate username prevention;
- secure password handling;
- email verification;
- phone verification;
- prevention of account creation while required verification is incomplete;
- secure login;
- logout;
- session persistence;
- session expiration/revocation;
- change password;
- secure password reset/recovery;
- account state handling.

Never store plaintext passwords.
Never put authentication secrets in client code.
Use backend-enforced authorization.
Rate-limit login, verification, password reset, and suspicious authentication attempts.
```


## 6. PROFILE + MONARCH ID

```text
Implement the user profile with:
- username/name;
- profile picture;
- join date;
- birthday;
- achievements/records where applicable.

Monarch identity:
- Every normal user receives a Monarch identifier.
- The normal identifier changes periodically according to the configured rotation schedule.
- The creator/owner account is exempt from normal rotation.
- Current Monarch identifiers must be unique among currently active users.
- A person can be found using the current Monarch identifier.
- Searching a Monarch identifier must not expose protected profile information to an unconnected requester.
- Before connection, the person's profile image and identifying information must be obscured/restricted.
- The backend must withhold protected data; do not send sensitive profile data to the client and merely hide it visually.
- Username-based discovery is available according to connection rules.
- Do not expose historical Monarch identifiers as a public stalking/memorization mechanism.

Keep the Monarch rotation implementation configurable so the exact period can be changed without redesigning the system.
```


## 7. CONNECTIONS + PEOPLE

```text
Implement people discovery and connection requests.

Supported routes:
1. Current Monarch identifier search.
2. Username discovery where permitted.
3. One-use direct connection link.

Connection request:
- requester can send one short identifying/introductory message;
- recipient sees who is requesting using the available restricted identity;
- recipient can Accept or Decline;
- acceptance creates the connection;
- decline does not create the connection.

Direct link:
- generated by requester;
- valid for exactly 1 minute;
- can be successfully consumed by only one recipient;
- expires automatically;
- cannot be reused after consumption;
- invalid/expired links fail safely.

After connection:
- normal username/profile visibility;
- private messaging unlocked;
- normal connected-user interactions become available.

Removing a connection:
- quiet/no notification;
- both sides lose ability to contact each other;
- existing chat/history remains;
- either side can later send another connection request;
- archived/deleted chat behavior must remain user-local.

Before connection:
- allow one introductory message only;
- do not unlock normal private conversation until accepted.

No V1 block system unless explicitly added later.
```


## 8. PRIVATE CONVERSATIONS / MESSAGING

```text
Implement one-to-one private conversations.

Required:
- real-time text messaging;
- persistent message history;
- timestamps;
- sent/delivered/read states;
- typing indicator;
- replies;
- reactions;
- media;
- files;
- stickers;
- voice messages;
- editing;
- deletion;
- forwarding;
- search;
- archive;
- delete chat;
- clear chat;
- Enshrines.

Message reliability:
- optimistic send UI;
- server acknowledgement;
- retry after failure;
- no duplicate messages after reconnect;
- ordering based on server-authoritative message identity/timestamps;
- pagination/infinite history loading;
- unread state;
- synchronization across devices.

Editing:
- allowed only within 5 minutes of sending;
- edited message displays an Edited indicator;
- backend enforces the time limit;
- client cannot bypass the limit.

Replies:
- swipe/gesture to reply on mobile;
- reply preview references the original message;
- opening a reply should make the original context discoverable.

Forwarding:
- forward to another private conversation or Council;
- forwarded message displays a non-editable “Forwarded” indicator;
- preserve original-message attribution/reference safely without exposing inaccessible data.

Read receipts:
- sent;
- delivered;
- read;
- user can disable read receipts;
- privacy setting must be enforced consistently.

Typing:
- real-time while online;
- user can disable typing indicators;
- must not remain stuck forever after disconnect/crash.

Message deletion:
- implement a consistent, explicit deletion model;
- do not invent irreversible global deletion semantics that conflict with history/Enshrine requirements;
- if a final deletion distinction is not specified, isolate it behind a policy/service so it can be changed later without rewriting the message system.
```


## 9. BIRTHDAY MESSAGE BEHAVIOR

```text
Store birthday on the user profile.

On the user's birthday:
- every message sent by that user during the birthday date receives birthday message treatment;
- only that user's messages receive the treatment;
- treatment is based on the sender's relevant local date/time rules;
- do not alter message content;
- do not make birthday styling apply permanently to old messages.

The visual treatment is a UI concern, but the backend/message model must expose enough information for the client to determine that a message qualifies.
```


## 10. COUNCILS

```text
Implement Councils as a separate first-class entity from private conversations.

A Council contains:
- name;
- icon/profile picture;
- description;
- members;
- admins;
- messaging;
- Enshrines;
- polls;
- member management;
- Council settings.

Creation:
- any user can create a Council;
- creator initially becomes Admin.

Admins:
- multiple Admins allowed;
- any Admin can promote an existing member to Admin;
- any Admin can transfer/assign admin status to a member;
- any Admin can remove a member;
- any Admin can remove another Admin;
- a Council must never be left without an Admin;
- an Admin may leave only after another Admin exists.

Invitations:
- members can invite people when the Council setting allows it;
- Council setting supports:
  - Admins only;
  - all members.

Council information:
- Admins control Council info by default;
- optional Council setting may allow members to edit Council info.

Leaving/removal:
- removed/left member can no longer participate;
- historical messages remain;
- their old messages remain attributable to their historical sender identity;
- old mentions remain historical;
- after removal, typing their username must not create a live mention target;
- existing historical content is not retroactively rewritten.

Empty Council:
- if no members remain, the Council is automatically deleted.

Council deletion:
- deletion by a user is local to that user's view;
- it must not silently delete the Council/history for everyone else.

Councils and private chats should share the same underlying message engine where practical.
```


## 11. POLLS

```text
Implement permanent Council polls.

Any member can create a poll.

Poll options:
- single choice;
- multiple choice;
- anonymous voting;
- visible voting.

The creator selects the poll's voting mode when creating it.

Rules:
- poll remains active permanently;
- no automatic closing;
- users can change their vote;
- backend validates allowed options;
- anonymous polls must not expose voter identity to other users;
- visible polls may show who selected which option according to the chosen design;
- aggregate results remain available after voting;
- published question/options must not be silently changed after votes exist;
- creator may delete their own poll if the product policy permits; otherwise isolate deletion so it can be changed later.

Any member can create a poll. No admin-only restriction.
```


## 12. ENSHRINES / COUNCIL ARCHIVES

```text
Implement Enshrine as a historical status attached to a message.

Any user can Enshrine a message in a private conversation or Council.

An Enshrine contains:
- source message reference;
- custom title;
- person who created the Enshrine;
- timestamp;
- availability state of the original message.

Only the user who created the Enshrine can remove that Enshrine.

Behavior:
- Enshrined records remain historical records even if the original message later becomes unavailable;
- if the original message still exists, opening the Enshrine can jump to it;
- if unavailable, clearly indicate that the original is unavailable;
- do not delete the Enshrine merely because the source message is unavailable.

Treat Enshrines as a first-class historical/archive feature, not as ordinary bookmarks.
```


## 13. REACTIONS

```text
Implement fast message reactions.

Default quick reactions should include:
- ❤️
- 😂
- 😭
- 💀
- 🤨
- 👍

Provide an additional picker for other supported reactions.

Required:
- add reaction;
- remove own reaction;
- show counts;
- prevent duplicate identical reaction entries from the same user on the same message;
- real-time update where practical;
- work in private chats and Councils.

Do not build custom reaction marketplaces or economies.
```


## 14. STICKERS

```text
Implement V1 sticker support.

Required:
- sticker collection;
- basic built-in sticker packs;
- custom sticker packs/uploads;
- send stickers in private chats and Councils;
- frequently used stickers appear first;
- store sticker metadata and media safely.

Do not build:
- sticker marketplace;
- sticker economy;
- creator monetization system.
```


## 15. VOICE MESSAGES

```text
Implement voice messages.

Required:
- record;
- cancel before sending;
- send;
- playback;
- playback speed control;
- persistent storage;
- duration metadata;
- maximum duration of 1 hour per voice message.

The backend must reject messages exceeding the limit even if a malicious client attempts to bypass the UI.

Use an appropriate compressed audio format and safe upload/download path.
Handle interrupted uploads and failed sends cleanly.
```


## 16. MEDIA + FILES

```text
Implement media/file messages.

Supported categories:
- images;
- videos;
- general files.

Initial normal attachment limit:
- maximum approximately 15 MB per attachment unless the selected infrastructure imposes a lower safe limit.

Initial common formats may include:
Images: JPG/JPEG, PNG, WebP, GIF
Videos: MP4, WebM, MOV
Files: PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX, TXT, ZIP

Do not trust filename extensions alone.
Validate MIME type/content where practical.
Store files outside the database as objects; store metadata/reference in the database.
Use authenticated access.
Do not expose private files through predictable public URLs.
Provide previews/thumbnails where practical.
Files remain downloadable by users who have access.
Handle failed, interrupted, expired, or orphaned uploads.
```


## 17. NOTIFICATIONS

```text
Implement separate notification types rather than one undifferentiated activity stream.

Direct:
- new private message;
- introductory message;
- connection request;
- accepted connection.

Council:
- mention;
- Council invitation;
- poll activity where useful;
- Enshrine activity where useful;
- configurable message notifications.

Personal:
- reply;
- reaction;
- achievement;
- important system/security events.

Global notification controls:
- all;
- messages;
- connections;
- Councils;
- mentions;
- reactions;
- system/achievement.

Per-Council:
- all messages;
- mentions only;
- nothing;
- mute temporarily;
- mute until re-enabled.

Viewed notifications become read.
Pending actions such as connection requests remain pending until acted upon.

Implement push notification registration per device.
Do not put sensitive message content into push payloads when the user's privacy settings prohibit previews.
```


## 18. PRIVACY

```text
Implement privacy as backend-enforced access control plus client controls.

Required controls:
- read receipts on/off;
- online status on/off;
- typing indicator on/off;
- birthday visibility;
- notification message previews;
- per-Council notification settings.

Before connection:
- restricted profile;
- protected information withheld;
- profile picture obscured/restricted;
- no normal private messaging beyond the single introductory message.

After connection:
- normal profile visibility according to settings;
- private communication available.

Do not create:
- public follower system;
- public activity feed;
- public social profile;
- public directory of all users.

Every protected resource must be authorized server-side.
```


## 19. OFFLINE / RECONNECT / SYNC

```text
Monaco must behave sensibly when connectivity is lost.

Required:
- offline indicator;
- cached recent conversations remain readable;
- outgoing messages may be queued locally;
- queued messages send automatically after reconnection;
- failed messages show a retry state;
- duplicate sends are prevented;
- server remains authoritative;
- delivery/read/typing state only synchronizes when connectivity permits;
- app reopening restores the user's recent context;
- background notification/synchronization behavior follows Android platform limits.

Use idempotency/client-generated message IDs or equivalent mechanisms so reconnects cannot create duplicate messages.
```


## 20. SEARCH

```text
Implement search across:
- people;
- messages;
- Councils;
- Enshrines;
- media/files where metadata permits.

Search must respect authorization.
A user must never receive search results for messages, files, Councils, or profiles they are not permitted to access.

Index appropriately for expected growth.
Support pagination.
Avoid scanning the entire database for every query.
```


## 21. ACHIEVEMENTS

```text
Implement pointless/funny achievements as profile history, not competitive ranking.

Initial examples:
- Professional Yapper — 10,000 messages;
- Historian — 25 Enshrines;
- Night Creature — message between 3:00–4:00 AM;
- Sticker Criminal — 1,000 stickers;
- The Unemployed — 100 hours in Monaco;
- Council Menace — 100 reactions.

Achievement engine must:
- calculate eligibility reliably;
- avoid awarding duplicates;
- store earned timestamp;
- remain extensible for new achievements;
- not require a leaderboard.

Achievements should be harmless and non-essential to communication.
```


## 22. MONACO PERSONALITY / EASTER EGGS

```text
Implement Monaco personality only where it does not compromise usability.

Possible rare system flavor:
- 4 AM message: “The Council regrets this decision.”
- immediate deletion: “Evidence destroyed.”
- unanimous poll: “The Council has reached a unanimous decision.”
- 10,000th message: “A historically unnecessary amount of communication has occurred.”

Typing can optionally use Monaco-flavored phrases such as:
- “composing legislation…”
- “consulting the Council…”

These should be rare/configurable and must never interfere with normal function.
Do not let personality features become spam.
```


## 23. NAVIGATION / APP STRUCTURE — FUNCTIONAL ONLY

```text
Implement functional navigation with separate destinations for:
- Conversations;
- Councils;
- Notifications;
- Account/Profile;
- People/Search access.

Private conversations and Councils must remain separate in navigation/listing.

The home experience should feel like a headquarters and be inspired by the clarity of Discord without cloning Discord.

Do not lock exact colors, typography, spacing, animation, or final visual styling here. UI/UX is a separate design phase.
```


## 24. SECURITY FOUNDATION

```text
Security is a build requirement, not a later polish step.

Implement:
- secure password hashing through the chosen auth system;
- secure session/token handling;
- server-side authorization;
- least-privilege database/storage access;
- input validation;
- output encoding where applicable;
- rate limiting;
- abuse prevention for auth/verification/search/link generation;
- secure one-time connection links;
- secret management;
- HTTPS/TLS in deployed environments;
- private file access;
- audit/security logging without storing unnecessary sensitive content;
- dependency vulnerability review;
- safe error messages;
- protection against common injection and authorization failures.

Never trust client-supplied role/admin/ownership fields.
Never allow the client to promote itself to admin.
Never allow the client to bypass message edit limits.
Never allow a client to read another user's protected data by changing an ID.
```


## 25. BACKUPS + RECOVERY

```text
Implement a practical backup and recovery plan.

Required:
- database backup strategy;
- recovery procedure;
- media/file recovery consideration;
- environment/secret recovery documentation without exposing secrets;
- migration safety;
- rollback strategy for failed deployments.

Document:
- what is backed up;
- frequency;
- retention;
- how restoration is tested;
- what data may be lost in worst-case recovery.

For free-tier infrastructure, explicitly document the limits and what would need upgrading for stronger guarantees.
```


## 26. TESTING REQUIREMENTS

```text
Create automated tests for critical business logic.

At minimum test:
- registration/verification;
- login/logout/session rules;
- password changes;
- Monarch uniqueness/rotation;
- restricted pre-connection profile;
- connection request lifecycle;
- one-use one-minute connection links;
- private chat authorization;
- Council membership;
- Council admin promotion/removal;
- prevention of leaving a Council without an Admin;
- empty-Council deletion;
- message sending;
- message edit five-minute limit;
- replies;
- forwarding;
- reactions;
- read/typing settings;
- poll voting/change-vote/anonymous behavior;
- Enshrine ownership/removal;
- file size/type limits;
- voice one-hour limit;
- notification preferences;
- privacy authorization;
- offline queue/deduplication logic.

Also create integration/end-to-end tests for the most important user flows.

No feature is “done” merely because the screen renders.
```


## 27. PERFORMANCE + SCALE BASELINE

```text
The first Monaco deployment is for a private friend group, but the architecture must not be deliberately fragile.

Required:
- paginated message history;
- indexed database queries;
- bounded realtime subscriptions;
- efficient media loading;
- image/video thumbnails where appropriate;
- caching for recent data;
- avoid loading an entire conversation history at once;
- avoid polling when realtime events are appropriate;
- graceful behavior on slow networks;
- reasonable startup time;
- memory-conscious media handling.

Do not overengineer for millions of users in V1.
Design cleanly enough that scaling later is possible.
```


## 28. ANDROID APPLICATION REQUIREMENTS

```text
Deliver a genuine Android application.

Required:
- installable debug APK during development;
- release-capable Android build;
- secure network communication;
- persistent login/session behavior;
- push notifications;
- local caching;
- background behavior within Android rules;
- media permissions requested only when needed;
- microphone permission requested only for voice messages;
- file/media picker behavior;
- share/open behavior where useful;
- proper app identity/package configuration;
- release signing strategy documented;
- no hard-coded development URLs in production.

The first usable release may be distributed directly as an APK to the private group. Do not assume Google Play Store distribution is required for V1.
```


## 29. ENVIRONMENTS + DEPLOYMENT

```text
Maintain at least:
- local development;
- staging/test;
- production.

Never point development builds at production data by accident.

Separate:
- database;
- storage;
- authentication configuration;
- notification configuration;
- API keys/secrets.

Deployment must be reproducible.
Create deployment documentation.
Include health checks and error logging.
Do not expose admin/service credentials to the Android client.
```


## 30. DOCUMENTATION THE AGENT MUST CREATE

```text
The repository must contain:
- README.md;
- architecture.md;
- setup.md;
- environment.example;
- database/schema documentation;
- API/service documentation;
- security.md;
- deployment.md;
- testing.md;
- troubleshooting.md;
- changelog or development log;
- known-limitations.md.

Documentation must describe the actual implementation, not an imagined future system.
Update documentation when architecture changes.
```


## 31. V1 NON-GOALS — DO NOT BUILD THESE

```text
Do not implement unless explicitly requested later:
- public social feed;
- follower/following system;
- public profiles;
- calls;
- video calls;
- screen sharing;
- music system;
- games;
- bots;
- AI assistant inside Monaco;
- marketplace;
- sticker economy;
- monetization;
- public creator ecosystem;
- complex Discord-style role hierarchy;
- public leaderboards;
- large-scale enterprise administration;
- future departments such as Studies, Health, Calendar, Games, etc.;
- custom themes/visual systems before UI design is finalized.

If you think one of these is necessary for a required feature, stop and explain why rather than silently adding it.
```


## 32. FINAL BUILD / ACCEPTANCE PROMPT

```text
When all implementation phases are complete, perform a full Monaco release audit.

Check every requirement in this prompt pack.

For each requirement:
- implemented;
- partially implemented;
- missing;
- blocked.

Then:
1. run the complete test suite;
2. build the Android application;
3. verify backend/database migrations;
4. verify authentication;
5. verify realtime messaging;
6. verify media/file handling;
7. verify notifications;
8. verify privacy/authorization;
9. verify offline/reconnect behavior;
10. verify Council administration;
11. verify polls;
12. verify Enshrines;
13. verify achievements;
14. inspect logs for serious errors;
15. remove debug/mock behavior from production paths;
16. confirm secrets are not committed;
17. produce final setup and deployment instructions.

Do not call Monaco complete if any critical path is mocked, insecure, unbuildable, or missing.
```


## PROMPT EXECUTION ORDER

Use the prompts sequentially. The safest workflow is:
1. Master Instruction
2. Architecture Gate
3. Project Foundation
4. Database
5. Authentication
6. Core communication
7. Councils
8. Secondary features
9. Security/privacy
10. Offline/reconnect
11. Testing
12. Android build
13. Deployment
14. Final audit

If the agent discovers a genuine requirement conflict, it must stop and report it rather than silently inventing behavior.

## WHAT THIS FILE IS NOT

This is not the final UI design or a promise that every external service will remain free forever. It is the construction prompt pack for the coding agent.
