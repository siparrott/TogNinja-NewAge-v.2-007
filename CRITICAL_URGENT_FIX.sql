-- CRITICAL URGENT FIX - CALENDAR AND DIGITAL FILES
-- Run this SQL immediately in your Supabase SQL Editor
-- This will fix both calendar saving and digital files functionality

-- =====================================================
-- 1. CALENDAR SYSTEM COMPLETE FIX
-- =====================================================

-- Drop existing tables if they have issues
DROP TABLE IF EXISTS public.calendar_event_reminders CASCADE;
DROP TABLE IF EXISTS public.calendar_event_attendees CASCADE;
DROP TABLE IF EXISTS public.calendar_events CASCADE;
DROP TABLE IF EXISTS public.calendars CASCADE;
DROP TABLE IF EXISTS public.calendar_categories CASCADE;

-- Create calendar_categories table
CREATE TABLE public.calendar_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    color TEXT DEFAULT '#3B82F6',
    description TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create calendars table
CREATE TABLE public.calendars (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    timezone TEXT DEFAULT 'UTC',
    is_default BOOLEAN DEFAULT false,
    is_public BOOLEAN DEFAULT false,
    sync_enabled BOOLEAN DEFAULT false,
    sync_url TEXT,
    last_sync TIMESTAMP WITH TIME ZONE,
    external_id TEXT,
    external_source TEXT,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create calendar_events table
CREATE TABLE public.calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    all_day BOOLEAN DEFAULT false,
    timezone TEXT DEFAULT 'UTC',
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'tentative', 'cancelled')),
    visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'confidential')),
    importance TEXT DEFAULT 'normal' CHECK (importance IN ('low', 'normal', 'high')),
    category_id UUID REFERENCES public.calendar_categories(id) ON DELETE SET NULL,
    calendar_id UUID REFERENCES public.calendars(id) ON DELETE CASCADE,
    color TEXT DEFAULT '#3B82F6',
    is_recurring BOOLEAN DEFAULT false,
    recurrence_rule TEXT,
    recurrence_exception_dates TEXT[],
    parent_event_id UUID REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    external_id TEXT,
    external_source TEXT,
    ical_uid TEXT UNIQUE DEFAULT gen_random_uuid()::text,
    is_bookable BOOLEAN DEFAULT false,
    max_attendees INTEGER,
    booking_window_start TIMESTAMP WITH TIME ZONE,
    booking_window_end TIMESTAMP WITH TIME ZONE
);

-- Create calendar_event_attendees table
CREATE TABLE public.calendar_event_attendees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,
    role TEXT DEFAULT 'attendee' CHECK (role IN ('organizer', 'attendee', 'optional')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'tentative')),
    response_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create calendar_event_reminders table
CREATE TABLE public.calendar_event_reminders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    type TEXT DEFAULT 'email' CHECK (type IN ('email', 'popup', 'sms', 'push')),
    minutes_before INTEGER NOT NULL DEFAULT 15,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. DIGITAL FILES SYSTEM COMPLETE FIX
-- =====================================================

-- Drop existing digital files table if it has issues
DROP TABLE IF EXISTS public.digital_files CASCADE;

-- Create digital_files table
CREATE TABLE public.digital_files (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    filename TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type TEXT NOT NULL,
    file_path TEXT NOT NULL,
    public_url TEXT,
    client_id UUID,
    client_name TEXT,
    booking_id UUID,
    category TEXT DEFAULT 'general',
    tags TEXT[] DEFAULT '{}',
    is_public BOOLEAN DEFAULT false,
    is_favorite BOOLEAN DEFAULT false,
    rating INTEGER CHECK (rating >= 0 AND rating <= 5),
    description TEXT,
    keywords TEXT[] DEFAULT '{}',
    copyright TEXT,
    -- Image metadata
    width INTEGER,
    height INTEGER,
    camera_make TEXT,
    camera_model TEXT,
    lens_model TEXT,
    focal_length TEXT,
    aperture TEXT,
    shutter_speed TEXT,
    iso INTEGER,
    color_profile TEXT,
    -- Usage stats
    view_count INTEGER DEFAULT 0,
    download_count INTEGER DEFAULT 0,
    -- Timestamps
    uploaded_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Calendar indexes
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_time ON public.calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_end_time ON public.calendar_events(end_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_calendar_id ON public.calendar_events(calendar_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_created_by ON public.calendar_events(created_by);
CREATE INDEX IF NOT EXISTS idx_calendars_owner_id ON public.calendars(owner_id);

-- Digital files indexes
CREATE INDEX IF NOT EXISTS idx_digital_files_client_id ON public.digital_files(client_id);
CREATE INDEX IF NOT EXISTS idx_digital_files_uploaded_by ON public.digital_files(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_digital_files_created_at ON public.digital_files(created_at);
CREATE INDEX IF NOT EXISTS idx_digital_files_category ON public.digital_files(category);

-- =====================================================
-- 4. ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.calendar_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_event_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_event_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digital_files ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. CREATE RLS POLICIES
-- =====================================================

-- Calendar Categories policies
CREATE POLICY "Users can view their own calendar categories" ON public.calendar_categories
    FOR SELECT USING (auth.uid() = created_by);
CREATE POLICY "Users can create their own calendar categories" ON public.calendar_categories
    FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update their own calendar categories" ON public.calendar_categories
    FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Users can delete their own calendar categories" ON public.calendar_categories
    FOR DELETE USING (auth.uid() = created_by);

-- Calendars policies
CREATE POLICY "Users can view their own calendars" ON public.calendars
    FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "Users can create their own calendars" ON public.calendars
    FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can update their own calendars" ON public.calendars
    FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Users can delete their own calendars" ON public.calendars
    FOR DELETE USING (auth.uid() = owner_id);

-- Calendar Events policies
CREATE POLICY "Users can view their own calendar events" ON public.calendar_events
    FOR SELECT USING (auth.uid() = created_by);
CREATE POLICY "Users can create their own calendar events" ON public.calendar_events
    FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Users can update their own calendar events" ON public.calendar_events
    FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Users can delete their own calendar events" ON public.calendar_events
    FOR DELETE USING (auth.uid() = created_by);

-- Calendar Event Attendees policies
CREATE POLICY "Users can view attendees for their events" ON public.calendar_event_attendees
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM public.calendar_events 
        WHERE calendar_events.id = event_id 
        AND calendar_events.created_by = auth.uid()
    ));
CREATE POLICY "Users can create attendees for their events" ON public.calendar_event_attendees
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM public.calendar_events 
        WHERE calendar_events.id = event_id 
        AND calendar_events.created_by = auth.uid()
    ));
