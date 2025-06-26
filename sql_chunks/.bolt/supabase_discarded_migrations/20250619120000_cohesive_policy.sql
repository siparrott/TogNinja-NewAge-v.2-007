/*
  # Consolidate Admin User Policies

  Combines setup from 20250618131024_patient_darkness.sql and
  20250618132101_dry_peak.sql.
  - Ensures `admin_users` table exists
  - Inserts initial admin for matt@newagefotografie.com
  - Drops any existing policies on `admin_users`
  - Creates simplified policies:
      * Users can read own admin status
      * Service role can manage admin records
*/

-- Ensure table exists
CREATE TABLE IF NOT EXISTS admin_users (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  is_admin boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Index for quick admin lookups
CREATE INDEX IF NOT EXISTS idx_admin_users_is_admin
  ON admin_users(is_admin) WHERE is_admin = true;

-- Insert known admin if account exists
DO $$
DECLARE
  admin_user_id uuid;
BEGIN
  SELECT id INTO admin_user_id
  FROM auth.users
  WHERE email = 'matt@newagefotografie.com'
  LIMIT 1;
  IF admin_user_id IS NOT NULL THEN
    INSERT INTO admin_users (user_id, is_admin)
    VALUES (admin_user_id, true)
    ON CONFLICT (user_id)
    DO UPDATE SET is_admin = true;
  END IF;
END $$;

-- Drop any existing policies
DROP POLICY IF EXISTS "Admin users can manage admin data" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage all admin data" ON admin_users;
DROP POLICY IF EXISTS "Admins can delete admin records" ON admin_users;
DROP POLICY IF EXISTS "Admins can insert admin records" ON admin_users;
DROP POLICY IF EXISTS "Admins can read all admin records" ON admin_users;
DROP POLICY IF EXISTS "Admins can update admin records" ON admin_users;
DROP POLICY IF EXISTS "Admins can view all users" ON admin_users;
DROP POLICY IF EXISTS "Allow users to check their own admin status" ON admin_users;
DROP POLICY IF EXISTS "Public can check admin status" ON admin_users;
DROP POLICY IF EXISTS "Users can read own admin status" ON admin_users;
DROP POLICY IF EXISTS "Users can insert own admin record" ON admin_users;
DROP POLICY IF EXISTS "Users can view own user data" ON admin_users;
DROP POLICY IF EXISTS "Service role full access" ON admin_users;
DROP POLICY IF EXISTS "Users can read own admin record" ON admin_users;
DROP POLICY IF EXISTS "Users can update own admin record" ON admin_users;

-- Simplified policies
CREATE POLICY "Users can read own admin status"
  ON admin_users FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Service role can manage admin records"
  ON admin_users FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);
