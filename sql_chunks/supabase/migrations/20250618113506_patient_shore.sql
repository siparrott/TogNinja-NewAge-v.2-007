/*
  # Admin CRM Tables

  1. New Tables
    - `crm_leads`: Lead management
    - `crm_clients`: Client management  
    - `crm_bookings`: Booking management
    - `crm_invoices`: Invoice management
    - `crm_campaigns`: Email campaign management
    - `crm_messages`: Inbox messages
    - `crm_questionnaires`: Questionnaire templates
    - `crm_responses`: Questionnaire responses
    - `crm_files`: Digital file management
    - `crm_settings`: System settings

  2. Security
    - Enable RLS on all tables
    - Add policies for admin access only
*/

-- CRM Leads Table
CREATE TABLE IF NOT EXISTS crm_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  service text NOT NULL,
  status text DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'qualified', 'converted')),
  source text,
  notes text,
  assigned_to uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- CRM Clients Table
CREATE TABLE IF NOT EXISTS crm_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  address text,
  company text,
  notes text,
  status text DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
  lead_id uuid REFERENCES crm_leads(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- CRM Bookings Table
CREATE TABLE IF NOT EXISTS crm_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES crm_clients(id) NOT NULL,
  service_type text NOT NULL,
  booking_date timestamptz NOT NULL,
  duration_minutes integer DEFAULT 60,
  location text,
  status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'completed', 'cancelled')),
  notes text,
  price decimal(10,2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- CRM Invoices Table
CREATE TABLE IF NOT EXISTS crm_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number text UNIQUE NOT NULL,
  client_id uuid REFERENCES crm_clients(id) NOT NULL,
  booking_id uuid REFERENCES crm_bookings(id),
  amount decimal(10,2) NOT NULL,
  tax_amount decimal(10,2) DEFAULT 0,
  total_amount decimal(10,2) NOT NULL,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
  due_date date,
  paid_date date,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- CRM Email Campaigns Table
CREATE TABLE IF NOT EXISTS crm_campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  subject text NOT NULL,
  content text NOT NULL,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sent', 'cancelled')),
  scheduled_at timestamptz,
  sent_at timestamptz,
  recipient_count integer DEFAULT 0,
  open_count integer DEFAULT 0,
  click_count integer DEFAULT 0,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- CRM Messages Table
CREATE TABLE IF NOT EXISTS crm_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_name text NOT NULL,
  sender_email text NOT NULL,
  subject text NOT NULL,
  content text NOT NULL,
  status text DEFAULT 'unread' CHECK (status IN ('unread', 'read', 'replied', 'archived')),
  client_id uuid REFERENCES crm_clients(id),
  assigned_to uuid REFERENCES auth.users(id),
  replied_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- CRM Questionnaires Table
CREATE TABLE IF NOT EXISTS crm_questionnaires (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  questions jsonb NOT NULL,
  status text DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- CRM Questionnaire Responses Table
CREATE TABLE IF NOT EXISTS crm_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  questionnaire_id uuid REFERENCES crm_questionnaires(id) NOT NULL,
  client_id uuid REFERENCES crm_clients(id),
  respondent_name text,
  respondent_email text,
  responses jsonb NOT NULL,
  submitted_at timestamptz DEFAULT now()
);

-- CRM Digital Files Table
CREATE TABLE IF NOT EXISTS crm_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  filename text NOT NULL,
  original_filename text NOT NULL,
  file_size bigint NOT NULL,
  mime_type text NOT NULL,
  file_path text NOT NULL,
  client_id uuid REFERENCES crm_clients(id),
  booking_id uuid REFERENCES crm_bookings(id),
  category text DEFAULT 'general',
  is_public boolean DEFAULT false,
  uploaded_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- CRM Settings Table
CREATE TABLE IF NOT EXISTS crm_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key text UNIQUE NOT NULL,
  setting_value jsonb NOT NULL,
  description text,
  updated_by uuid REFERENCES auth.users(id),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on all CRM tables
ALTER TABLE crm_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_questionnaires ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_settings ENABLE ROW LEVEL SECURITY;

-- Create admin-only policies for all CRM tables
CREATE POLICY "Admin users can manage leads"
  ON crm_leads FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage clients"
  ON crm_clients FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage bookings"
  ON crm_bookings FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage invoices"
  ON crm_invoices FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage campaigns"
  ON crm_campaigns FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage messages"
  ON crm_messages FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage questionnaires"
  ON crm_questionnaires FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage responses"
  ON crm_responses FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage files"
  ON crm_files FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage settings"
  ON crm_settings FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

-- Insert default settings
INSERT INTO crm_settings (setting_key, setting_value, description) VALUES
('company_name', '"New Age Fotografie"', 'Company name for invoices and emails'),
('company_address', '"Musterstraße 123, 1010 Wien, Austria"', 'Company address'),
('company_email', '"info@newagefotografie.com"', 'Company contact email'),
('company_phone', '"+43 123 456 789"', 'Company phone number'),
('invoice_prefix', '"INV"', 'Invoice number prefix'),
('tax_rate', '0.20', 'Default tax rate (20%)'),
('currency', '"EUR"', 'Default currency'),
('smtp_host', '""', 'SMTP server host'),
('smtp_port', '587', 'SMTP server port'),
('smtp_username', '""', 'SMTP username'),
('smtp_password', '""', 'SMTP password (encrypted)')
ON CONFLICT (setting_key) DO NOTHING;