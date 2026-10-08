# MONACO — MASTER PRODUCT SPECIFICATION
## Moanark Council

**Purpose:** Master functional/product reference before final UI and technical planning.

**UI status:** Not final and deliberately excluded from detailed specification.

## 1. Product Identity

### Name

Monaco
Full identity: Moanark Council.

### Core idea

Monaco is a private digital headquarters for a friend group. It is an actual application/platform, not merely a website or simple chat page.

Messaging is the foundation. Councils, Enshrines, achievements, stickers, polls, and personality make Monaco feel like a place belonging to the group.

Useful product distinction: “WhatsApp is where you talk to people. Monaco is where your group lives.”

### Product philosophy

Function and quality matter more than being different for its own sake. Use established interaction patterns where they already solve a problem well. Monaco-specific ideas should exist where they add genuine identity or usefulness. Avoid designing large features that may never be built. Undesigned future departments remain “Future — Undesigned.”

## 2. V1 Scope

### Communication

Accounts/authentication; private one-to-one conversations; Councils; real-time messaging; replies; reactions; media; files; stickers; voice messages; editing; deleting; read status; typing status; forwarding; search; notifications; archive/delete/clear conversation controls.

### Council

Council creation; name; icon; description; members; multiple admins; invitations; Council permissions; polls; Enshrines; Council Archives.

### Personality

Council terminology; Enshrines as historical records; pointless/funny achievements; stickers; birthday message treatment; small Easter eggs; historical/funny system wording.

## 3. Deliberately Out of V1

### Deferred

Voice calls; video calls; screen sharing; stories; custom Council themes; complex role hierarchies; advanced permissions; custom reactions; Council Lore as a separate system; major multi-device ecosystem; bots; AI assistant; public communities; monetization; social feed; large-scale public discovery; advanced customization; future departments not yet designed.

## 4. Account

### Registration

Required: username, password, phone number with genuine verification, email/Gmail with genuine verification, birthday. Optional: profile picture. Automatic: join date. Username and display name are the same identity field; there is no separate display-name system.

### Profile

Username/name; profile picture; join date; birthday; achievements/records. No LinkedIn-style profile-field system.

### Controls

Login; logout; change password; forgot password; change email; change phone; active sessions/devices; logout other sessions; delete account.

### Security defaults

Rate-limit failed logins. Password reset uses a verified recovery method. Changing email/phone requires verification of the new contact method. Changing password terminates other sessions by default. Sensitive actions require re-authentication.

### Account deletion

Permanent deletion requires a warning, re-authentication/password confirmation, and explicit confirmation. Personal account information is removed. Historical Council messages may remain where necessary as conversation history.

## 5. Monarch ID

### Purpose

A changing discovery identifier, primarily for finding someone you do not already know.

### Rotation concept

A normal user's identifier changes periodically, currently envisioned as approximately weekly. Example: Week 1 Monarch 09; Week 2 Monarch 32; Week 3 Monarch 71. The creator's number does not change.

### Discovery

Searching “Monarch 09” can surface the person currently assigned that identifier. Before connection, identifying information is restricted/obscured. The backend should actually withhold protected data rather than exposing real data as decorative ciphertext.

### Purpose of rotation

The changing identifier makes it harder to memorize a permanent number and use it for long-term tracking. Exact rotation mechanics are a later technical decision.

## 6. Connections / People

### Ways to connect

Current Monarch ID; username where applicable/known; one-use direct connection link.

### Direct link

Valid for 1 minute; only one person can successfully use it; consumed after acceptance/use; expires if unused.

### Request

Example: “Monarch 27 wants to connect with you.” Actions: Accept or Decline. Requester may include a short identifying message such as “Hey, it's Alex — I'm the person from college.”

### Before connection

One introductory message may be sent to explain who the requester is or why they are connecting. Normal private messaging stays locked until acceptance.

### After connection

Normal private messaging, username visibility, profile-picture visibility, and normal profile visibility according to privacy settings become available.

### Removing a connection