CREATE POLICY "Users can update attendees for their events" ON public.calendar_event_attendees
    FOR UPDATE USING (EXISTS (
        SELECT 1 FROM public.calendar_events 
        WHERE calendar_events.id = event_id 
        AND calendar_events.created_by = auth.uid()
    ));
CREATE POLICY "Users can delete attendees for their events" ON public.calendar_event_attendees
    FOR DELETE USING (EXISTS (
        SELECT 1 FROM public.calendar_events 
        WHERE calendar_events.id = event_id 
        AND calendar_events.created_by = auth.uid()
    ));

-- Calendar Event Reminders policies
CREATE POLICY "Users can view reminders for their events" ON public.calendar_event_reminders
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM public.calendar_events 
        WHERE calendar_events.id = event_id 
        AND calendar_events.created_by = auth.uid()
    ));
CREATE POLICY "Users can create reminders for their events" ON public.calendar_event_reminders
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM public.calendar_events 
        WHERE calendar_events.id = event_id 
        AND calendar_events.created_by = auth.uid()
    ));
CREATE POLICY "Users can update reminders for their events" ON public.calendar_event_reminders
    FOR UPDATE USING (EXISTS (
        SELECT 1 FROM public.calendar_events 
        WHERE calendar_events.id = event_id 
        AND calendar_events.created_by = auth.uid()
    ));
CREATE POLICY "Users can delete reminders for their events" ON public.calendar_event_reminders
    FOR DELETE USING (EXISTS (
        SELECT 1 FROM public.calendar_events 
        WHERE calendar_events.id = event_id 
        AND calendar_events.created_by = auth.uid()
    ));

-- Digital Files policies
CREATE POLICY "Users can view their own digital files" ON public.digital_files
    FOR SELECT USING (auth.uid() = uploaded_by);
CREATE POLICY "Users can create their own digital files" ON public.digital_files
    FOR INSERT WITH CHECK (auth.uid() = uploaded_by);
CREATE POLICY "Users can update their own digital files" ON public.digital_files
    FOR UPDATE USING (auth.uid() = uploaded_by);
CREATE POLICY "Users can delete their own digital files" ON public.digital_files
    FOR DELETE USING (auth.uid() = uploaded_by);

-- =====================================================
-- 6. INSERT DEFAULT DATA
-- =====================================================

-- Insert default calendar category
INSERT INTO public.calendar_categories (name, color, description, created_by)
SELECT 'General', '#3B82F6', 'Default category for events', auth.uid()
WHERE auth.uid() IS NOT NULL
ON CONFLICT DO NOTHING;

-- Insert default calendar
INSERT INTO public.calendars (name, color, description, is_default, owner_id)
SELECT 'My Calendar', '#3B82F6', 'Default personal calendar', true, auth.uid()
WHERE auth.uid() IS NOT NULL
ON CONFLICT DO NOTHING;

-- =====================================================
-- 7. CREATE STORAGE BUCKET FOR DIGITAL FILES
-- =====================================================

-- This needs to be run separately in the Supabase dashboard
-- Go to Storage -> Create new bucket:
-- Bucket name: digital-files
-- Public bucket: false (private)
-- File size limit: 50MB
-- Allowed MIME types: image/*, video/*, application/pdf, text/*

-- Note: After creating the bucket, you need to set up Storage RLS policies:
/*
CREATE POLICY "Users can upload their own files" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'digital-files' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own files" ON storage.objects
    FOR SELECT USING (bucket_id = 'digital-files' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own files" ON storage.objects
    FOR UPDATE USING (bucket_id = 'digital-files' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own files" ON storage.objects
    FOR DELETE USING (bucket_id = 'digital-files' AND auth.uid()::text = (storage.foldername(name))[1]);
*/
