-- Migration: 002_conversation_preview_indexes.up.sql
-- Description: Add composite index for conversation last-message preview queries
-- These indexes optimize the subqueries used in GET /conversations and GET /conversations/:id

CREATE INDEX IF NOT EXISTS idx_messages_conv_active_created
  ON messages(conversation_id, deletion_state, created_at DESC);

-- Index for participant lookup by user + conversation
CREATE INDEX IF NOT EXISTS idx_conv_participants_conv_user
  ON conversation_participants(conversation_id, user_id);

-- Index for user search by username
CREATE INDEX IF NOT EXISTS idx_users_username_ilike
  ON users(username text_pattern_ops);
