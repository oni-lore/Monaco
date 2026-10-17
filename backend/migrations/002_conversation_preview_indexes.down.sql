-- Migration: 002_conversation_preview_indexes.down.sql
DROP INDEX IF EXISTS idx_messages_conv_active_created;
DROP INDEX IF EXISTS idx_conv_participants_conv_user;
DROP INDEX IF EXISTS idx_users_username_ilike;