Either side can remove it silently. No notification. Neither side can continue contacting the other through the connection. Either can later send another request. Existing conversation history remains and can be archived, deleted, or cleared.

## 7. Private Conversations

### Core

Real-time messages; timestamps; replies; reactions; media; files; stickers; voice messages; edit; delete; read status; typing status; forwarding; archive; delete conversation; clear conversation; search within conversation; Enshrines.

### Replies

Use familiar attachment-style replies. Swipe to reply. Reply preview references the original message. Example: Alex: “We are absolutely not putting a chicken in the basement.” Reply: “↳ Alex: We are absolutely not putting a chicken in the basement. Daniel: Too late.”

### Editing

Behaves like established modern messaging apps. A message can be edited only within 5 minutes of sending. After editing it shows an “Edited” indicator.

### Deletion

Message deletion exists as a normal message control. Exact local-vs-everyone semantics can be finalized with implementation rules and should remain consistent across private chats and Councils.

### Forwarding

Messages can be forwarded to another private conversation or Council. Forwarded messages display a “Forwarded” indicator; this is a message property, not editable text.

### Read status

States: Sent, Delivered, Read. Users can disable read receipts. If disabled, their read state is not exposed to others.

### Typing

Normal: “Alex is typing...” Optional Monaco variants: “Alex is composing legislation...”, “Alex is consulting the Council...”, “Alex is drafting legislation...”. Exact settings are UI work later.

## 8. Birthdays

### Behaviour

Birthday is stored on the profile. On the person's birthday, every message they send that day receives a special birthday visual treatment. Only that person's messages receive it. Exact visual design is deferred.

## 9. Councils

### Council information

Name; icon/profile picture; description; members; admins; messages; polls; Enshrines; Archives.

### Terminology

Prefer thematic language such as “The Council was established by Sir Alex” or “The Council was created by Sir Alex.”

### Conversation

Councils use the same core messaging engine as private conversations, expanded with membership and administration.

## 10. Council Administration

### Creation

Anyone can create a Council. Creator initially becomes Admin.

### Admins

Multiple admins are allowed. Any Admin can promote a member, transfer Admin status to any member, remove a member, or remove another Admin.

### Leaving

An Admin cannot leave if doing so would leave the Council without an Admin. They must appoint another Admin first.

### Invites

Council setting chooses either Admins only or all members can invite.

### Council info

By default Admins control name, icon/profile picture, and description. A setting may allow all members to edit them.

### Member removal/leaving

The person can no longer participate, but historical messages remain. Old mentions no longer function as active mentions; typing the username later is ordinary text.

### Empty Council

If a Council reaches zero members, it is automatically deleted.

### Local deletion

Deleting a Council from one user's view is local to that user. Other members may retain the Council and its history.

## 11. Polls

### Creation

Anyone can create a poll.

### Types

Single choice or multiple choice.

### Voting

Users can vote and change their vote.

### Visibility

Creator chooses anonymous or visible voting.

### Lifetime

Polls remain active permanently. No close button, expiry, end date, or mandatory final state.

### V1 defaults

Results remain visible after voting. Anonymous polls still show aggregate counts. Poll question/options are not silently editable after publication; deleting and recreating is the clean V1 behaviour. Creator can delete their own poll as normal content.

## 12. Enshrines

### Concept

An Enshrine turns a message into a historical record, not merely a bookmark. Conceptually: Message → historical status. Works in private conversations and Councils.

### Who can create

Anyone can Enshrine a message.

### Removal

Only the person who created the Enshrine can remove it.

### Title

Every Enshrine can have a custom title.

### Example

📜 Council Archives

The Great Chicken Incident

“WHY IS THERE A CHICKEN IN THE BASEMENT”

Enshrined by Sir Daniel
October 8, 2026

### Deleted original

If the original message is later deleted, the Enshrine remains as a historical record and clearly indicates that the original message is no longer available.

### Navigation

When the original message still exists, opening an Enshrine can take the user directly to that message.

## 13. Reactions

### Behaviour

