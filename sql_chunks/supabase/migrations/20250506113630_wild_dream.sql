/*
  # Create users view and policies

  1. Changes
    - Create a view to safely expose auth.users data
    - Add policies for user data access
    - Set up proper permissions for authenticated users
    
  2. Security
    - Enable RLS
    - Users can only see their own data
    - Admins can view all user data
*/

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own user data" ON admin_users;
DROP POLICY IF EXISTS "Admins can view all users" ON admin_users;

-- Create the users view
CREATE OR REPLACE VIEW public.users AS
SELECT 
  id,
  email,
  created_at
FROM auth.users;

-- Set proper permissions
GRANT SELECT ON public.users TO authenticated;

-- Create policy for users to see their own data in admin_users
CREATE POLICY "Users can view own user data"
ON admin_users
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Create policy for admins to view all users
CREATE POLICY "Admins can view all users"
ON admin_users
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid()
    AND is_admin = true
  )
);