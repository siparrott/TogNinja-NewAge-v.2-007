/*
  # Fix admin authentication policies

  1. Changes
    - Add new RLS policy to allow users to check their own admin status
    - This fixes the circular dependency where users couldn't verify if they were admins
    
  2. Security
    - Policy only allows users to read their own admin status
    - Maintains existing admin management policies
*/

CREATE POLICY "Users can check their own admin status"
  ON admin_users
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());