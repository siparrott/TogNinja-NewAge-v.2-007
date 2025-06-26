/*
  # Create admin_users table

  1. New Tables
    - `admin_users`
      - `user_id` (uuid, primary key, references auth.users)
      - `is_admin` (boolean, default false)
      - `created_at` (timestamp with timezone, default now())

  2. Security
    - Enable RLS on `admin_users` table
    - Add policy for users to read their own admin status
    - Add policy for admins to manage admin users

  3. Notes
    - This table tracks which users have admin privileges
    - Links to Supabase auth.users table via foreign key
    - Essential for role-based access control in the application
*/

-- Create the admin_users table
CREATE TABLE IF NOT EXISTS public.admin_users (
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    is_admin boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

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
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid() AND is_admin = true
        )
    );

-- Policy: Admins can insert new admin records
CREATE POLICY "Admins can insert admin records"
    ON public.admin_users
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid() AND is_admin = true
        )
    );

-- Policy: Admins can update admin records
CREATE POLICY "Admins can update admin records"
    ON public.admin_users
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid() AND is_admin = true
        )
    );

-- Policy: Admins can delete admin records (except their own)
CREATE POLICY "Admins can delete admin records"
    ON public.admin_users
    FOR DELETE
    TO authenticated
    USING (
        user_id != auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid() AND is_admin = true
        )
    );

-- Create an index for better performance on admin lookups
CREATE INDEX IF NOT EXISTS idx_admin_users_is_admin ON public.admin_users(is_admin) WHERE is_admin = true;