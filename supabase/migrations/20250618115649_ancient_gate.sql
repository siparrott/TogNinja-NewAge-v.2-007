/*
  # Fix admin authentication system

  1. Changes
    - Recreate admin_users table with proper constraints
    - Fix RLS policies for admin authentication
    - Create demo admin user with proper credentials
    
  2. Security
    - Ensure RLS is properly configured
    - Allow admin status verification during login
*/

-- Drop existing policies and constraints that might be causing issues
DROP POLICY IF EXISTS "Public can check admin status" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage all admin data" ON admin_users;
DROP POLICY IF EXISTS "Users can view own user data" ON admin_users;
DROP POLICY IF EXISTS "Admins can view all users" ON admin_users;

-- Ensure the table exists with correct structure
CREATE TABLE IF NOT EXISTS admin_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  is_admin boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Add unique constraint if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'admin_users_user_id_key' 
    AND table_name = 'admin_users'
  ) THEN
    ALTER TABLE admin_users ADD CONSTRAINT admin_users_user_id_key UNIQUE (user_id);
  END IF;
END $$;

-- Add foreign key constraint if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'admin_users_user_id_fkey' 
    AND table_name = 'admin_users'
  ) THEN
    ALTER TABLE admin_users ADD CONSTRAINT admin_users_user_id_fkey 
      FOREIGN KEY (user_id) REFERENCES auth.users(id);
  END IF;
END $$;

-- Enable RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Create new policies with proper permissions
CREATE POLICY "Public can check admin status"
  ON admin_users
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can view own user data"
  ON admin_users
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all users"
  ON admin_users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid()
      AND is_admin = true
    )
  );

CREATE POLICY "Admin users can manage all admin data"
  ON admin_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users admin_users_1
      WHERE admin_users_1.user_id = auth.uid()
      AND admin_users_1.is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users admin_users_1
      WHERE admin_users_1.user_id = auth.uid()
      AND admin_users_1.is_admin = true
    )
  );

-- Create or update demo admin user
DO $$ 
DECLARE
  demo_user_id uuid := 'c9c90647-7e8e-4848-8f39-3b7551a6cd6f';
BEGIN
  -- Insert or update the demo user in auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    demo_user_id,
    'authenticated',
    'authenticated',
    'demo@example.com',
    crypt('demo123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '{"provider":"email","providers":["email"]}',
    '{}',
    false
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    updated_at = NOW();

  -- Make them an admin
  INSERT INTO admin_users (user_id, is_admin)
  VALUES (demo_user_id, true)
  ON CONFLICT (user_id) DO UPDATE SET
    is_admin = true;
    
  RAISE NOTICE 'Demo admin user created/updated: demo@example.com / demo123';
END $$;