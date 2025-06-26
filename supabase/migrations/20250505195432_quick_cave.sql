/*
  # Fix admin login policies

  1. Changes
    - Update RLS policies for admin_users table to allow proper authentication flow
    - Add policy for authenticated users to read their own admin status
    - Remove redundant policies

  2. Security
    - Maintain RLS enabled
    - Ensure proper access control for admin verification
*/

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Allow admin status check during authentication" ON admin_users;
DROP POLICY IF EXISTS "Users can read own admin data" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage admin data" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage other admin users" ON admin_users;

-- Create new, more specific policies
CREATE POLICY "Enable admin status check during authentication"
ON admin_users
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
);

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