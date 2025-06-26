/*
  # Create admin user policy and demo account

  1. Security
    - Add policy for admin users to manage other admin users
    - Create a demo admin account for testing
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
  demo_user_id uuid;
BEGIN
  -- Create the user in auth.users
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
  RETURNING id INTO demo_user_id;

  -- Make them an admin
  INSERT INTO admin_users (user_id, is_admin)
  VALUES (demo_user_id, true);
END $$;