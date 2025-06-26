-- EMERGENCY FIXES FOR DIGITAL FILES AND CALENDAR
-- Run this SQL script in your Supabase dashboard SQL Editor
-- This will fix both the file upload and calendar issues

-- =====================================================
-- 1. CALENDAR SYSTEM COMPLETE FIX
-- =====================================================

-- Create calendar_categories table (this is what's missing!)
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
    calendar_type TEXT DEFAULT 'personal' CHECK (calendar_type IN ('personal', 'shared', 'public')),
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
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'tentative', 'cancelled')),
    visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'confidential')),
    importance TEXT DEFAULT 'normal' CHECK (importance IN ('low', 'normal', 'high')),
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for calendar tables
ALTER TABLE public.calendar_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies for calendar_categories
DROP POLICY IF EXISTS "Users can manage their calendar categories" ON public.calendar_categories;
CREATE POLICY "Users can manage their calendar categories" ON public.calendar_categories
    FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for calendars
DROP POLICY IF EXISTS "Users can manage their calendars" ON public.calendars;
CREATE POLICY "Users can manage their calendars" ON public.calendars
    FOR ALL USING (auth.uid() = owner_id);

-- RLS Policies for calendar_events
DROP POLICY IF EXISTS "Users can manage their calendar events" ON public.calendar_events;
CREATE POLICY "Users can manage their calendar events" ON public.calendar_events
    FOR ALL USING (auth.uid() = user_id);

-- Insert default calendar categories
DO $$
BEGIN
    -- Only insert if no categories exist
    IF NOT EXISTS (SELECT 1 FROM public.calendar_categories LIMIT 1) THEN
        INSERT INTO public.calendar_categories (name, color, description) VALUES
        ('Work', '#3B82F6', 'Work related appointments'),
        ('Personal', '#10B981', 'Personal appointments'),
        ('Appointments', '#F59E0B', 'Client appointments'),
        ('Photography', '#8B5CF6', 'Photography sessions'),
        ('Meetings', '#EF4444', 'Business meetings'),
        ('Events', '#EC4899', 'Special events');
    END IF;
END $$;

-- =====================================================
-- 2. DIGITAL FILES SYSTEM COMPLETE FIX
-- =====================================================

-- Create digital_files table
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
    is_processed BOOLEAN DEFAULT false,
    processing_status TEXT DEFAULT 'pending',
    
    -- Access control
    access_level TEXT DEFAULT 'private' CHECK (access_level IN ('private', 'client', 'public')),
    download_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE
);

-- Create indexes for digital_files
CREATE INDEX IF NOT EXISTS idx_digital_files_uploaded_by ON public.digital_files(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_digital_files_client_id ON public.digital_files(client_id);
CREATE INDEX IF NOT EXISTS idx_digital_files_category ON public.digital_files(category);
CREATE INDEX IF NOT EXISTS idx_digital_files_created_at ON public.digital_files(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_digital_files_is_public ON public.digital_files(is_public);

-- Enable RLS for digital_files
ALTER TABLE public.digital_files ENABLE ROW LEVEL SECURITY;

-- RLS Policies for digital_files
DROP POLICY IF EXISTS "Users can manage their digital files" ON public.digital_files;
CREATE POLICY "Users can manage their digital files" ON public.digital_files
    FOR ALL USING (auth.uid() = uploaded_by);

-- Public files can be viewed by anyone
DROP POLICY IF EXISTS "Public files are viewable by everyone" ON public.digital_files;
CREATE POLICY "Public files are viewable by everyone" ON public.digital_files
    FOR SELECT USING (is_public = true);

-- =====================================================
-- 3. CRM TABLES (ENSURE THEY EXIST)
-- =====================================================

-- Create leads table
CREATE TABLE IF NOT EXISTS public.leads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    source TEXT DEFAULT 'website',
    status TEXT DEFAULT 'NEW' CHECK (status IN ('NEW', 'CONTACTED', 'QUALIFIED', 'CONVERTED', 'LOST')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create crm_clients table
CREATE TABLE IF NOT EXISTS public.crm_clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    company TEXT,
    status TEXT DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'ARCHIVED')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create crm_bookings table
CREATE TABLE IF NOT EXISTS public.crm_bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES public.crm_clients(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    booking_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER DEFAULT 60, -- minutes
    status TEXT DEFAULT 'SCHEDULED' CHECK (status IN ('SCHEDULED', 'CONFIRMED', 'COMPLETED', 'CANCELLED')),
    location TEXT,
    price DECIMAL(10,2),
    deposit_paid BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create crm_invoices table
CREATE TABLE IF NOT EXISTS public.crm_invoices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES public.crm_clients(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES public.crm_bookings(id) ON DELETE SET NULL,
    invoice_number TEXT UNIQUE NOT NULL,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('DRAFT', 'PENDING', 'PAID', 'OVERDUE', 'CANCELLED')),
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    currency TEXT DEFAULT 'EUR',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for CRM tables
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_invoices ENABLE ROW LEVEL SECURITY;

-- RLS Policies for leads
DROP POLICY IF EXISTS "Authenticated users can manage leads" ON public.leads;
CREATE POLICY "Authenticated users can manage leads" ON public.leads
    FOR ALL USING (auth.role() = 'authenticated');

-- RLS Policies for crm_clients
DROP POLICY IF EXISTS "Authenticated users can manage clients" ON public.crm_clients;
CREATE POLICY "Authenticated users can manage clients" ON public.crm_clients
    FOR ALL USING (auth.role() = 'authenticated');

-- RLS Policies for crm_bookings
DROP POLICY IF EXISTS "Authenticated users can manage bookings" ON public.crm_bookings;
CREATE POLICY "Authenticated users can manage bookings" ON public.crm_bookings
    FOR ALL USING (auth.role() = 'authenticated');

-- RLS Policies for crm_invoices
DROP POLICY IF EXISTS "Authenticated users can manage invoices" ON public.crm_invoices;
CREATE POLICY "Authenticated users can manage invoices" ON public.crm_invoices
    FOR ALL USING (auth.role() = 'authenticated');

-- =====================================================
-- 4. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Calendar indexes
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_id ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_time ON public.calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_calendar_id ON public.calendar_events(calendar_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_category_id ON public.calendar_events(category_id);

-- CRM indexes
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON public.leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_status ON public.leads(status);
CREATE INDEX IF NOT EXISTS idx_crm_clients_created_at ON public.crm_clients(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_crm_bookings_client_id ON public.crm_bookings(client_id);
CREATE INDEX IF NOT EXISTS idx_crm_bookings_booking_date ON public.crm_bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_crm_invoices_client_id ON public.crm_invoices(client_id);

-- =====================================================
-- 5. SUMMARY
-- =====================================================

-- This script creates:
-- ✅ calendar_categories table (fixes calendar error)
-- ✅ calendars table
-- ✅ calendar_events table with proper relationships
-- ✅ digital_files table (for file uploads)
-- ✅ All CRM tables (leads, clients, bookings, invoices)
-- ✅ All RLS policies for security
-- ✅ All indexes for performance
-- ✅ Default calendar categories

-- AFTER RUNNING THIS SQL:
-- 1. Create the 'digital-files' storage bucket in Supabase Storage
-- 2. Test file uploads in Digital Files page
-- 3. Test calendar functionality
-- 4. All CRM features should work properly

SELECT 'SUCCESS: All tables and policies created! Now create the digital-files storage bucket.' AS status;
