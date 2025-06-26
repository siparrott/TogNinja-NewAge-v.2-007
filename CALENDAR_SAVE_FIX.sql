-- CRITICAL FIX: Calendar Save Issue
-- This creates a default calendar and ensures users can save appointments

-- Step 1: Create a default calendar for all users (run this first)
INSERT INTO public.calendars (name, description, color, is_default, is_public, owner_id)
SELECT 'My Calendar', 'Default personal calendar', '#3B82F6', true, false, auth.uid()
WHERE NOT EXISTS (
  SELECT 1 FROM public.calendars 
  WHERE owner_id = auth.uid() AND is_default = true
);

-- Step 2: Create a system-wide default calendar (for demo/testing)
INSERT INTO public.calendars (id, name, description, color, is_default, is_public, owner_id)
VALUES (
  'default-calendar-uuid',
  'Default Calendar', 
  'System default calendar for all users', 
  '#3B82F6', 
  true, 
  true,
  (SELECT id FROM auth.users LIMIT 1)
) ON CONFLICT (id) DO NOTHING;

-- Step 3: Ensure calendar_events table allows NULL calendar_id temporarily
ALTER TABLE public.calendar_events 
ALTER COLUMN calendar_id DROP NOT NULL;

-- Step 4: Add a trigger to auto-assign default calendar if none specified
CREATE OR REPLACE FUNCTION assign_default_calendar()
RETURNS TRIGGER AS $$
BEGIN
  -- If no calendar_id is provided, use the user's default calendar
  IF NEW.calendar_id IS NULL THEN
    SELECT id INTO NEW.calendar_id 
    FROM public.calendars 
    WHERE owner_id = auth.uid() AND is_default = true
    LIMIT 1;
    
    -- If user has no default calendar, create one
    IF NEW.calendar_id IS NULL THEN
      INSERT INTO public.calendars (name, description, color, is_default, owner_id)
      VALUES ('My Calendar', 'Auto-created default calendar', '#3B82F6', true, auth.uid())
      RETURNING id INTO NEW.calendar_id;
    END IF;
  END IF;
  
  -- Ensure created_by is set
  IF NEW.created_by IS NULL THEN
    NEW.created_by = auth.uid();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply the trigger
DROP TRIGGER IF EXISTS auto_assign_calendar ON public.calendar_events;
CREATE TRIGGER auto_assign_calendar
  BEFORE INSERT ON public.calendar_events
  FOR EACH ROW
  EXECUTE FUNCTION assign_default_calendar();

-- Step 5: Create a simplified RLS policy for calendar events
DROP POLICY IF EXISTS "Simplified calendar events access" ON public.calendar_events;
CREATE POLICY "Simplified calendar events access" 
  ON public.calendar_events 
  FOR ALL 
  USING (
    -- User owns the calendar OR calendar is public OR user created the event
    EXISTS (
      SELECT 1 FROM public.calendars c 
      WHERE c.id = calendar_events.calendar_id 
      AND (c.owner_id = auth.uid() OR c.is_public = true)
    )
    OR created_by = auth.uid()
  )
  WITH CHECK (
    -- User can create events in calendars they own OR public calendars
    EXISTS (
      SELECT 1 FROM public.calendars c 
      WHERE c.id = calendar_events.calendar_id 
      AND (c.owner_id = auth.uid() OR c.is_public = true)
    )
  );

-- Step 6: Create sample calendar categories
INSERT INTO public.calendar_categories (name, color, icon, is_system) VALUES
('Work', '#EF4444', 'briefcase', true),
('Personal', '#3B82F6', 'user', true),
('Meeting', '#10B981', 'users', true),
('Appointment', '#F59E0B', 'calendar', true),
('Event', '#8B5CF6', 'star', true)
ON CONFLICT DO NOTHING;
