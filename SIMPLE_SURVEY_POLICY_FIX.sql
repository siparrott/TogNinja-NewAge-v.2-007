-- SIMPLE SURVEY POLICY FIX
-- This just resolves the "policy already exists" error quickly

-- Drop the conflicting policy if it exists
DROP POLICY IF EXISTS "Authenticated users can manage surveys" ON public.surveys;

-- Enable RLS if not already enabled
ALTER TABLE public.surveys ENABLE ROW LEVEL SECURITY;

-- Create a simple, clean policy with a unique name
CREATE POLICY "surveys_authenticated_access" ON public.surveys
    FOR ALL 
    USING (auth.uid() = created_by)
    WITH CHECK (auth.uid() = created_by);

-- Verify the policy was created
SELECT 
    'Survey policies:' as info,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'surveys';

SELECT 'Simple survey policy fix complete!' as result;
