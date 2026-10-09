-- Migration: 001_initial_schema.up.sql
-- Description: Core schema for Monaco V1
-- Author: Monaco Team
-- Generated: 2026-10-09

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- Users table
-- ============================================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  email_verified BOOLEAN DEFAULT FALSE,
  birthday DATE,
  profile_picture_url TEXT,
  current_monarch_id VARCHAR(255),
  is_creator BOOLEAN DEFAULT FALSE,
  account_status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- ============================================================
-- Monarch IDs table
-- ============================================================
CREATE TABLE monarch_ids (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  monarch_id VARCHAR(255) NOT NULL UNIQUE,
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for monarch_ids
CREATE INDEX idx_monarch_ids_monarch_id ON monarch_ids(monarch_id);
CREATE INDEX idx_monarch_ids_active ON monarch_ids(is_active) WHERE is_active = TRUE;

-- ============================================================
-- Connections table
-- ============================================================
CREATE TABLE connections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id UUID REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  intro_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  UNIQUE(requester_id, recipient_id)
);

-- Indexes for connections
CREATE INDEX idx_connections_requester ON connections(requester_id);
CREATE INDEX idx_connections_recipient ON connections(recipient_id);
CREATE INDEX idx_connections_status ON connections(status);

-- ============================================================
-- Direct conversations / private conversations
-- ============================================================
CREATE TABLE direct_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255), -- null for private 1:1, or a label
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Conversation participants
-- ============================================================
CREATE TABLE conversation_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES direct_conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('member', 'admin')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  UNIQUE(conversation_id, user_id)
);

-- Indexes for conversation participants
CREATE INDEX idx_conv_participants_user ON conversation_participants(user_id);
CREATE INDEX idx_conv_participants_conv ON conversation_participants(conversation_id);

-- ============================================================
-- Messages table
-- ============================================================
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES direct_conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE SET NULL,
  reply_to UUID REFERENCES messages(id) ON DELETE SET NULL,
  content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('text', 'image', 'video', 'file', 'voice', 'system')),
  content_reference TEXT, -- S3/R2 reference or media metadata
  content_text TEXT, -- for text messages only
  edit_count INTEGER DEFAULT 0,
  edited_at TIMESTAMPTZ,
  deletion_state VARCHAR(50) DEFAULT 'active' CHECK (deletion_state IN ('active', 'deleted_for_sender', 'deleted_for_everyone')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  edited_at TIMESTAMPTZ
);

-- Indexes for messages
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- ==========================================================--
-- Read receipts
-- =============================================================
CREATE TABLE read_receipts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

-- Index for read receipts
CREATE INDEX idx_read_receipts_message ON read_receipts(message_id);
CREATE INDEX idx_read_receipts_user ON read_receipts(user_id);

-- ==========================================================--
-- Reactions table
-- =============================================================
CREATE TABLE reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  reaction VARCHAR(50) NOT NULL CHECK (reaction IN ('heart', 'laugh', 'cry', 'skull', 'suspicious', 'thumbs-up')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id, reaction)
);

-- Indexes for reactions
CREATE INDEX idx_reactions_message ON reactions(message_id);
CREATE INDEX idx_reactions_user ON reactions(user_id);

-- ==========================================================--
-- Councils table
-- =============================================================
CREATE TABLE councils (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  icon_url TEXT,
  creator_id UUID REFERENCES users(id) ON DELETE SET NULL,
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for councils
CREATE INDEX idx_councils_creator ON councils(creator_id);
CREATE INDEX idx_councils_archived ON councils(is_archived);

-- ==========================================================--
-- Council members table
-- =============================================================
CREATE TABLE council_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  council_id UUID REFERENCES councils(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('member', 'admin')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  UNIQUE(council_id, user_id)
);

-- Indexes for council members
CREATE INDEX idx_council_members_council ON council_members(council_id);
CREATE INDEX idx_council_members_user ON council_members(user_id);

-- ==========================================================--
-- Council settings table
-- =============================================================
CREATE TABLE council_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  council_id UUID REFERENCES councils(id) ON DELETE CASCADE,
  allow_member_invitations BOOLEAN DEFAULT FALSE,
  allow_member_edit_info BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(council_id)
);

-- ==========================================================--
-- Polls table
-- =============================================================
CREATE TABLE polls (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  council_id UUID REFERENCES councils(id) ON DELETE CASCADE,
  question VARCHAR(500) NOT NULL,
  is_anonymous BOOLEAN DEFAULT FALSE,
  creator_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================================--
-- Poll options table
-- =============================================================
CREATE TABLE poll_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
  option_text VARCHAR(500) NOT NULL,
  option_order INTEGER DEFAULT 0,
  UNIQUE(poll_id, option_order)
);

-- Indexes for poll options
CREATE INDEX idx_poll_options_poll ON poll_options(poll_id);

-- ==========================================================--
-- Poll votes table
-- =============================================================
CREATE TABLE poll_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  option_id UUID REFERENCES poll_options(id) ON DELETE SET NULL,
  voted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(poll_id, user_id)
);

-- Indexes for poll votes
CREATE INDEX idx_poll_votes_poll ON poll_votes(poll_id);
CREATE INDEX idx_poll_votes_user ON poll_votes(user_id);

-- ==========================================================--
-- Enshrines table
-- =============================================================
CREATE TABLE enshrines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  is_removed BOOLEAN DEFAULT FALSE,
  removed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(source_message_id, creator_id)
);

-- Indexes for enshrines
CREATE INDEX idx_enshrines_message ON enshrines(source_message_id);
CREATE INDEX idx_enshrines_creator ON enshrines(creator_id);

-- ==========================================================--
-- Refresh tokens table (for session management)
-- =============================================================
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token_hash)
);

-- Index for refresh tokens
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);

-- ==========================================================--
-- Audit log (optional, for security monitoring)
-- =============================================================
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL,
  path VARCHAR(500),
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for audit log
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at);

-- ==========================================================--
-- Update triggers for updated_at columns
-- =============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_users
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_councils
  BEFORE UPDATE ON councils
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ==========================================================--
-- Security: Row Level Security policies (disabled by default,
-- enabled per D3 Supabase setup)
-- =============================================================
-- These policies are commented out for initial setup.
-- Uncomment and configure after Supabase project is created.
--
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Users can read own data" ON users FOR SELECT USING (auth.uid() = id);
-- CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);
--
-- ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Participants can read conversation" ON conversations FOR SELECT USING (TRUE);
-- CREATE POLICY "Members can send messages" ON messages FOR INSERT WITH CHECK (TRUE);