Basic reactions are required. Fast picker examples: ❤️ 😂 😭 💀 🤨 👍. A + control provides more reactions. Counts are displayed. Advanced/custom Monaco-specific reactions are deferred.

## 14. Stickers

### V1

Send stickers; sticker collection; basic packs; custom sticker packs/uploads; frequently used stickers first. No marketplace, economy, or creator ecosystem.

## 15. Voice Messages

### Behaviour

Record; cancel before sending; send; playback; playback speed control. Maximum duration: 1 hour per voice message. Technical compression/storage limits are an architecture decision.

## 16. Media and Files

### Initial limit

15 MB per normal attachment.

### Images

JPG/JPEG, PNG, WebP, GIF. Maximum 15 MB.

### Video

MP4, WebM, MOV. Maximum 15 MB.

### Files

PDF, DOC/DOCX, XLS/XLSX, PPT/PPTX, TXT, ZIP. Maximum 15 MB.

### Behaviour

Images/videos get previews. Files show filename, type and size. Files remain downloadable. Failed uploads can be retried. Media is sent inside conversations. No public media gallery is required.

## 17. Notifications

### Types

Direct: new private message, introductory message, connection request, connection accepted. Council: Council activity according to settings, mentions, poll activity, Enshrine activity, Council invitations. Personal: replies, reactions, achievements, other system events.

### Global controls

All notifications; messages; connections; Councils; mentions; reactions; system/achievement notifications.

### Per Council

All messages; mentions only; nothing; temporary mute; mute until manually enabled.

### Read behaviour

Viewed notifications become read. Important pending actions such as connection requests can remain visually pending until acted upon.

## 18. Privacy

### Discovery

Monarch ID is the primary discovery method for unknown people. Restricted profiles protect identity before connection. Username discovery applies where appropriate after connection.

### Profile

Connected people see normal profile information according to settings; before connection, identifying information is restricted.

### Birthday

Can be hidden. Default: visible to connected people.

### Online status

Can be hidden.

### Read receipts

Can be disabled.

### Typing indicator

Can be disabled.

### Notification previews

User can choose whether private message content appears in push/lock-screen notifications.

### Public identity

No public follower system, public activity feed, public social profile, or requirement for Monaco to behave as a public social network.

## 19. App Behaviour

### Offline

Show offline state. Recently cached conversations remain readable. Pending messages retry automatically after reconnection. Failed messages can be manually retried.

### Duplicate prevention

Reconnection must not create duplicate messages. Server state is authoritative.

### Background

Push notifications continue. Synchronization and media transfers continue where the operating system permits. Typing status stops after leaving the active conversation.

### Restore

When reopening, Monaco should restore the user's last active context where practical.

### Conflict

Server state wins when devices disagree.

## 20. Search

### Categories

People; messages; Councils; Enshrines; media/files.

### Behaviour

Results should be categorized rather than shown as one confusing undifferentiated list. Monarch ID search is important for first-time discovery; username search is useful once people are known/connected.

## 21. Achievements

### Purpose

Pointless/funny records, not serious competitive gamification.

### Examples

Professional Yapper — 10,000 messages; Historian — 25 Enshrines; Night Creature — message between 3–4 AM; Sticker Criminal — 1,000 stickers; The Unemployed — 100 hours in Monaco; Council Menace — 100 reactions.

### Leaderboard

No default competitive leaderboard.

## 22. Easter Eggs

### Examples

4 AM message: “The Council regrets this decision.” Immediately deleted message: “Evidence destroyed.” Unanimous poll: “The Council has reached a unanimous decision.” 10,000th message: “A historically unnecessary amount of communication has occurred.”

### Rule

Rare and unobtrusive; they must not interfere with normal functionality.

## 23. Navigation / Home — Functional Direction Only

### Direction

Inspired primarily by Discord's clear separation of major destinations, but not a visual clone.

### Destinations

Conversations; Councils; Notifications; Account/Profile; People/Search access.

### Important

Conversations and Councils remain separate destinations. Avoid a giant hamburger menu full of unrelated options.

