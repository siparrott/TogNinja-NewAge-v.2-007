/*
  # Fix admin authentication policies

  1. Security
    - Drop existing policies to avoid conflicts
    - Add new policies with correct permissions for admin authentication
    - Ensure public can check admin status during auth
    - Allow authenticated users to read their own admin data
*/

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Users can check their own admin status" ON admin_users;
DROP POLICY IF EXISTS "Admin users can read own data" ON admin_users;
DROP POLICY IF EXISTS "Allow admin status check during authentication" ON admin_users;
DROP POLICY IF EXISTS "Users can read own admin data" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage admin data" ON admin_users;

-- Create new policies with correct permissions
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