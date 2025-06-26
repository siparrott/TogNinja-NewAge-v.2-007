/*
  # Fix infinite recursion in admin_users RLS policies

  1. Problem
    - Current RLS policies on admin_users table are causing infinite recursion
    - When checking admin status, the policy tries to check admin status again
    - This creates a circular dependency

  2. Solution
    - Drop existing problematic policies
    - Create new policies that don't create circular dependencies
    - Use direct auth.uid() checks instead of complex admin status checks
    - Ensure service role can manage all records without restrictions

  3. New Policies
    - Allow users to read their own admin record using direct user_id match
    - Allow users to insert their own admin record
    - Allow service role full access for admin management
*/

-- Drop existing policies that cause recursion
DROP POLICY IF EXISTS "Users can read own admin status" ON admin_users;
DROP POLICY IF EXISTS "Users can insert own admin record" ON admin_users;
DROP POLICY IF EXISTS "Service role can manage admin records" ON admin_users;

-- Create new policies without recursion
CREATE POLICY "Users can read own admin record"
  ON admin_users
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own admin record"
  ON admin_users
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Service role full access"
  ON admin_users
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Allow authenticated users to update their own record (in case needed)
CREATE POLICY "Users can update own admin record"
  ON admin_users
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());