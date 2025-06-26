-- =============================================
-- CRITICAL DATABASE SCHEMA UPDATES
-- Run this in your Supabase SQL Editor
-- =============================================

-- 1. Newsletter System Tables
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'unsubscribed')),
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS newsletter_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    html_content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS newsletter_campaigns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    html_content TEXT,
    template_id UUID REFERENCES newsletter_templates(id),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'failed')),
    scheduled_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    recipient_count INTEGER DEFAULT 0,
    open_count INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enhanced Invoices System
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS line_items JSONB DEFAULT '[]'::jsonb;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS tax_rate DECIMAL(5,2) DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS payment_terms VARCHAR(100);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS notes TEXT;

-- 3. Gallery Enhancements
CREATE TABLE IF NOT EXISTS gallery_images (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    public_url VARCHAR(500) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    alt_text VARCHAR(255),
    tags TEXT[],
    gallery_category VARCHAR(100),
    is_featured BOOLEAN DEFAULT false,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. OpenAI Assistant Sessions
CREATE TABLE IF NOT EXISTS openai_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    thread_id VARCHAR(255),
    assistant_type VARCHAR(50) CHECK (assistant_type IN ('customization', 'crm_operations')),
    context JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS openai_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES openai_sessions(id) ON DELETE CASCADE,
    message_id VARCHAR(255),
    role VARCHAR(20) CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Enhanced Calendar Events
ALTER TABLE calendar_events ADD COLUMN IF NOT EXISTS location VARCHAR(255);
ALTER TABLE calendar_events ADD COLUMN IF NOT EXISTS all_day BOOLEAN DEFAULT false;
ALTER TABLE calendar_events ADD COLUMN IF NOT EXISTS recurrence_rule TEXT;

-- 6. System Settings
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value JSONB,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default settings
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('theme_settings', '{"primaryColor": "#8B5CF6", "secondaryColor": "#10B981", "accentColor": "#F59E0B"}'::jsonb, 'Theme color settings'),
('email_settings', '{"smtp_host": "", "smtp_port": 587, "sender_name": "TogNinja", "sender_email": ""}'::jsonb, 'Email configuration'),
('openai_settings', '{"api_key": "", "assistant_ids": {"customization": "", "crm_operations": ""}}'::jsonb, 'OpenAI API configuration')
ON CONFLICT (setting_key) DO NOTHING;

-- 7. Row Level Security Policies
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE openai_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE openai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Policies for authenticated users
CREATE POLICY IF NOT EXISTS "Authenticated users can manage newsletter" ON newsletter_subscribers FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY IF NOT EXISTS "Authenticated users can manage templates" ON newsletter_templates FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY IF NOT EXISTS "Authenticated users can manage campaigns" ON newsletter_campaigns FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY IF NOT EXISTS "Authenticated users can manage gallery" ON gallery_images FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY IF NOT EXISTS "Users can manage their sessions" ON openai_sessions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage their messages" ON openai_messages FOR ALL USING (auth.uid() = (SELECT user_id FROM openai_sessions WHERE id = session_id));
CREATE POLICY IF NOT EXISTS "Authenticated users can manage settings" ON system_settings FOR ALL USING (auth.role() = 'authenticated');

-- 8. Storage Buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
('gallery-images', 'gallery-images', true),
('digital-files', 'digital-files', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY IF NOT EXISTS "Authenticated users can upload gallery images" ON storage.objects 
FOR INSERT WITH CHECK (bucket_id = 'gallery-images' AND auth.role() = 'authenticated');

CREATE POLICY IF NOT EXISTS "Gallery images are publicly accessible" ON storage.objects 
FOR SELECT USING (bucket_id = 'gallery-images');

CREATE POLICY IF NOT EXISTS "Authenticated users can upload digital files" ON storage.objects 
FOR INSERT WITH CHECK (bucket_id = 'digital-files' AND auth.role() = 'authenticated');

CREATE POLICY IF NOT EXISTS "Authenticated users can access digital files" ON storage.objects 
FOR SELECT USING (bucket_id = 'digital-files' AND auth.role() = 'authenticated');

-- =============================================
-- END OF DATABASE SCHEMA UPDATES
-- =============================================
