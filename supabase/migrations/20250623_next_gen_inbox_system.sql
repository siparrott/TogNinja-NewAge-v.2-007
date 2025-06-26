-- Next-Generation Inbox System Migration
-- Comprehensive email management with Gmail/SMTP/POP3 integration

-- Email Accounts (for multiple email account management)
CREATE TABLE IF NOT EXISTS email_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL, -- Display name for the account
  email_address text NOT NULL,
  provider text NOT NULL CHECK (provider IN ('gmail', 'outlook', 'yahoo', 'imap', 'pop3', 'smtp', 'exchange')),
  
  -- Connection settings
  incoming_server text, -- IMAP/POP3 server
  incoming_port integer,
  incoming_security text CHECK (incoming_security IN ('none', 'ssl', 'tls', 'starttls')),
  outgoing_server text, -- SMTP server
  outgoing_port integer,
  outgoing_security text CHECK (outgoing_security IN ('none', 'ssl', 'tls', 'starttls')),
  
  -- Authentication
  username text,
  password_encrypted text, -- Encrypted password
  oauth_token_encrypted text, -- For OAuth providers like Gmail
  oauth_refresh_token_encrypted text,
  oauth_expires_at timestamptz,
  
  -- Settings
  is_default boolean DEFAULT false,
  sync_enabled boolean DEFAULT true,
  sync_frequency_minutes integer DEFAULT 5,
  sync_folders text[] DEFAULT ARRAY['INBOX', 'Sent', 'Drafts', 'Trash'],
  last_sync_at timestamptz,
  
  -- Signatures
  signature_html text,
  signature_text text,
  auto_signature boolean DEFAULT true,
  
  -- Status
  status text DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'error', 'syncing')),
  last_error text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Email Folders/Labels
CREATE TABLE IF NOT EXISTS email_folders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid REFERENCES email_accounts(id) ON DELETE CASCADE,
  name text NOT NULL,
  display_name text,
  folder_type text DEFAULT 'custom' CHECK (folder_type IN ('inbox', 'sent', 'drafts', 'trash', 'spam', 'archive', 'custom')),
  parent_folder_id uuid REFERENCES email_folders(id),
  remote_folder_id text, -- Remote folder ID from email provider
  unread_count integer DEFAULT 0,
  total_count integer DEFAULT 0,
  sync_enabled boolean DEFAULT true,
  color text,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enhanced Messages Table
CREATE TABLE IF NOT EXISTS email_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid REFERENCES email_accounts(id) ON DELETE CASCADE,
  folder_id uuid REFERENCES email_folders(id),
  
  -- Message identifiers
  message_id text NOT NULL, -- RFC Message-ID
  thread_id text,
  in_reply_to text,
  references text,
  remote_message_id text, -- Provider-specific ID (Gmail ID, etc.)
  
  -- Headers
  from_email text NOT NULL,
  from_name text,
  to_emails text[] NOT NULL,
  to_names text[],
  cc_emails text[],
  cc_names text[],
  bcc_emails text[],
  bcc_names text[],
  reply_to text,
  subject text,
  
  -- Content
  body_text text,
  body_html text,
  preview_text text, -- First 150 chars for preview
  
  -- Metadata
  date_sent timestamptz,
  date_received timestamptz DEFAULT now(),
  size_bytes integer,
  importance text DEFAULT 'normal' CHECK (importance IN ('low', 'normal', 'high')),
  priority integer DEFAULT 3, -- 1 (highest) to 5 (lowest)
  
  -- Status flags
  is_read boolean DEFAULT false,
  is_starred boolean DEFAULT false,
  is_flagged boolean DEFAULT false,
  is_draft boolean DEFAULT false,
  is_sent boolean DEFAULT false,
  is_archived boolean DEFAULT false,
  is_deleted boolean DEFAULT false,
  is_spam boolean DEFAULT false,
  
  -- Advanced features
  has_attachments boolean DEFAULT false,
  attachment_count integer DEFAULT 0,
  labels text[], -- Custom labels/tags
  categories text[], -- Email categories
  
  -- AI/ML features
  sentiment_score real, -- -1 (negative) to 1 (positive)
  urgency_score real, -- 0 to 1
  spam_score real, -- 0 to 1
  auto_classified_category text,
  extracted_entities jsonb, -- Extracted names, dates, etc.
  
  -- Tracking
  is_tracked boolean DEFAULT false,
  opened_at timestamptz,
  open_count integer DEFAULT 0,
  link_clicks jsonb, -- Track clicked links
  
  -- Security
  is_encrypted boolean DEFAULT false,
  is_signed boolean DEFAULT false,
  security_status text DEFAULT 'unknown' CHECK (security_status IN ('secure', 'warning', 'danger', 'unknown')),
  
  -- Collaboration
  assigned_to uuid REFERENCES auth.users(id),
  assigned_at timestamptz,
  due_date timestamptz,
  follow_up_date timestamptz,
  snooze_until timestamptz,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Email Attachments
