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

-- Create demo admin user
DO $$
DECLARE
  demo_user_id uuid := 'c9c90647-7e8e-4848-8f39-3b7551a6cd6f';
BEGIN
  -- Insert demo user into auth.users if not exists
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    demo_user_id,
    'authenticated',
    'authenticated',
    'demo@example.com',
    crypt('demo123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '{"provider":"email","providers":["email"]}',
    '{}',
    false
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    updated_at = NOW();

  -- Add demo user to admin_users table
  INSERT INTO public.admin_users (user_id, is_admin)
  VALUES (demo_user_id, true)
  ON CONFLICT (user_id) DO UPDATE SET
    is_admin = true;
    
  RAISE NOTICE 'Demo admin user created: demo@example.com / demo123';
END $$;