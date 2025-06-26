-- CALENDAR AND INVOICE FIXES
-- Run this SQL in your Supabase dashboard to fix reported issues

-- =====================================================
-- 1. FIX CALENDAR RELATIONSHIP ERROR
-- =====================================================

-- Create calendar_events table if missing
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    calendar_id UUID,
    category_id UUID,
    color TEXT DEFAULT '#3B82F6',
    is_recurring BOOLEAN DEFAULT false,
    recurrence_rule TEXT,
    recurrence_exception_dates TEXT[],
    parent_event_id UUID REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    external_id TEXT,
    external_source TEXT
);

-- Create calendars table if missing (this fixes the relationship error)
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

-- Add foreign key relationship (this is what was missing!)
-- First check if the column exists, if not add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'calendar_events' 
        AND column_name = 'calendar_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.calendar_events ADD COLUMN calendar_id UUID;
    END IF;
END $$;

-- Now add the foreign key constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'calendar_events_calendar_id_fkey' 
        AND table_name = 'calendar_events'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.calendar_events 
        ADD CONSTRAINT calendar_events_calendar_id_fkey 
        FOREIGN KEY (calendar_id) REFERENCES public.calendars(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Create calendar categories table
CREATE TABLE IF NOT EXISTS public.calendar_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    color TEXT DEFAULT '#3B82F6',
    description TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_categories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can manage their calendar events" ON public.calendar_events;
CREATE POLICY "Users can manage their calendar events" ON public.calendar_events
    FOR ALL USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their calendars" ON public.calendars;
CREATE POLICY "Users can manage their calendars" ON public.calendars
    FOR ALL USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their calendar categories" ON public.calendar_categories;
CREATE POLICY "Users can manage their calendar categories" ON public.calendar_categories
    FOR ALL USING (user_id = auth.uid());

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_id ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_calendar_id ON public.calendar_events(calendar_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_time ON public.calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_status ON public.calendar_events(status);
CREATE INDEX IF NOT EXISTS idx_calendars_owner_id ON public.calendars(owner_id);

-- Insert default calendar for current user
INSERT INTO public.calendars (name, description, color, is_default, owner_id)
VALUES ('My Calendar', 'Default personal calendar', '#3B82F6', true, auth.uid())
ON CONFLICT DO NOTHING;

-- =====================================================
-- 2. REMOVE SAMPLE/DEMO CLIENTS FROM INVOICES
-- =====================================================

-- Delete demo/sample clients that appear in invoice dropdowns
DELETE FROM public.crm_clients 
WHERE LOWER(name) LIKE '%demo%' 
   OR LOWER(name) LIKE '%sample%' 
   OR LOWER(name) LIKE '%test%'
   OR LOWER(email) LIKE '%demo%'
   OR LOWER(email) LIKE '%sample%'
   OR LOWER(email) LIKE '%test%'
   OR LOWER(email) LIKE '%example.com%'
   OR name = 'John Doe'
   OR name = 'Jane Smith'
   OR name = 'Test Client'
   OR name = 'Sample Client'
   OR name = 'Demo Client';

-- Delete related invoices for demo clients
DELETE FROM public.invoices 
WHERE LOWER(client_name) LIKE '%demo%' 
   OR LOWER(client_name) LIKE '%sample%' 
   OR LOWER(client_name) LIKE '%test%'
   OR client_name = 'John Doe'
   OR client_name = 'Jane Smith'
   OR client_name = 'Test Client'
   OR client_name = 'Sample Client'
   OR client_name = 'Demo Client';

-- Delete related bookings for demo clients
DELETE FROM public.bookings 
WHERE LOWER(client_name) LIKE '%demo%' 
   OR LOWER(client_name) LIKE '%sample%' 
   OR LOWER(client_name) LIKE '%test%'
   OR client_name = 'John Doe'
   OR client_name = 'Jane Smith'
   OR client_name = 'Test Client'
   OR client_name = 'Sample Client'
   OR client_name = 'Demo Client';

-- =====================================================
-- 3. CREATE MISSING INVOICE TABLES (if needed)
-- =====================================================

-- Ensure invoices table exists with proper structure
CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    invoice_number TEXT UNIQUE NOT NULL,
    client_id UUID,
    client_name TEXT NOT NULL,
    client_email TEXT,
    client_address TEXT,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
    currency TEXT DEFAULT 'EUR',
    subtotal DECIMAL(10,2) DEFAULT 0,
    tax_rate DECIMAL(5,2) DEFAULT 19,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    terms TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    paid_at TIMESTAMP WITH TIME ZONE
);

-- Create invoice items table
CREATE TABLE IF NOT EXISTS public.invoice_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    invoice_id UUID REFERENCES public.invoices(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for invoices
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for invoices
DROP POLICY IF EXISTS "Users can manage their invoices" ON public.invoices;
CREATE POLICY "Users can manage their invoices" ON public.invoices
    FOR ALL USING (created_by = auth.uid());

DROP POLICY IF EXISTS "Users can manage invoice items" ON public.invoice_items;
CREATE POLICY "Users can manage invoice items" ON public.invoice_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.invoices 
            WHERE invoices.id = invoice_items.invoice_id 
            AND invoices.created_by = auth.uid()
        )
    );

-- Create indexes for invoices
CREATE INDEX IF NOT EXISTS idx_invoices_created_by ON public.invoices(created_by);
CREATE INDEX IF NOT EXISTS idx_invoices_client_id ON public.invoices(client_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON public.invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON public.invoice_items(invoice_id);

-- =====================================================
-- 4. VERIFICATION QUERIES
-- =====================================================

-- Check if calendar relationship is fixed
SELECT 
    'Calendar relationship check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'calendar_events_calendar_id_fkey'
        ) THEN 'FIXED - Foreign key relationship exists'
        ELSE 'ERROR - Foreign key relationship missing'
    END as status;

-- Check if demo clients are removed
SELECT 
    'Demo clients check' as check_type,
    CASE 
        WHEN count(*) = 0 THEN 'FIXED - No demo clients found'
        ELSE CONCAT('WARNING - ', count(*), ' demo clients still exist')
    END as status
FROM public.crm_clients 
WHERE LOWER(name) LIKE '%demo%' 
   OR LOWER(name) LIKE '%sample%' 
   OR LOWER(name) LIKE '%test%';

-- Check tables exist
SELECT 
    'Required tables check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'calendar_events')
         AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'calendars')
         AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'invoices')
        THEN 'FIXED - All required tables exist'
        ELSE 'ERROR - Some tables missing'
    END as status;

-- Summary message
SELECT 'SETUP COMPLETE' as message, 
       'Calendar relationships fixed, demo data removed, tables verified' as details;
