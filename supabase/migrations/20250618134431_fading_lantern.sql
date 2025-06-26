/*
  # Create admin user for authentication

  1. New Tables
    - Ensures admin_users table exists with proper structure
  2. Security
    - Enable RLS on admin_users table
    - Add policies for admin user management
  3. Data
    - Insert demo admin user for testing
*/

-- Create admin_users table if it doesn't exist
CREATE TABLE IF NOT EXISTS admin_users (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  is_admin boolean DEFAULT false NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Service role full access" ON admin_users;
DROP POLICY IF EXISTS "Users can insert own admin record" ON admin_users;
DROP POLICY IF EXISTS "Users can read own admin record" ON admin_users;
DROP POLICY IF EXISTS "Users can update own admin record" ON admin_users;

-- Create policies
CREATE POLICY "Service role full access" ON admin_users
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can insert own admin record" ON admin_users
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can read own admin record" ON admin_users
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own admin record" ON admin_users
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_admin_users_is_admin ON admin_users (is_admin) WHERE is_admin = true;

-- Insert demo admin user if it doesn't exist
DO $$
DECLARE
  demo_user_id uuid;
BEGIN
  -- First, try to create the demo user in auth.users if it doesn't exist
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'c9c90647-7e8e-4848-8f39-3b755a6cd6f',
    'authenticated',
    'authenticated',
    'demo@example.com',
    crypt('demo123', gen_salt('bf')),
    now(),
    null,
    null,
    '{"provider": "email", "providers": ["email"]}',
    '{}',
    now(),
    now(),
    '',
    '',
    '',
    ''
  ) ON CONFLICT (id) DO NOTHING;

  -- Now insert into admin_users
  INSERT INTO admin_users (user_id, is_admin)
  VALUES ('c9c90647-7e8e-4848-8f39-3b755a6cd6f', true)
  ON CONFLICT (user_id) DO UPDATE SET is_admin = true;
  
  RAISE NOTICE 'Demo admin user created/updated successfully';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error creating demo user: %', SQLERRM;
END $$;