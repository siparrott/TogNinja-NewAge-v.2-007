-- CALENDAR LOADING FIX
-- The calendars were created but aren't loading in the frontend
-- This will check and fix the calendar loading issue

-- First, let's check if the calendars actually exist
SELECT 'Checking calendars:' as step;
SELECT * FROM public.calendars WHERE owner_id = auth.uid();

-- Check if categories exist
SELECT 'Checking categories:' as step;
SELECT * FROM public.calendar_categories WHERE created_by = auth.uid();

-- If no results above, force recreate them
DO $$
BEGIN
    -- Delete any existing data for this user
    DELETE FROM public.calendars WHERE owner_id = auth.uid();
    DELETE FROM public.calendar_categories WHERE created_by = auth.uid();
    
    -- Insert categories with current user ID
    INSERT INTO public.calendar_categories (id, name, color, description, icon, created_by, created_at)
    VALUES 
        (gen_random_uuid(), 'Photography Session', '#10B981', 'Photo shoots and sessions', '📸', auth.uid(), NOW()),
        (gen_random_uuid(), 'Sales Meeting', '#F59E0B', 'In-person sales consultations', '💼', auth.uid(), NOW()),
        (gen_random_uuid(), 'General', '#3B82F6', 'Other appointments', '📅', auth.uid(), NOW());
    
    -- Insert calendars with current user ID
    INSERT INTO public.calendars (id, name, color, description, is_default, owner_id, created_at, updated_at)
    VALUES 
        (gen_random_uuid(), 'Shoot', '#10B981', 'Photography sessions and shoots', true, auth.uid(), NOW(), NOW()),
        (gen_random_uuid(), 'In Person Sale', '#F59E0B', 'In-person sales appointments', false, auth.uid(), NOW(), NOW());
END $$;

-- Verify the data was inserted
SELECT 'Final check - Calendars:' as step;
SELECT id, name, color, is_default, owner_id FROM public.calendars WHERE owner_id = auth.uid();

SELECT 'Final check - Categories:' as step;
SELECT id, name, color, icon, created_by FROM public.calendar_categories WHERE created_by = auth.uid();
