-- CRITICAL FINAL FIXES - Run this in Supabase SQL Editor
-- This will fix both Calendar and Digital Files issues

-- 1. FIX DIGITAL FILES STORAGE POLICIES
-- First, drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow public downloads" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own files" ON storage.objects;

-- Create new, working storage policies for digital-files bucket
CREATE POLICY "Digital files - authenticated users can insert" ON storage.objects
FOR INSERT TO authenticated 
WITH CHECK (bucket_id = 'digital-files');

CREATE POLICY "Digital files - authenticated users can select" ON storage.objects
FOR SELECT TO authenticated 
USING (bucket_id = 'digital-files');

CREATE POLICY "Digital files - authenticated users can update" ON storage.objects
FOR UPDATE TO authenticated 
USING (bucket_id = 'digital-files');

CREATE POLICY "Digital files - authenticated users can delete" ON storage.objects
FOR DELETE TO authenticated 
USING (bucket_id = 'digital-files');

-- 2. ENSURE DIGITAL FILES TABLE EXISTS
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
    
    -- Processing
    is_processed BOOLEAN DEFAULT false,
    processing_status TEXT DEFAULT 'pending',
    
    -- Access control
    access_level TEXT DEFAULT 'private' CHECK (access_level IN ('private', 'client', 'public')),
    download_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE
);

-- Enable RLS on digital_files
ALTER TABLE public.digital_files ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for digital_files table
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

-- 3. FIX CALENDAR SYSTEM - CREATE REQUIRED TABLES
-- Create calendars table
CREATE TABLE IF NOT EXISTS public.calendars (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    is_default BOOLEAN DEFAULT false,
    is_visible BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create calendar categories table
CREATE TABLE IF NOT EXISTS public.calendar_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#6B7280',
    icon TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create calendar events table
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    all_day BOOLEAN DEFAULT false,
    calendar_id UUID REFERENCES public.calendars(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.calendar_categories(id),
    color TEXT DEFAULT '#3B82F6',
    visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'confidential')),
    importance TEXT DEFAULT 'normal' CHECK (importance IN ('low', 'normal', 'high')),
    is_recurring BOOLEAN DEFAULT false,
    recurrence_rule TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create calendar event attendees table
CREATE TABLE IF NOT EXISTS public.calendar_event_attendees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    role TEXT DEFAULT 'attendee' CHECK (role IN ('organizer', 'attendee', 'optional')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'tentative')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create calendar event reminders table
CREATE TABLE IF NOT EXISTS public.calendar_event_reminders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('email', 'popup', 'sms', 'push')),
    minutes_before INTEGER NOT NULL DEFAULT 15,
    is_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on all calendar tables
ALTER TABLE public.calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_event_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_event_reminders ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for calendars
DROP POLICY IF EXISTS "Users can manage their own calendars" ON public.calendars;
CREATE POLICY "Users can manage their own calendars" ON public.calendars
    FOR ALL USING (created_by = auth.uid());

-- Create RLS policies for calendar categories
DROP POLICY IF EXISTS "Users can manage their own categories" ON public.calendar_categories;
CREATE POLICY "Users can manage their own categories" ON public.calendar_categories
    FOR ALL USING (created_by = auth.uid());

-- Create RLS policies for calendar events
DROP POLICY IF EXISTS "Users can manage their own events" ON public.calendar_events;
CREATE POLICY "Users can manage their own events" ON public.calendar_events
    FOR ALL USING (created_by = auth.uid());

-- Create RLS policies for attendees
DROP POLICY IF EXISTS "Users can manage attendees for their events" ON public.calendar_event_attendees;
CREATE POLICY "Users can manage attendees for their events" ON public.calendar_event_attendees
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.calendar_events 
            WHERE calendar_events.id = calendar_event_attendees.event_id 
            AND calendar_events.created_by = auth.uid()
        )
    );

-- Create RLS policies for reminders
DROP POLICY IF EXISTS "Users can manage reminders for their events" ON public.calendar_event_reminders;
CREATE POLICY "Users can manage reminders for their events" ON public.calendar_event_reminders
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.calendar_events 
            WHERE calendar_events.id = calendar_event_reminders.event_id 
            AND calendar_events.created_by = auth.uid()
        )
    );

-- 4. CREATE FUNCTION TO INITIALIZE USER DATA
-- This function will be called by the application when a user first accesses the calendar
CREATE OR REPLACE FUNCTION initialize_user_calendar_data(user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Insert default calendar if it doesn't exist
    INSERT INTO public.calendars (name, description, color, is_default, created_by)
    SELECT 
        'My Calendar',
        'Default personal calendar',
        '#3B82F6',
        true,
        user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.calendars WHERE created_by = user_id
    );

    -- Insert default categories if they don't exist
    INSERT INTO public.calendar_categories (name, description, color, icon, created_by) 
    SELECT * FROM (VALUES
        ('Meeting', 'Business meetings and calls', '#EF4444', 'users', user_id),
        ('Personal', 'Personal appointments and events', '#10B981', 'user', user_id),
        ('Work', 'Work-related tasks and deadlines', '#F59E0B', 'briefcase', user_id),
        ('Travel', 'Travel and vacation plans', '#8B5CF6', 'plane', user_id),
        ('Health', 'Medical appointments and health', '#EC4899', 'heart', user_id)
    ) AS v(name, description, color, icon, created_by)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.calendar_categories WHERE created_by = user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION initialize_user_calendar_data(UUID) TO authenticated;

-- 5. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_digital_files_uploaded_by ON public.digital_files(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_digital_files_created_at ON public.digital_files(created_at);
CREATE INDEX IF NOT EXISTS idx_calendars_created_by ON public.calendars(created_by);
CREATE INDEX IF NOT EXISTS idx_calendar_events_calendar_id ON public.calendar_events(calendar_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_created_by ON public.calendar_events(created_by);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_time ON public.calendar_events(start_time);

-- Success message
SELECT 'All fixes applied successfully! Both Digital Files and Calendar should now work properly.' as result;
