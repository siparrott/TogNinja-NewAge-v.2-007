/*
  # Create Admin User and Policy

  1. Changes
    - Add policy for admin users to manage other admin users
    - Create demo admin user if it doesn't exist
    
  2. Security
    - Ensures proper admin access control
    - Handles case where user already exists
*/

-- First create the admin management policy
CREATE POLICY "Admin users can manage other admin users"
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

-- Create a demo admin user
DO $$
DECLARE
  demo_user_id uuid := 'c9c90647-7e8e-4848-8f39-3b7551a6cd6f';
  user_exists boolean;
BEGIN
  -- Check if user already exists
  SELECT EXISTS (
    SELECT 1 FROM auth.users WHERE id = demo_user_id
  ) INTO user_exists;
  
  -- Create the user in auth.users only if they don't exist
  IF NOT user_exists THEN
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
      demo_user_id,
      'authenticated',
      'authenticated',
      'demo@example.com',
      crypt('demo123', gen_salt('bf')),
      NOW(),
      NOW(),
      NOW(),
      '',
      ''
    );
  END IF;

  -- Make them an admin (using ON CONFLICT to handle if they're already an admin)
  INSERT INTO admin_users (user_id, is_admin)
  VALUES (demo_user_id, true)
  ON CONFLICT (user_id) DO UPDATE SET is_admin = true;
END $$;