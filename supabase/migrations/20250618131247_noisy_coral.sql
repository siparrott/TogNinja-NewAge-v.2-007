/*
  # Create Demo Admin User

  1. New Tables
    - No new tables created
  
  2. Changes
    - Insert demo admin user into admin_users table
    - This assumes the user already exists in auth.users with the specified email
  
  3. Security
    - Uses existing RLS policies on admin_users table
  
  4. Notes
    - The actual user account must be created in Supabase Auth separately
    - This migration only adds the admin privileges to the existing user
    - If the user doesn't exist in auth.users, this will fail due to foreign key constraint
*/

-- First, we need to handle the case where the demo user might not exist in auth.users
-- We'll use a DO block to conditionally insert the admin record

DO $$
DECLARE
    demo_user_id uuid;
BEGIN
    -- Try to find the demo user in auth.users
    SELECT id INTO demo_user_id 
    FROM auth.users 
    WHERE email = 'demo@example.com';
    
    -- If the user exists, ensure they have admin privileges
    IF demo_user_id IS NOT NULL THEN
        -- Insert or update the admin record
        INSERT INTO admin_users (user_id, is_admin, created_at)
        VALUES (demo_user_id, true, now())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            is_admin = true,
            created_at = COALESCE(admin_users.created_at, now());
            
        RAISE NOTICE 'Demo admin user privileges updated for user ID: %', demo_user_id;
    ELSE
        RAISE NOTICE 'Demo user (demo@example.com) not found in auth.users. Please create the user account first.';
    END IF;
END $$;