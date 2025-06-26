-- Drop existing policies
DROP POLICY IF EXISTS "Enable admin status check during authentication" ON admin_users;
DROP POLICY IF EXISTS "Admin users can manage all admin data" ON admin_users;

-- Create new policies with proper permissions
CREATE POLICY "Allow admin status check"
ON admin_users
FOR SELECT
TO authenticated
USING (true);

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