CREATE TABLE IF NOT EXISTS email_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid REFERENCES email_messages(id) ON DELETE CASCADE,
  filename text NOT NULL,
  content_type text,
  size_bytes integer,
  content_id text, -- For inline attachments
  is_inline boolean DEFAULT false,
  
  -- Storage
  file_path text, -- Local storage path
  cloud_url text, -- Cloud storage URL
  thumbnail_url text, -- For image previews
  
  -- Security scanning
  virus_scan_status text DEFAULT 'pending' CHECK (virus_scan_status IN ('pending', 'clean', 'infected', 'error')),
  virus_scan_result text,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Email Templates
CREATE TABLE IF NOT EXISTS email_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  subject text,
  body_html text,
  body_text text,
  category text,
  is_shared boolean DEFAULT false,
  usage_count integer DEFAULT 0,
  variables jsonb, -- Template variables like {{name}}, {{company}}
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Email Rules (Filters)
CREATE TABLE IF NOT EXISTS email_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id uuid REFERENCES email_accounts(id) ON DELETE CASCADE,
  name text NOT NULL,
  is_enabled boolean DEFAULT true,
  priority integer DEFAULT 50, -- Higher number = higher priority
  
  -- Conditions (all must match for AND, any for OR)
  condition_logic text DEFAULT 'AND' CHECK (condition_logic IN ('AND', 'OR')),
  conditions jsonb NOT NULL, -- Array of condition objects
  
  -- Actions
  actions jsonb NOT NULL, -- Array of action objects
  
  -- Statistics
  matched_count integer DEFAULT 0,
  last_matched_at timestamptz,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Email Contacts (Address Book)
CREATE TABLE IF NOT EXISTS email_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  name text,
  display_name text,
  company text,
  job_title text,
  phone text,
  notes text,
  
  -- Contact frequency and relationship
  email_count integer DEFAULT 0,
  last_email_date timestamptz,
  first_email_date timestamptz,
  relationship_strength real DEFAULT 0, -- 0 to 1
  
  -- Social/Professional info
  linkedin_url text,
  twitter_handle text,
  website text,
  
  -- Grouping
  groups text[], -- Contact groups
  tags text[], -- Custom tags
  
  -- AI insights
  communication_pattern jsonb, -- Preferred communication times, etc.
  interests text[], -- Extracted from email content
  
  is_vip boolean DEFAULT false,
  is_blocked boolean DEFAULT false,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Email Conversations/Threads
