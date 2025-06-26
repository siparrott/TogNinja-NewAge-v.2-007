-- QUICK SURVEY FIX - Run this immediately in Supabase SQL Editor
-- This creates the minimum required tables for surveys/questionnaires to save

-- Create surveys table
CREATE TABLE IF NOT EXISTS public.surveys (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    welcome_message TEXT,
    thank_you_message TEXT,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'closed', 'archived')),
    pages JSONB DEFAULT '[]'::jsonb,
    settings JSONB DEFAULT '{}'::jsonb,
    branding JSONB DEFAULT '{}'::jsonb,
    analytics JSONB DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    published_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE
);

-- Create survey_questions table (if needed for complex queries)
CREATE TABLE IF NOT EXISTS public.survey_questions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id UUID REFERENCES public.surveys(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    required BOOLEAN DEFAULT false,
    order_index INTEGER NOT NULL,
    options JSONB DEFAULT '[]'::jsonb,
    validation JSONB DEFAULT '{}'::jsonb,
    logic JSONB DEFAULT '{}'::jsonb,
    settings JSONB DEFAULT '{}'::jsonb,
    page_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create survey_responses table
CREATE TABLE IF NOT EXISTS public.survey_responses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id UUID REFERENCES public.surveys(id) ON DELETE CASCADE,
    respondent_email TEXT,
    respondent_name TEXT,
    responses JSONB DEFAULT '{}'::jsonb,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    ip_address TEXT,
    user_agent TEXT,
    completion_time INTEGER, -- in seconds
    is_complete BOOLEAN DEFAULT false,
    page_number INTEGER DEFAULT 1
);

-- Create survey_analytics table (for tracking views, starts, etc.)
CREATE TABLE IF NOT EXISTS public.survey_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id UUID REFERENCES public.surveys(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- 'view', 'start', 'complete', 'abandon'
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address TEXT,
    user_agent TEXT,
    page_number INTEGER,
    time_spent INTEGER -- seconds on page
);

-- Enable RLS
ALTER TABLE public.surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.survey_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.survey_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.survey_analytics ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for surveys
DROP POLICY IF EXISTS "Users can manage their surveys" ON public.surveys;
CREATE POLICY "Users can manage their surveys" ON public.surveys
    FOR ALL USING (auth.uid() = created_by);

-- Allow admin users to manage all surveys
DROP POLICY IF EXISTS "Admin users can manage all surveys" ON public.surveys;
CREATE POLICY "Admin users can manage all surveys" ON public.surveys
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND (
                auth.users.email ILIKE '%admin%' OR 
                auth.users.email IN ('admin@togninja.com', 'admin@example.com', 'matt@newagefotografie.com')
            )
        )
    );

-- Survey questions policies
DROP POLICY IF EXISTS "Users can manage their survey questions" ON public.survey_questions;
CREATE POLICY "Users can manage their survey questions" ON public.survey_questions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.surveys 
            WHERE surveys.id = survey_questions.survey_id 
            AND surveys.created_by = auth.uid()
        )
    );

-- Survey responses policies (allow public to submit responses)
DROP POLICY IF EXISTS "Anyone can submit survey responses" ON public.survey_responses;
CREATE POLICY "Anyone can submit survey responses" ON public.survey_responses
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Survey creators can view responses" ON public.survey_responses;
CREATE POLICY "Survey creators can view responses" ON public.survey_responses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.surveys 
            WHERE surveys.id = survey_responses.survey_id 
            AND surveys.created_by = auth.uid()
        )
    );

-- Analytics policies
DROP POLICY IF EXISTS "Anyone can log analytics" ON public.survey_analytics;
CREATE POLICY "Anyone can log analytics" ON public.survey_analytics
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Survey creators can view analytics" ON public.survey_analytics;
CREATE POLICY "Survey creators can view analytics" ON public.survey_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.surveys 
            WHERE surveys.id = survey_analytics.survey_id 
            AND surveys.created_by = auth.uid()
        )
    );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_surveys_created_by ON public.surveys(created_by);
CREATE INDEX IF NOT EXISTS idx_surveys_status ON public.surveys(status);
CREATE INDEX IF NOT EXISTS idx_surveys_created_at ON public.surveys(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_survey_questions_survey_id ON public.survey_questions(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_questions_order ON public.survey_questions(survey_id, order_index);

CREATE INDEX IF NOT EXISTS idx_survey_responses_survey_id ON public.survey_responses(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_responses_completed_at ON public.survey_responses(completed_at);
CREATE INDEX IF NOT EXISTS idx_survey_responses_email ON public.survey_responses(respondent_email);

CREATE INDEX IF NOT EXISTS idx_survey_analytics_survey_id ON public.survey_analytics(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_analytics_event_type ON public.survey_analytics(event_type);

-- Insert a sample survey to test functionality
DO $$
DECLARE
    current_user_id UUID;
    sample_survey_id UUID;
BEGIN
    -- Get current user ID
    SELECT auth.uid() INTO current_user_id;
    
    -- Only insert if we have a user and no surveys exist
    IF current_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.surveys WHERE created_by = current_user_id) THEN
        -- Create sample survey
        INSERT INTO public.surveys (
            title, 
            description, 
            welcome_message,
            thank_you_message,
            status, 
            pages,
            settings,
            created_by
        ) VALUES (
            'Sample Survey',
            'This is a sample survey to test the questionnaire system',
            'Welcome to our survey! Your feedback is important to us.',
            'Thank you for completing our survey! Your responses have been recorded.',
            'draft',
            '[
                {
                    "id": "page1",
                    "title": "Page 1",
                    "questions": [
                        {
                            "id": "q1",
                            "type": "multiple_choice",
                            "title": "How satisfied are you with our service?",
                            "required": true,
                            "order": 1,
                            "options": [
                                {"id": "opt1", "text": "Very satisfied"},
                                {"id": "opt2", "text": "Satisfied"},
                                {"id": "opt3", "text": "Neutral"},
                                {"id": "opt4", "text": "Dissatisfied"},
                                {"id": "opt5", "text": "Very dissatisfied"}
                            ]
                        }
                    ]
                }
            ]'::jsonb,
            '{
                "collectEmail": true,
                "requireEmail": false,
                "allowAnonymous": true,
                "progressBar": true,
                "previousButton": true
            }'::jsonb,
            current_user_id
        ) RETURNING id INTO sample_survey_id;
        
        -- Create sample question in separate table
        INSERT INTO public.survey_questions (
            survey_id,
            type,
            title,
            description,
            required,
            order_index,
            options,
            page_id
        ) VALUES (
            sample_survey_id,
            'multiple_choice',
            'How satisfied are you with our service?',
            'Please rate your overall satisfaction',
            true,
            1,
            '[
                {"id": "opt1", "text": "Very satisfied"},
                {"id": "opt2", "text": "Satisfied"},
                {"id": "opt3", "text": "Neutral"},
                {"id": "opt4", "text": "Dissatisfied"},
                {"id": "opt5", "text": "Very dissatisfied"}
            ]'::jsonb,
            'page1'
        );
    END IF;
END $$;

SELECT 'SUCCESS: Survey tables created! Questionnaires should now save properly.' AS status;
