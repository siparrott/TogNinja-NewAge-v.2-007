-- QUICK CALENDAR FIX - Run this immediately in Supabase SQL Editor
-- This creates the minimum required tables for calendar events to save

-- Create calendar_categories table (this is causing the "No calendar available" issue)
CREATE TABLE IF NOT EXISTS public.calendar_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    color TEXT DEFAULT '#3B82F6',
    description TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create calendars table 
CREATE TABLE IF NOT EXISTS public.calendars (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    timezone TEXT DEFAULT 'UTC',
    is_default BOOLEAN DEFAULT false,
    is_visible BOOLEAN DEFAULT true,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    calendar_type TEXT DEFAULT 'personal',
    settings JSONB DEFAULT '{}'::jsonb
);

-- Create calendar_events table
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    all_day BOOLEAN DEFAULT false,
    timezone TEXT DEFAULT 'UTC',
    status TEXT DEFAULT 'confirmed',
    visibility TEXT DEFAULT 'public',
    importance TEXT DEFAULT 'normal',
    location TEXT,
    event_type TEXT DEFAULT 'appointment',
    client_name TEXT,
    client_id UUID,
    booking_id UUID,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    calendar_id UUID REFERENCES public.calendars(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.calendar_categories(id) ON DELETE SET NULL,
    color TEXT DEFAULT '#3B82F6',
    is_recurring BOOLEAN DEFAULT false,
    recurrence_rule TEXT,
    recurrence_exception_dates TEXT[],
    parent_event_id UUID REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    external_id TEXT,
    external_source TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ical_uid TEXT,
    is_bookable BOOLEAN DEFAULT false,
    max_attendees INTEGER,
    booking_window_start TIMESTAMP WITH TIME ZONE,
    booking_window_end TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE public.calendar_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can manage their calendar categories" ON public.calendar_categories
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their calendars" ON public.calendars
    FOR ALL USING (auth.uid() = owner_id);

CREATE POLICY "Users can manage their calendar events" ON public.calendar_events
    FOR ALL USING (auth.uid() = user_id OR auth.uid() = created_by);

-- Insert default data so dropdowns work
INSERT INTO public.calendar_categories (name, color, description) VALUES
    ('Work', '#3B82F6', 'Work related appointments'),
    ('Personal', '#10B981', 'Personal appointments'),
    ('Photography', '#8B5CF6', 'Photography sessions'),
    ('Meetings', '#EF4444', 'Business meetings'),
    ('Events', '#EC4899', 'Special events')
ON CONFLICT DO NOTHING;

-- Insert default calendar for current user
DO $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get current user ID
    SELECT auth.uid() INTO current_user_id;
    
    -- Only insert if we have a user and no calendars exist
    IF current_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.calendars WHERE owner_id = current_user_id) THEN
        INSERT INTO public.calendars (name, description, color, is_default, owner_id) VALUES
            ('My Calendar', 'Default calendar', '#3B82F6', true, current_user_id);
    END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_id ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_time ON public.calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_calendar_id ON public.calendar_events(calendar_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_category_id ON public.calendar_events(category_id);

SELECT 'SUCCESS: Calendar tables created! Events should now save properly.' AS status;
