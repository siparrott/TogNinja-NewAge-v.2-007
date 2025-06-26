/*
  # Fix admin login policies

  1. Changes
    - Modify RLS policies for admin_users table to allow initial admin status check during login
    
  2. Security
    - Updates policies to allow authenticated users to check their admin status
    - Maintains strict control over admin data management
*/

-- Drop existing policies to recreate them with correct permissions
DROP POLICY IF EXISTS "Allow admin status check" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage admin data" ON admin_users;

-- Create new policies with correct permissions
CREATE POLICY "Allow admin status check"
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
    SELECT 1
    FROM admin_users admin_users_1
    WHERE admin_users_1.user_id = auth.uid()
    AND admin_users_1.is_admin = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM admin_users admin_users_1
    WHERE admin_users_1.user_id = auth.uid()
    AND admin_users_1.is_admin = true
  )
);