/*
  # Fix admin users table and policies

  1. Changes
    - Drop existing policies
    - Add unique constraint on user_id
    - Recreate policies for admin management
    - Create demo admin user
    
  2. Security
    - Maintain RLS protection
    - Ensure proper admin access control
*/

-- Drop existing policies first
DROP POLICY IF EXISTS "Allow users to check their own admin status" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage admin data" ON admin_users;
DROP POLICY IF EXISTS "Public can check admin status" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage all admin data" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage all posts" ON blog_posts;

-- Add unique constraint on user_id
ALTER TABLE admin_users 
  DROP CONSTRAINT IF EXISTS admin_users_user_id_key,
  DROP CONSTRAINT IF EXISTS admin_users_user_id_fkey,
  ALTER COLUMN user_id SET DATA TYPE uuid,
  ADD CONSTRAINT admin_users_user_id_key UNIQUE (user_id),
  ADD CONSTRAINT admin_users_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id);

-- Recreate policies
CREATE POLICY "Public can check admin status"
  ON admin_users
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Admin users can manage all admin data"
  ON admin_users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid()
      AND is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid()
      AND is_admin = true
    )
  );

-- Recreate blog posts policy
CREATE POLICY "Admin users can manage all posts"
  ON blog_posts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid()
      AND is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid()
      AND is_admin = true
    )
  );

-- Create demo admin user if it doesn't exist
DO $$ 
DECLARE
  demo_user_id uuid;
BEGIN
  -- Insert demo user if not exists
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
    recovery_token
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    'c9c90647-7e8e-4848-8f39-3b7551a6cd6f',
    'authenticated',
    'authenticated',
    'demo@example.com',
    crypt('demo123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    ''
  )
  ON CONFLICT (id) DO NOTHING
  RETURNING id INTO demo_user_id;

  -- If we didn't get an id from the insert, get it from the existing user
  IF demo_user_id IS NULL THEN
    SELECT id INTO demo_user_id FROM auth.users WHERE email = 'demo@example.com';
  END IF;

  -- Make them an admin
  INSERT INTO admin_users (user_id, is_admin)
  VALUES (demo_user_id, true)
  ON CONFLICT ON CONSTRAINT admin_users_user_id_key 
  DO UPDATE SET is_admin = true;
END $$;