/*
  # Create admin_users table with proper structure

  1. New Tables
    - `admin_users`
      - `user_id` (uuid, primary key)
      - `is_admin` (boolean, default false)
      - `created_at` (timestamp)
  
  2. Security
    - Enable RLS on `admin_users` table
    - Add policies for admin management and user access
  
  3. Indexes
    - Add index for efficient admin lookups
*/

-- Create admin_users table
CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id uuid PRIMARY KEY,
  is_admin boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Add foreign key constraint to auth.users
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'admin_users_user_id_fkey'
    AND table_name = 'admin_users'
  ) THEN
    ALTER TABLE public.admin_users 
    ADD CONSTRAINT admin_users_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Create index for efficient admin lookups
CREATE INDEX IF NOT EXISTS idx_admin_users_is_admin 
ON public.admin_users USING btree (is_admin) 
WHERE (is_admin = true);

-- Enable Row Level Security
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own admin status" ON public.admin_users;
DROP POLICY IF EXISTS "Admins can read all admin records" ON public.admin_users;
DROP POLICY IF EXISTS "Admins can insert admin records" ON public.admin_users;
DROP POLICY IF EXISTS "Admins can update admin records" ON public.admin_users;
DROP POLICY IF EXISTS "Admins can delete admin records" ON public.admin_users;

-- Policy: Users can read their own admin status
CREATE POLICY "Users can read own admin status"
ON public.admin_users
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Admins can read all admin records
CREATE POLICY "Admins can read all admin records"
ON public.admin_users
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.admin_users admin_users_1
    WHERE admin_users_1.user_id = auth.uid() 
    AND admin_users_1.is_admin = true
  )
);

-- Policy: Admins can insert admin records
CREATE POLICY "Admins can insert admin records"
ON public.admin_users
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.admin_users admin_users_1
    WHERE admin_users_1.user_id = auth.uid() 
    AND admin_users_1.is_admin = true
  )
);

-- Policy: Admins can update admin records
CREATE POLICY "Admins can update admin records"
ON public.admin_users
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.admin_users admin_users_1
    WHERE admin_users_1.user_id = auth.uid() 
    AND admin_users_1.is_admin = true
  )
);

-- Policy: Admins can delete admin records (but not themselves)
CREATE POLICY "Admins can delete admin records"
ON public.admin_users
FOR DELETE
TO authenticated
USING (
  user_id <> auth.uid() 
  AND EXISTS (
    SELECT 1 FROM public.admin_users admin_users_1
    WHERE admin_users_1.user_id = auth.uid() 
    AND admin_users_1.is_admin = true
  )
);