CREATE TABLE IF NOT EXISTS email_conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id text NOT NULL,
  account_id uuid REFERENCES email_accounts(id) ON DELETE CASCADE,
  subject text,
  participants text[] NOT NULL, -- All email addresses in conversation
  message_count integer DEFAULT 0,
  unread_count integer DEFAULT 0,
  
  -- Status
  is_archived boolean DEFAULT false,
  is_muted boolean DEFAULT false,
  is_important boolean DEFAULT false,
  
  -- Dates
  first_message_date timestamptz,
  last_message_date timestamptz,
  last_activity_date timestamptz DEFAULT now(),
  
  -- AI/ML insights
  conversation_summary text, -- AI-generated summary
  key_topics text[], -- Extracted topics
  action_items text[], -- Extracted action items
  sentiment_trend real[], -- Sentiment over time
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Email Search Index (for fast full-text search)
CREATE TABLE IF NOT EXISTS email_search_index (
  message_id uuid PRIMARY KEY REFERENCES email_messages(id) ON DELETE CASCADE,
  search_vector tsvector,
  content_text text, -- Combined searchable text
  updated_at timestamptz DEFAULT now()
);

-- Email Analytics
CREATE TABLE IF NOT EXISTS email_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id uuid REFERENCES email_accounts(id),
  date date NOT NULL,
  
  -- Volume metrics
  emails_received integer DEFAULT 0,
  emails_sent integer DEFAULT 0,
  emails_read integer DEFAULT 0,
  emails_deleted integer DEFAULT 0,
  emails_archived integer DEFAULT 0,
  
  -- Response metrics
  average_response_time_hours real,
  response_rate real, -- Percentage of emails responded to
  
  -- Time patterns
  peak_activity_hour integer, -- Hour of day with most activity
  weekend_activity_percentage real,
  
  -- Contact metrics
  unique_senders integer DEFAULT 0,
  unique_recipients integer DEFAULT 0,
  
  -- AI insights
  productivity_score real, -- 0 to 1
  email_overload_score real, -- 0 to 1
  
  created_at timestamptz DEFAULT now()
);

