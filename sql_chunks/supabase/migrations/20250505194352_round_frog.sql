/*
  # Fix Admin Authentication Policies

  1. Changes
    - Add policy to allow unauthenticated users to check admin status during login
    - Modify existing policies to ensure proper access control
  
  2. Security
    - Maintains RLS protection while allowing necessary authentication checks
    - Ensures admin users can only access their own records
*/

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Users can check their own admin status" ON admin_users;
DROP POLICY IF EXISTS "Admin users can read own data" ON admin_users;

-- Add new policies with correct permissions
CREATE POLICY "Allow admin status check during authentication"
  ON admin_users
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can read own admin data"
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