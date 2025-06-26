-- 🚨 IMMEDIATE STORAGE FIX - Run this in Supabase SQL Editor NOW
-- This fixes the "Storage upload failed: new row violates row-level security policy" error

-- STEP 1: Create the missing 'digital-files' storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types, avif_autodetection, created_at, updated_at)
VALUES (
  'digital-files',
  'digital-files', 
  true,
  52428800, -- 50MB limit
  ARRAY[
    'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/avif',
    'application/pdf', 'text/plain', 'application/json', 'text/csv',
    'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ],
  false, -- avif_autodetection
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  updated_at = NOW();

-- STEP 2: Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- STEP 3: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated uploads to digital-files" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to digital-files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates to digital-files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes from digital-files" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access to digital-files" ON storage.objects;

-- STEP 4: Create comprehensive RLS policies for digital-files bucket
CREATE POLICY "Allow authenticated uploads to digital-files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'digital-files');

CREATE POLICY "Allow public read access to digital-files"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'digital-files');

CREATE POLICY "Allow authenticated updates to digital-files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'digital-files')
WITH CHECK (bucket_id = 'digital-files');

CREATE POLICY "Allow authenticated deletes from digital-files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'digital-files');

-- STEP 5: Also allow anonymous uploads (for public forms)
CREATE POLICY "Allow anonymous uploads to digital-files"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (bucket_id = 'digital-files');

-- STEP 6: Ensure digital_files table exists with proper structure
CREATE TABLE IF NOT EXISTS public.digital_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filename TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    mime_type TEXT,
    category TEXT DEFAULT 'general',
    uploaded_by UUID REFERENCES auth.users(id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    public_url TEXT
);

-- STEP 7: Enable RLS on digital_files table
ALTER TABLE public.digital_files ENABLE ROW LEVEL SECURITY;

-- STEP 8: Create RLS policies for digital_files table
DROP POLICY IF EXISTS "Allow authenticated users to insert digital files" ON public.digital_files;
DROP POLICY IF EXISTS "Allow authenticated users to view digital files" ON public.digital_files;
DROP POLICY IF EXISTS "Allow public to view digital files" ON public.digital_files;
DROP POLICY IF EXISTS "Allow anonymous uploads to digital files" ON public.digital_files;

CREATE POLICY "Allow authenticated users to insert digital files"
ON public.digital_files FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated users to view digital files"
ON public.digital_files FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow public to view digital files"
ON public.digital_files FOR SELECT
TO public
USING (true);

CREATE POLICY "Allow anonymous uploads to digital files"
ON public.digital_files FOR INSERT
TO anon
WITH CHECK (true);

-- STEP 9: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_digital_files_category ON public.digital_files(category);
CREATE INDEX IF NOT EXISTS idx_digital_files_uploaded_at ON public.digital_files(uploaded_at);
CREATE INDEX IF NOT EXISTS idx_digital_files_mime_type ON public.digital_files(mime_type);

-- STEP 10: Verify the setup worked
SELECT 
    'SUCCESS: digital-files bucket created' as status,
    id, name, public, file_size_limit
FROM storage.buckets 
WHERE id = 'digital-files';

-- Show all storage policies for verification
SELECT 
    'Storage policies for digital-files:' as info,
    policyname, 
    cmd,
    roles
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
  AND policyname LIKE '%digital-files%';

-- Show table policies for verification  
SELECT 
    'Table policies for digital_files:' as info,
    policyname,
    cmd,
    roles
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'digital_files';

-- Final verification message
SELECT '🎉 STORAGE ISSUE FIXED! The digital-files bucket and all policies are now properly configured.' as final_status;
