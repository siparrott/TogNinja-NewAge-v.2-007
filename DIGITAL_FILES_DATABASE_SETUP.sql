-- DIGITAL FILES SYSTEM SETUP
-- Run this in your Supabase SQL Editor to fix file upload functionality

-- 1. CREATE DIGITAL FILES TABLE
CREATE TABLE IF NOT EXISTS public.digital_files (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    filename TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type TEXT NOT NULL,
    file_path TEXT NOT NULL,
    client_id UUID,
    client_name TEXT,
    booking_id UUID,
    category TEXT DEFAULT 'other',
    is_public BOOLEAN DEFAULT false,
    uploaded_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Professional metadata
    width INTEGER,
    height INTEGER,
    camera_make TEXT,
    camera_model TEXT,
    iso INTEGER,
    aperture TEXT,
    shutter_speed TEXT,
    focal_length TEXT,
    gps_latitude DECIMAL,
    gps_longitude DECIMAL,
    
    -- Organization
    tags TEXT[],
    description TEXT,
    alt_text TEXT,
    is_favorite BOOLEAN DEFAULT false,
    is_processed BOOLEAN DEFAULT false,
    processing_status TEXT DEFAULT 'pending',
    
    -- Access control
    access_level TEXT DEFAULT 'private' CHECK (access_level IN ('private', 'client', 'public')),
    download_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE
);

-- 2. CREATE INDEXES
CREATE INDEX IF NOT EXISTS idx_digital_files_uploaded_by ON public.digital_files(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_digital_files_client_id ON public.digital_files(client_id);
CREATE INDEX IF NOT EXISTS idx_digital_files_category ON public.digital_files(category);
CREATE INDEX IF NOT EXISTS idx_digital_files_mime_type ON public.digital_files(mime_type);
CREATE INDEX IF NOT EXISTS idx_digital_files_created_at ON public.digital_files(created_at);
CREATE INDEX IF NOT EXISTS idx_digital_files_is_public ON public.digital_files(is_public);
CREATE INDEX IF NOT EXISTS idx_digital_files_tags ON public.digital_files USING gin(tags);

-- 3. ENABLE RLS
ALTER TABLE public.digital_files ENABLE ROW LEVEL SECURITY;

-- 4. CREATE RLS POLICIES
DROP POLICY IF EXISTS "Users can view their own files" ON public.digital_files;
CREATE POLICY "Users can view their own files" ON public.digital_files
    FOR SELECT USING (uploaded_by = auth.uid() OR is_public = true);

DROP POLICY IF EXISTS "Users can upload files" ON public.digital_files;
CREATE POLICY "Users can upload files" ON public.digital_files
    FOR INSERT WITH CHECK (uploaded_by = auth.uid());

DROP POLICY IF EXISTS "Users can update their own files" ON public.digital_files;
CREATE POLICY "Users can update their own files" ON public.digital_files
    FOR UPDATE USING (uploaded_by = auth.uid());

DROP POLICY IF EXISTS "Users can delete their own files" ON public.digital_files;
CREATE POLICY "Users can delete their own files" ON public.digital_files
    FOR DELETE USING (uploaded_by = auth.uid());

-- 5. CREATE FILE CATEGORIES FUNCTION
CREATE OR REPLACE FUNCTION get_file_category(mime_type TEXT)
RETURNS TEXT AS $$
BEGIN
    CASE
        WHEN mime_type LIKE 'image/%' THEN RETURN 'image';
        WHEN mime_type LIKE 'video/%' THEN RETURN 'video';
        WHEN mime_type LIKE 'audio/%' THEN RETURN 'audio';
        WHEN mime_type IN ('application/pdf') THEN RETURN 'document';
        WHEN mime_type LIKE 'text/%' THEN RETURN 'document';
        WHEN mime_type LIKE 'application/vnd.openxmlformats%' THEN RETURN 'document';
        WHEN mime_type LIKE 'application/msword%' THEN RETURN 'document';
        WHEN mime_type LIKE 'application/zip%' OR mime_type LIKE 'application/x-rar%' THEN RETURN 'archive';
        ELSE RETURN 'other';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- 6. CREATE STORAGE BUCKET SETUP INSTRUCTIONS
-- Note: You need to create the storage bucket manually in Supabase Dashboard
-- Go to Storage → Create Bucket → Name: "digital-files"
-- Set it as Public if you want direct access to files

-- 7. CREATE FILE SHARING TABLE
CREATE TABLE IF NOT EXISTS public.file_shares (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    file_id UUID REFERENCES public.digital_files(id) ON DELETE CASCADE,
    share_token TEXT UNIQUE NOT NULL DEFAULT gen_random_uuid()::TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    password_hash TEXT,
    download_limit INTEGER,
    download_count INTEGER DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- 8. ENABLE RLS FOR FILE SHARES
ALTER TABLE public.file_shares ENABLE ROW LEVEL SECURITY;

-- 9. CREATE RLS POLICY FOR FILE SHARES
CREATE POLICY "Users can manage their file shares" ON public.file_shares
    FOR ALL USING (created_by = auth.uid());

-- 10. CREATE SAMPLE FILE CATEGORIES DATA
INSERT INTO public.digital_files (
    filename, 
    original_filename, 
    file_size, 
    mime_type, 
    file_path, 
    category, 
    is_public, 
    uploaded_by,
    description
) VALUES 
(
    'sample-logo.jpg',
    'company-logo.jpg',
    52000,
    'image/jpeg',
    'sample-logo.jpg',
    'image',
    true,
    auth.uid(),
    'Company logo file'
)
ON CONFLICT DO NOTHING;

-- 11. VERIFY SETUP
SELECT 'digital_files' as table_name, count(*) as row_count FROM public.digital_files
UNION ALL
SELECT 'file_shares' as table_name, count(*) as row_count FROM public.file_shares;
