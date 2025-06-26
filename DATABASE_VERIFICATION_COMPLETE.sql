-- COMPREHENSIVE DATABASE VERIFICATION AND SETUP
-- Run this to ensure all required tables, buckets, and policies exist

-- 1. Verify and create digital_files table
CREATE TABLE IF NOT EXISTS digital_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filename TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    mime_type TEXT,
    category TEXT DEFAULT 'general',
    uploaded_by UUID REFERENCES auth.users(id),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 2. Enable RLS on digital_files table
ALTER TABLE digital_files ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS policies for digital_files table
DROP POLICY IF EXISTS "Allow authenticated users to insert digital files" ON digital_files;
CREATE POLICY "Allow authenticated users to insert digital files"
ON digital_files FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated users to view digital files" ON digital_files;
CREATE POLICY "Allow authenticated users to view digital files"
ON digital_files FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow public to view digital files" ON digital_files;
CREATE POLICY "Allow public to view digital files"
ON digital_files FOR SELECT
TO public
USING (true);

-- 4. Verify other essential tables exist
CREATE TABLE IF NOT EXISTS survey_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    business_name TEXT,
    business_type TEXT,
    current_challenges TEXT,
    goals TEXT,
    budget_range TEXT,
    timeline TEXT,
    additional_info TEXT,
    newsletter_signup BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS newsletter_subscribers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'active',
    preferences JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT,
    attendees TEXT[],
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_digital_files_category ON digital_files(category);
CREATE INDEX IF NOT EXISTS idx_digital_files_uploaded_at ON digital_files(uploaded_at);
CREATE INDEX IF NOT EXISTS idx_survey_responses_created_at ON survey_responses(created_at);
CREATE INDEX IF NOT EXISTS idx_newsletter_subscribers_email ON newsletter_subscribers(email);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_date ON calendar_events(start_date);

-- 6. Verify storage bucket exists (this will error if not exists, which is expected)
SELECT 
    'digital-files bucket exists' as status,
    id, name, public, file_size_limit
FROM storage.buckets 
WHERE id = 'digital-files';

-- 7. List all storage policies
SELECT 
    'Storage policies:' as info,
    policyname, 
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 8. Verify RLS is enabled on required tables
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('digital_files', 'survey_responses', 'newsletter_subscribers', 'calendar_events')
ORDER BY tablename;
