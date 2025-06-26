-- CALENDAR DEFAULT DATA FIX
-- Run this in Supabase SQL Editor to fix "No calendar available" error

-- Force insert default calendar category for current user
DELETE FROM public.calendar_categories WHERE created_by = auth.uid();
INSERT INTO public.calendar_categories (name, color, description, created_by)
VALUES ('General', '#3B82F6', 'Default category for events', auth.uid());

-- Force insert default calendar for current user
DELETE FROM public.calendars WHERE owner_id = auth.uid();
INSERT INTO public.calendars (name, color, description, is_default, owner_id)
VALUES ('My Calendar', '#3B82F6', 'Default personal calendar', true, auth.uid());
