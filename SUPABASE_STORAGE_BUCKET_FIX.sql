-- SUPABASE STORAGE BUCKET AND RLS POLICIES FIX
-- This fixes the "Storage upload failed: new row violates row-level security policy" error

-- 1. First, ensure the 'digital-files' storage bucket exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'digital-files',
  'digital-files', 
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf', 'text/plain', 'application/json']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Create RLS policy for authenticated users to upload files
CREATE POLICY "Allow authenticated uploads to digital-files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'digital-files');

-- 3. Create RLS policy for public read access
CREATE POLICY "Allow public read access to digital-files"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'digital-files');

-- 4. Create RLS policy for authenticated users to update their files
CREATE POLICY "Allow authenticated updates to digital-files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'digital-files')
WITH CHECK (bucket_id = 'digital-files');

-- 5. Create RLS policy for authenticated users to delete their files
CREATE POLICY "Allow authenticated deletes from digital-files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'digital-files');

-- 6. Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 7. Verify the bucket was created
SELECT * FROM storage.buckets WHERE id = 'digital-files';
