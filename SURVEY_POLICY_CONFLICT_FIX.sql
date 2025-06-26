-- SURVEY POLICY CONFLICT FIX
-- This resolves the "policy already exists" error (42710)

-- 1. FIRST, DROP EXISTING POLICIES IF THEY EXIST
DROP POLICY IF EXISTS "Authenticated users can manage surveys" ON public.surveys;
DROP POLICY IF EXISTS "Users can view their own surveys" ON public.surveys;
DROP POLICY IF EXISTS "Users can create surveys" ON public.surveys;
DROP POLICY IF EXISTS "Users can update their own surveys" ON public.surveys;
DROP POLICY IF EXISTS "Users can delete their own surveys" ON public.surveys;

-- 2. ENSURE RLS IS ENABLED
ALTER TABLE public.surveys ENABLE ROW LEVEL SECURITY;

-- 3. CREATE CLEAN, NON-CONFLICTING POLICIES
CREATE POLICY "survey_select_policy" ON public.surveys
    FOR SELECT 
    USING (auth.uid() = created_by OR auth.uid() IN (
        SELECT user_id FROM public.profiles WHERE role = 'admin'
    ));

CREATE POLICY "survey_insert_policy" ON public.surveys
    FOR INSERT 
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "survey_update_policy" ON public.surveys
    FOR UPDATE 
    USING (auth.uid() = created_by OR auth.uid() IN (
        SELECT user_id FROM public.profiles WHERE role = 'admin'
    ))
    WITH CHECK (auth.uid() = created_by OR auth.uid() IN (
        SELECT user_id FROM public.profiles WHERE role = 'admin'
    ));

CREATE POLICY "survey_delete_policy" ON public.surveys
    FOR DELETE 
    USING (auth.uid() = created_by OR auth.uid() IN (
        SELECT user_id FROM public.profiles WHERE role = 'admin'
    ));

-- 4. VERIFY CURRENT COLUMN NAMES
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'surveys' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. ADD MISSING COLUMNS IF THEY DON'T EXIST (with correct snake_case names)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'welcome_message' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ADD COLUMN welcome_message TEXT;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'thank_you_message' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ADD COLUMN thank_you_message TEXT;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'published_at' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ADD COLUMN published_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'closed_at' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ADD COLUMN closed_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- 6. ENSURE ALL REQUIRED COLUMNS EXIST WITH CORRECT DEFAULTS
DO $$
BEGIN
    -- Set default for pages column if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'pages' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ALTER COLUMN pages SET DEFAULT '[]'::jsonb;
    END IF;
END $$;

DO $$
BEGIN
    -- Set default for settings column if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'settings' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ALTER COLUMN settings SET DEFAULT '{"allowAnonymous": true, "progressBar": true}'::jsonb;
    END IF;
END $$;

DO $$
BEGIN
    -- Set default for branding column if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'branding' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ALTER COLUMN branding SET DEFAULT '{}'::jsonb;
    END IF;
END $$;

DO $$
BEGIN
    -- Set default for analytics column if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'surveys' AND column_name = 'analytics' AND table_schema = 'public') THEN
        ALTER TABLE public.surveys ALTER COLUMN analytics SET DEFAULT '{"totalViews": 0, "totalStarts": 0, "totalCompletes": 0, "completionRate": 0, "averageTime": 0}'::jsonb;
    END IF;
END $$;

-- 7. CREATE OR REPLACE HELPER FUNCTION FOR CONSISTENT SURVEY CREATION
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

-- 8. VERIFY POLICIES ARE CORRECTLY SET
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'surveys';

-- 9. VERIFY FINAL SCHEMA
SELECT 
    'Final surveys table schema:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'surveys' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'Survey policy conflict fix complete!' as result;
