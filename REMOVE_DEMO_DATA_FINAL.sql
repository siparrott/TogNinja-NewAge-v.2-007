-- CRITICAL: Remove ALL Demo Data and Fix Calendar Database
-- Run this in your Supabase SQL Editor to fix both calendar and remove demo data

-- 1. CLEAN UP DEMO DATA
DELETE FROM calendar_events WHERE 
    title LIKE '%Demo%' OR 
    title LIKE '%Sample%' OR
    title LIKE '%Wedding Photoshoot%' OR
    title LIKE '%Client Consultation%' OR
    title LIKE '%Photo Delivery%' OR
    title LIKE '%test%' OR
    title LIKE '%Test%';

DELETE FROM calendars WHERE 
    name LIKE '%Demo%' OR 
    name LIKE '%Sample%' OR
    name LIKE '%Test%';

-- 2. ENSURE CALENDAR TABLES EXIST
CREATE TABLE IF NOT EXISTS public.calendars (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    is_default BOOLEAN DEFAULT false,
    is_public BOOLEAN DEFAULT false,
    timezone TEXT DEFAULT 'UTC',
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    all_day BOOLEAN DEFAULT false,
    timezone TEXT DEFAULT 'UTC',
    status TEXT DEFAULT 'confirmed',
    visibility TEXT DEFAULT 'public',
    importance TEXT DEFAULT 'normal',
    calendar_id UUID REFERENCES public.calendars(id) ON DELETE CASCADE,
    color TEXT DEFAULT '#3B82F6',
    is_recurring BOOLEAN DEFAULT false,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.calendar_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    color TEXT DEFAULT '#3B82F6',
    icon TEXT,
    is_system BOOLEAN DEFAULT false,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. ENABLE ROW LEVEL SECURITY
ALTER TABLE public.calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_categories ENABLE ROW LEVEL SECURITY;

-- 4. DROP EXISTING POLICIES (if any)
DROP POLICY IF EXISTS "Users can manage their calendars" ON public.calendars;
DROP POLICY IF EXISTS "Users can manage their events" ON public.calendar_events;
DROP POLICY IF EXISTS "Users can manage their categories" ON public.calendar_categories;

-- 5. CREATE SIMPLE POLICIES
CREATE POLICY "Users can manage their calendars" ON public.calendars
    FOR ALL USING (auth.uid() = owner_id OR is_public = true);

CREATE POLICY "Users can manage their events" ON public.calendar_events
    FOR ALL USING (
        created_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.calendars 
            WHERE calendars.id = calendar_events.calendar_id 
            AND (calendars.owner_id = auth.uid() OR calendars.is_public = true)
        )
    );

CREATE POLICY "Users can manage their categories" ON public.calendar_categories
    FOR ALL USING (auth.uid() = owner_id OR is_system = true);

-- 6. CREATE DEFAULT CALENDAR FOR CURRENT USER
INSERT INTO public.calendars (name, description, color, is_default, owner_id)
VALUES ('Business Calendar', 'Main business calendar', '#3B82F6', true, auth.uid())
ON CONFLICT DO NOTHING;

-- 7. ADD BASIC CATEGORIES
INSERT INTO public.calendar_categories (name, color, icon, is_system) VALUES
('Appointment', '#3B82F6', 'calendar', true),
('Photoshoot', '#10B981', 'camera', true),
('Consultation', '#F59E0B', 'users', true),
('Meeting', '#EF4444', 'video', true),
('Delivery', '#8B5CF6', 'package', true)
ON CONFLICT DO NOTHING;

-- 8. CLEAN UP ANY OTHER DEMO TABLES
DELETE FROM clients WHERE name LIKE '%Demo%' OR name LIKE '%Sample%' OR name LIKE '%Test%';
DELETE FROM invoices WHERE client_name LIKE '%Demo%' OR client_name LIKE '%Sample%';
DELETE FROM leads WHERE name LIKE '%Demo%' OR name LIKE '%Sample%';

-- 9. VERIFY TABLES EXIST
SELECT 'calendars' as table_name, count(*) as row_count FROM calendars
UNION ALL
SELECT 'calendar_events' as table_name, count(*) as row_count FROM calendar_events
UNION ALL  
SELECT 'calendar_categories' as table_name, count(*) as row_count FROM calendar_categories;
