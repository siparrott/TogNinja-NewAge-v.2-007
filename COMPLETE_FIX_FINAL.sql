-- COMPLETE FIX FOR STORAGE AND CALENDAR ISSUES
-- Run this in Supabase SQL Editor

-- 1. DROP EXISTING STORAGE POLICIES (if they exist but aren't working)
DROP POLICY IF EXISTS "Users can upload their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own files" ON storage.objects;

-- 2. CREATE CORRECTED STORAGE POLICIES
CREATE POLICY "Users can upload their own files" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'digital-files' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view their own files" ON storage.objects
    FOR SELECT USING (bucket_id = 'digital-files' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own files" ON storage.objects
    FOR UPDATE USING (bucket_id = 'digital-files' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own files" ON storage.objects
    FOR DELETE USING (bucket_id = 'digital-files' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 3. ADD MISSING ICON COLUMN TO CALENDAR CATEGORIES
ALTER TABLE public.calendar_categories ADD COLUMN IF NOT EXISTS icon TEXT;

-- 4. FORCE INSERT DEFAULT CALENDAR DATA
DELETE FROM public.calendar_categories WHERE created_by = auth.uid();
INSERT INTO public.calendar_categories (name, color, description, icon, created_by)
VALUES 
    ('Photography Session', '#10B981', 'Photo shoots and sessions', '📸', auth.uid()),
    ('Sales Meeting', '#F59E0B', 'In-person sales consultations', '💼', auth.uid()),
    ('General', '#3B82F6', 'Other appointments', '📅', auth.uid());

DELETE FROM public.calendars WHERE owner_id = auth.uid();
INSERT INTO public.calendars (name, color, description, is_default, owner_id)
VALUES 
    ('Shoot', '#10B981', 'Photography sessions and shoots', true, auth.uid()),
    ('In Person Sale', '#F59E0B', 'In-person sales appointments', false, auth.uid());
