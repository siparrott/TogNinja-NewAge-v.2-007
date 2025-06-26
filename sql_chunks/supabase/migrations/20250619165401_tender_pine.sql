/*
  # Fix infinite recursion in admin_users RLS policies

  1. Problem
    - The "Admin users can manage other admin users" policy creates infinite recursion
    - It queries the same table (admin_users) that the policy is applied to
    - This causes a circular dependency during policy evaluation

  2. Solution
    - Drop the problematic policy that causes recursion
    - Create a simpler policy structure that avoids self-referential queries
    - Use service_role for admin operations when needed
    - Keep basic user policies for self-management

  3. Security
    - Users can still read/update their own admin records
    - Service role maintains full access for admin operations
    - Remove the circular dependency while maintaining security
*/

-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "Admin users can manage other admin users" ON admin_users;

-- Keep the existing policies that work correctly:
-- - "Service role full access" (already exists)
-- - "Users can insert own admin record" (already exists) 
-- - "Users can read own admin record" (already exists)
-- - "Users can update own admin record" (already exists)

-- Add a comment to document the change
COMMENT ON TABLE admin_users IS 'Admin user management table. RLS policies updated to prevent infinite recursion. Admin operations should use service_role when needed.';