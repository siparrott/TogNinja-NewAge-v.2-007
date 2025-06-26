/*
  # Create demo admin user if not exists
  
  1. Changes
    - Creates demo user with email 'demo@example.com' if it doesn't exist
    - Makes the user an admin by adding to admin_users table
    - Handles case where user already exists
*/

DO $$ 
BEGIN
  -- Only create user if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM auth.users WHERE email = 'demo@example.com'
  ) THEN
    INSERT INTO auth.users (
      id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      role
    ) VALUES (
      gen_random_uuid(),
      'demo@example.com',
      crypt('demo123', gen_salt('bf')),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      false,
      'authenticated'
    );
  END IF;

  -- Make the user an admin if they aren't already
  IF NOT EXISTS (
    SELECT 1 
    FROM admin_users a
    JOIN auth.users u ON u.id = a.user_id
    WHERE u.email = 'demo@example.com' AND a.is_admin = true
  ) THEN
    INSERT INTO admin_users (user_id, is_admin)
    SELECT id, true
    FROM auth.users
    WHERE email = 'demo@example.com';
  END IF;
END $$;