### Deferred

Exact home screen, layout, icons, colours, themes, spacing, animation, typography, visual hierarchy, and screen composition are all UI/UX work later.

## 24. User Flows

### New account

Open Monaco → Create account → username → password → verify phone → verify email → birthday → optional profile picture → Monaco.

### Find someone

Search Monarch ID → restricted profile → introductory message → connection request → recipient accepts → full connection → private conversation unlocked.

### Direct link

Generate link → one-minute validity → recipient opens → sees identifying context → accepts → link consumed.

### Private conversation

Open connected person → send → sent/delivered/read → reply/react/edit/forward/Enshrine/delete as applicable.

### Create Council

Create Council → name → icon → description → creator becomes Admin → invite → begin conversation.

### Council management

Open Council → members/admin controls → promote/remove members where permitted → configure invitation permissions → configure Council-info editing permissions.

### Poll

Create → question → options → single/multiple → anonymous/visible → publish → vote → change vote → remains active indefinitely.

### Enshrine

Select message → Enshrine → custom title → save → Archive → only creator can remove.

## 25. Functional Architecture Concept

### Layer 1 — Communication

Accounts; authentication; messages; real-time delivery; media; replies; editing; deleting; reactions; typing; read receipts; notifications.

### Layer 2 — Council

Councils; members; Council profiles; polls; Enshrines; Archives; achievements.

### Layer 3 — Personality

Council language; funny system messages; Easter eggs; pointless achievements; sticker culture; historical records; future lore; custom reactions; surprises.

### Reason

Personality can evolve without rebuilding the communication foundation.

## 26. Future Decision Rules

### Checklist

1. Does it solve a real problem? 2. Is it necessary for V1? 3. Does it help the actual friend group? 4. Can an established pattern solve it reliably? 5. Does it create unnecessary complexity? 6. Does it belong in current scope? 7. If not, put it in Future — Undesigned.

### Principle

A feature should not exist merely to make Monaco look different.

## 27. UI/UX — Deliberately Deferred

### Not final

Exact home screen; exact navigation layout; screen-by-screen UI; colours; themes; typography; icons; buttons; message bubble design; Council visual identity; profile layout; notification layout; animation; transitions; responsive layouts; mobile/desktop visual differences.

### Purpose

This master document defines the functional behaviour the eventual UI must support. It is not the final visual specification.

## 28. Technical Architecture — Deferred

### Not locked

Database architecture; backend architecture; storage provider; authentication implementation; real-time protocol; hosting; mobile framework; desktop framework; web framework; deployment strategy.

### Order

Technical choices should follow the finalized product requirements and sufficiently defined UI/UX.

## 29. V1 Completion Principle

### Goal

Build Monaco well enough that the friend group can actually use it as its private home.

### Priority

Communication must be dependable. Councils must be simple. Personality should make Monaco memorable. Everything else can wait.

## 30. Example Bank

### Connection

“Monarch 27 wants to connect with you.”

### Council establishment

“The Council was established by Sir Alex.”

### Typing

“Alex is consulting the Council...”

### Enshrine

📜 The Great Chicken Incident — “WHY IS THERE A CHICKEN IN THE BASEMENT” — Enshrined by Sir Daniel — October 8, 2026.

### Deletion Easter egg

“Evidence destroyed.”

### Unanimous poll

“The Council has reached a unanimous decision.”

### 10,000th message

“A historically unnecessary amount of communication has occurred.”

### Birthday

Every message sent by the birthday person receives the day's special birthday treatment.

## 31. Final Status

### Defined enough for next stage

Product identity; account/authentication requirements; profiles; Monarch ID; connections; private conversations; Councils; Council administration; polls; Enshrines; reactions; stickers; voice messages; media/files; notifications; privacy; security; deletion; offline behaviour; search; achievements; Easter eggs; user flows; functional navigation direction; V1 exclusions.

### Deliberately not final

UI; colours; themes; exact screen designs; technical architecture; backend implementation; database schema; hosting/deployment.

