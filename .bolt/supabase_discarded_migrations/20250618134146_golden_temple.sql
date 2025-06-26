-- This migration fixes admin user setup issues by ensuring proper admin records exist
-- and fixing any potential policy issues

-- First, ensure the admin_users table exists
CREATE TABLE IF NOT EXISTS admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  is_admin BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS if not already enabled
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies to avoid conflicts
DO $$ 
BEGIN
  -- Drop all policies on admin_users table
  EXECUTE (
    SELECT string_agg('DROP POLICY IF EXISTS "' || polname || '" ON admin_users;', ' ')
    FROM pg_policies 
    WHERE tablename = 'admin_users'
  );
EXCEPTION
  WHEN OTHERS THEN NULL; -- Ignore errors
END $$;

-- Create simplified policies that don't cause recursion
CREATE POLICY "Service role full access"
  ON admin_users FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can read own admin record"
  ON admin_users FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own admin record"
  ON admin_users FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own admin record"
  ON admin_users FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Setup admin users based on existing accounts
DO $$
DECLARE
    matt_user_id uuid;
BEGIN
    -- Find matt user (from screenshot)
    SELECT id INTO matt_user_id 
    FROM auth.users 
    WHERE email = 'matt@newagefotografie.com';
    
    -- Setup matt user as admin if exists
    IF matt_user_id IS NOT NULL THEN
        INSERT INTO admin_users (user_id, is_admin, created_at)
        VALUES (matt_user_id, true, now())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            is_admin = true,
            created_at = COALESCE(admin_users.created_at, now());
            
        RAISE NOTICE 'Admin user setup completed for: matt@newagefotografie.com';
    ELSE
        RAISE NOTICE 'User matt@newagefotografie.com not found.';
    END IF;
    
    -- Also set up any user with email containing 'demo@example.com'
    INSERT INTO admin_users (user_id, is_admin)
    SELECT id, true
    FROM auth.users
    WHERE email LIKE '%demo@example.com%'
    ON CONFLICT (user_id) DO UPDATE SET is_admin = true;
END $$;

-- Create a function to check admin status without recursion
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM admin_users 
    WHERE admin_users.user_id = $1 
    AND admin_users.is_admin = true
  );
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION is_admin(uuid) TO authenticated;