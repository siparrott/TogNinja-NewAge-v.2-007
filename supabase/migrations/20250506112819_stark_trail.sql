/*
  # Fix admin users policies

  1. Changes
    - Add policy for admin users to read their own admin status
    - Add policy for admin users to manage other admin users
    - Ensure proper RLS policies for admin authentication

  2. Security
    - Enable RLS on admin_users table (already enabled)
    - Update policies to allow proper admin authentication flow
*/

-- Drop existing policies to recreate them with correct permissions
DROP POLICY IF EXISTS "Admin users can manage admin data" ON admin_users;
DROP POLICY IF EXISTS "Allow admin status check" ON admin_users;

-- Create new policies with correct permissions
CREATE POLICY "Allow users to check their own admin status"
ON admin_users
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Admin users can manage admin data"
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