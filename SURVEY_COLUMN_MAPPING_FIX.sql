-- SURVEY API COLUMN MAPPING FIX
-- This ensures the database columns match what the TypeScript API expects

-- 1. VERIFY CURRENT COLUMN NAMES
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'surveys' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. ADD MISSING COLUMNS IF THEY DON'T EXIST (with correct snake_case names)
-- Add welcome_message if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'welcome_message' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ADD COLUMN welcome_message TEXT;
    END IF;
END $$;

-- Add thank_you_message if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'thank_you_message' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ADD COLUMN thank_you_message TEXT;
    END IF;
END $$;

-- Add published_at if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'published_at' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ADD COLUMN published_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Add closed_at if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'closed_at' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ADD COLUMN closed_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- 3. ENSURE ALL REQUIRED COLUMNS EXIST WITH CORRECT DEFAULTS
-- Ensure pages column has proper default
ALTER TABLE public.surveys ALTER COLUMN pages SET DEFAULT '[]'::jsonb;

-- Ensure settings column has proper default
ALTER TABLE public.surveys ALTER COLUMN settings SET DEFAULT '{"allowAnonymous": true, "progressBar": true}'::jsonb;

-- Ensure branding column has proper default
ALTER TABLE public.surveys ALTER COLUMN branding SET DEFAULT '{}'::jsonb;

-- Ensure analytics column has proper default
ALTER TABLE public.surveys ALTER COLUMN analytics SET DEFAULT '{"totalViews": 0, "totalStarts": 0, "totalCompletes": 0, "completionRate": 0, "averageTime": 0}'::jsonb;

-- 4. CREATE OR REPLACE A HELPER FUNCTION FOR CONSISTENT SURVEY CREATION
CREATE OR REPLACE FUNCTION create_survey_with_defaults(
    p_title TEXT,
    p_description TEXT DEFAULT NULL,
    p_welcome_message TEXT DEFAULT NULL,
    p_thank_you_message TEXT DEFAULT NULL,
    p_pages JSONB DEFAULT '[]'::jsonb,
    p_settings JSONB DEFAULT '{"allowAnonymous": true, "progressBar": true}'::jsonb,
    p_created_by UUID DEFAULT NULL
) RETURNS TABLE(
    id UUID,
    title TEXT,
    description TEXT,
    welcome_message TEXT,
    thank_you_message TEXT,
    status TEXT,
    pages JSONB,
    settings JSONB,
    branding JSONB,
    analytics JSONB,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    published_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    INSERT INTO public.surveys (
        title,
        description,
        welcome_message,
        thank_you_message,
        pages,
        settings,
        branding,
        analytics,
        created_by
    ) VALUES (
        p_title,
        p_description,
        p_welcome_message,
        p_thank_you_message,
        p_pages,
        p_settings,
        '{}'::jsonb,
        '{"totalViews": 0, "totalStarts": 0, "totalCompletes": 0, "completionRate": 0, "averageTime": 0}'::jsonb,
        COALESCE(p_created_by, auth.uid())
    ) RETURNING 
        surveys.id,
        surveys.title,
        surveys.description,
        surveys.welcome_message,
        surveys.thank_you_message,
        surveys.status,
        surveys.pages,
        surveys.settings,
        surveys.branding,
        surveys.analytics,
        surveys.created_by,
        surveys.created_at,
        surveys.updated_at,
        surveys.published_at,
        surveys.closed_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_survey_with_defaults TO authenticated;

-- 5. TEST THE FUNCTION
SELECT 'Testing survey creation function...' as message;

-- Try to create a test survey using the function
SELECT * FROM create_survey_with_defaults(
    'Test Survey Function',
    'This tests the survey creation function',
    'Welcome to our test survey',
    'Thank you for completing our test survey'
);

-- 6. VERIFY FINAL SCHEMA
SELECT 
    'surveys table schema:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'surveys' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'Survey column mapping fix complete!' as result;