-- Email Tracking (for sent emails)
CREATE TABLE IF NOT EXISTS email_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid REFERENCES email_messages(id) ON DELETE CASCADE,
  recipient_email text NOT NULL,
  
  -- Tracking events
  sent_at timestamptz DEFAULT now(),
  delivered_at timestamptz,
  opened_at timestamptz,
  first_open_at timestamptz,
  last_open_at timestamptz,
  open_count integer DEFAULT 0,
  
  -- Link tracking
  links_clicked jsonb, -- Array of clicked links with timestamps
  
  -- Device/Location info
  device_info jsonb,
  location_info jsonb,
  user_agent text,
  ip_address inet,
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_email_messages_account_folder ON email_messages(account_id, folder_id);
CREATE INDEX IF NOT EXISTS idx_email_messages_thread ON email_messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_email_messages_date ON email_messages(date_received DESC);
CREATE INDEX IF NOT EXISTS idx_email_messages_unread ON email_messages(is_read, date_received DESC);
CREATE INDEX IF NOT EXISTS idx_email_messages_starred ON email_messages(is_starred) WHERE is_starred = true;
CREATE INDEX IF NOT EXISTS idx_email_messages_assigned ON email_messages(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_email_search_vector ON email_search_index USING gin(search_vector);
CREATE INDEX IF NOT EXISTS idx_email_contacts_email ON email_contacts(email);
CREATE INDEX IF NOT EXISTS idx_email_analytics_user_date ON email_analytics(user_id, date);

-- Full-text search index
CREATE INDEX IF NOT EXISTS idx_email_messages_search ON email_messages USING gin(to_tsvector('english', coalesce(subject, '') || ' ' || coalesce(body_text, '') || ' ' || coalesce(from_name, '') || ' ' || coalesce(from_email, '')));

-- Enable Row Level Security
ALTER TABLE email_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_search_index ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_tracking ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can manage their own email accounts"
  ON email_accounts FOR ALL TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can access their account folders"
  ON email_folders FOR ALL TO authenticated
  USING (account_id IN (SELECT id FROM email_accounts WHERE user_id = auth.uid()));

CREATE POLICY "Users can access their account messages"
  ON email_messages FOR ALL TO authenticated
  USING (account_id IN (SELECT id FROM email_accounts WHERE user_id = auth.uid()));

CREATE POLICY "Users can access their message attachments"
  ON email_attachments FOR ALL TO authenticated
  USING (message_id IN (SELECT id FROM email_messages WHERE account_id IN (SELECT id FROM email_accounts WHERE user_id = auth.uid())));

CREATE POLICY "Users can manage their own templates"
  ON email_templates FOR ALL TO authenticated
  USING (user_id = auth.uid() OR is_shared = true);

CREATE POLICY "Users can manage their own rules"
  ON email_rules FOR ALL TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can manage their own contacts"
  ON email_contacts FOR ALL TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can access their conversations"
  ON email_conversations FOR ALL TO authenticated
  USING (account_id IN (SELECT id FROM email_accounts WHERE user_id = auth.uid()));

CREATE POLICY "Users can access their search index"
  ON email_search_index FOR ALL TO authenticated
  USING (message_id IN (SELECT id FROM email_messages WHERE account_id IN (SELECT id FROM email_accounts WHERE user_id = auth.uid())));

CREATE POLICY "Users can access their analytics"
  ON email_analytics FOR ALL TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can access their tracking data"
  ON email_tracking FOR ALL TO authenticated
  USING (message_id IN (SELECT id FROM email_messages WHERE account_id IN (SELECT id FROM email_accounts WHERE user_id = auth.uid())));

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_email_accounts_updated_at BEFORE UPDATE ON email_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_folders_updated_at BEFORE UPDATE ON email_folders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_messages_updated_at BEFORE UPDATE ON email_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_attachments_updated_at BEFORE UPDATE ON email_attachments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_templates_updated_at BEFORE UPDATE ON email_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_rules_updated_at BEFORE UPDATE ON email_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_contacts_updated_at BEFORE UPDATE ON email_contacts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_conversations_updated_at BEFORE UPDATE ON email_conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_analytics_updated_at BEFORE UPDATE ON email_analytics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_tracking_updated_at BEFORE UPDATE ON email_tracking FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update search index
CREATE OR REPLACE FUNCTION update_email_search_index()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO email_search_index (message_id, search_vector, content_text)
  VALUES (
    NEW.id,
    to_tsvector('english', coalesce(NEW.subject, '') || ' ' || coalesce(NEW.body_text, '') || ' ' || coalesce(NEW.from_name, '') || ' ' || coalesce(NEW.from_email, '')),
    coalesce(NEW.subject, '') || ' ' || coalesce(NEW.body_text, '') || ' ' || coalesce(NEW.from_name, '') || ' ' || coalesce(NEW.from_email, '')
  )
  ON CONFLICT (message_id) DO UPDATE SET
    search_vector = EXCLUDED.search_vector,
    content_text = EXCLUDED.content_text,
    updated_at = now();
  
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_email_search_index_trigger
  AFTER INSERT OR UPDATE OF subject, body_text, from_name, from_email ON email_messages
  FOR EACH ROW EXECUTE FUNCTION update_email_search_index();

-- Function to update conversation stats
CREATE OR REPLACE FUNCTION update_conversation_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update conversation message count and dates
  INSERT INTO email_conversations (
    thread_id, account_id, subject, participants, message_count,
    first_message_date, last_message_date, last_activity_date
  )
  SELECT 
    NEW.thread_id,
    NEW.account_id,
    NEW.subject,
    ARRAY[NEW.from_email] || NEW.to_emails,
    1,
    NEW.date_received,
    NEW.date_received,
    NEW.date_received
  WHERE NEW.thread_id IS NOT NULL
  ON CONFLICT (thread_id, account_id) DO UPDATE SET
    message_count = email_conversations.message_count + 1,
    last_message_date = NEW.date_received,
    last_activity_date = NEW.date_received,
    participants = array(SELECT DISTINCT unnest(email_conversations.participants || ARRAY[NEW.from_email] || NEW.to_emails));
  
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conversation_stats_trigger
  AFTER INSERT ON email_messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_stats();
