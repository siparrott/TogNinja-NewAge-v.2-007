-- NEWSLETTER AND QUESTIONNAIRE SYSTEM SETUP
-- Run this in your Supabase SQL Editor to fix both newsletter and questionnaire functionality

-- 1. CREATE LEADS TABLE (for newsletter signups)
CREATE TABLE IF NOT EXISTS public.leads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    company TEXT,
    message TEXT,
    form_source TEXT DEFAULT 'KONTAKT' CHECK (form_source IN ('KONTAKT', 'NEWSLETTER', 'WEBSITE', 'SOCIAL', 'REFERRAL', 'OTHER')),
    status TEXT DEFAULT 'NEW' CHECK (status IN ('NEW', 'CONTACTED', 'QUALIFIED', 'CONVERTED', 'LOST')),
    priority TEXT DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    assigned_to UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_contact_date TIMESTAMP WITH TIME ZONE,
    budget_range TEXT,
    preferred_contact_method TEXT DEFAULT 'email' CHECK (preferred_contact_method IN ('email', 'phone', 'whatsapp', 'text')),
    tags TEXT[]
);

-- 2. CREATE NEWSLETTER SUBSCRIBERS TABLE
CREATE TABLE IF NOT EXISTS public.newsletter_subscribers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'unsubscribed', 'bounced')),
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    unsubscribed_at TIMESTAMP WITH TIME ZONE,
    subscription_source TEXT DEFAULT 'website',
    preferences JSONB DEFAULT '{}'::jsonb
);

-- 3. CREATE SURVEYS TABLE (for questionnaires)
CREATE TABLE IF NOT EXISTS public.surveys (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'archived')),
    questions JSONB DEFAULT '[]'::jsonb,
    settings JSONB DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    published_at TIMESTAMP WITH TIME ZONE,
    response_count INTEGER DEFAULT 0
);

-- 4. CREATE SURVEY RESPONSES TABLE
CREATE TABLE IF NOT EXISTS public.survey_responses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    survey_id UUID REFERENCES public.surveys(id) ON DELETE CASCADE,
    respondent_email TEXT,
    responses JSONB DEFAULT '{}'::jsonb,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address TEXT,
    user_agent TEXT,
    completion_time INTEGER -- in seconds
);

-- 5. ENABLE RLS
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.newsletter_subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.survey_responses ENABLE ROW LEVEL SECURITY;

-- 6. CREATE RLS POLICIES

-- Leads policies
CREATE POLICY "Admin users can manage leads" ON public.leads
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.email IN ('admin@example.com', 'admin@togninja.com')
        )
    );

CREATE POLICY "Allow newsletter signups" ON public.leads
    FOR INSERT WITH CHECK (form_source = 'NEWSLETTER');

-- Newsletter subscribers policies
CREATE POLICY "Admin users can manage subscribers" ON public.newsletter_subscribers
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.email IN ('admin@example.com', 'admin@togninja.com')
        )
    );

CREATE POLICY "Allow public newsletter signups" ON public.newsletter_subscribers
    FOR INSERT WITH CHECK (true);

-- Survey policies
CREATE POLICY "Admin users can manage surveys" ON public.surveys
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.email IN ('admin@example.com', 'admin@togninja.com')
        )
    );

-- Survey response policies (public can submit)
CREATE POLICY "Anyone can submit survey responses" ON public.survey_responses
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin users can view survey responses" ON public.survey_responses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND auth.users.email IN ('admin@example.com', 'admin@togninja.com')
        )
    );

-- 7. CREATE INDEXES
CREATE INDEX IF NOT EXISTS idx_leads_email ON public.leads(email);
CREATE INDEX IF NOT EXISTS idx_leads_form_source ON public.leads(form_source);
CREATE INDEX IF NOT EXISTS idx_leads_status ON public.leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON public.leads(created_at);

CREATE INDEX IF NOT EXISTS idx_newsletter_subscribers_email ON public.newsletter_subscribers(email);
CREATE INDEX IF NOT EXISTS idx_newsletter_subscribers_status ON public.newsletter_subscribers(status);

CREATE INDEX IF NOT EXISTS idx_surveys_status ON public.surveys(status);
CREATE INDEX IF NOT EXISTS idx_surveys_created_by ON public.surveys(created_by);

CREATE INDEX IF NOT EXISTS idx_survey_responses_survey_id ON public.survey_responses(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_responses_completed_at ON public.survey_responses(completed_at);

-- 8. CREATE SAMPLE DATA

-- Sample lead for testing
INSERT INTO public.leads (
    first_name, 
    last_name, 
    email, 
    message, 
    form_source, 
    status
) VALUES (
    'Newsletter',
    'Test User',
    'test@example.com',
    'Test newsletter signup',
    'NEWSLETTER',
    'NEW'
) ON CONFLICT (email) DO NOTHING;

-- Sample survey for testing
INSERT INTO public.surveys (
    title,
    description,
    status,
    questions,
    created_by
) VALUES (
    'Customer Satisfaction Survey',
    'Help us improve our photography services',
    'active',
    '[
        {
            "id": "q1",
            "title": "How satisfied are you with our service?",
            "type": "multiple_choice",
            "required": true,
            "options": [
                {"id": "o1", "text": "Very Satisfied"},
                {"id": "o2", "text": "Satisfied"},
                {"id": "o3", "text": "Neutral"},
                {"id": "o4", "text": "Dissatisfied"},
                {"id": "o5", "text": "Very Dissatisfied"}
            ]
        }
    ]'::jsonb,
    auth.uid()
) ON CONFLICT DO NOTHING;

-- 9. VERIFY SETUP
SELECT 'leads' as table_name, count(*) as row_count FROM public.leads
UNION ALL
SELECT 'newsletter_subscribers' as table_name, count(*) as row_count FROM public.newsletter_subscribers
UNION ALL
SELECT 'surveys' as table_name, count(*) as row_count FROM public.surveys
UNION ALL
SELECT 'survey_responses' as table_name, count(*) as row_count FROM public.survey_responses;

-- 10. UPDATE FUNCTIONS TO HANDLE NEWSLETTER SIGNUPS
CREATE OR REPLACE FUNCTION handle_newsletter_signup(email_input TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSONB;
BEGIN
    -- Insert into leads table
    INSERT INTO public.leads (
        first_name,
        last_name,
        email,
        message,
        form_source,
        status
    ) VALUES (
        'Newsletter',
        'Subscriber',
        email_input,
        'Newsletter signup - €50 Print Gutschein',
        'NEWSLETTER',
        'NEW'
    ) ON CONFLICT (email) DO NOTHING;
    
    -- Insert into newsletter_subscribers table
    INSERT INTO public.newsletter_subscribers (
        email,
        status,
        subscription_source
    ) VALUES (
        email_input,
        'active',
        'website'
    ) ON CONFLICT (email) DO NOTHING;
    
    result := jsonb_build_object(
        'success', true,
        'message', 'Successfully subscribed to newsletter!'
    );
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result := jsonb_build_object(
            'success', false,
            'message', 'Failed to process newsletter signup'
        );
        RETURN result;
END;
$$;
