/*
  # Next-Generation Calendar System
  
  This migration creates a comprehensive calendar system with:
  - Advanced event management
  - Recurring events with complex patterns
  - Multiple calendar support
  - Timezone handling
  - Event categories and colors
  - Attendee management
  - iCal integration
  - Reminders and notifications
  - Availability and booking slots
*/

-- Events table (enhanced)
CREATE TABLE IF NOT EXISTS calendar_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  location text,
  start_time timestamptz NOT NULL,
  end_time timestamptz NOT NULL,
  all_day boolean DEFAULT false,
  timezone text DEFAULT 'UTC',
  
  -- Event metadata
  status text DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'tentative', 'cancelled')),
  visibility text DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'confidential')),
  importance text DEFAULT 'normal' CHECK (importance IN ('low', 'normal', 'high')),
  
  -- Categorization
  category_id uuid REFERENCES calendar_categories(id) ON DELETE SET NULL,
  calendar_id uuid REFERENCES calendars(id) ON DELETE CASCADE NOT NULL,
  color text DEFAULT '#3B82F6',
  
  -- Recurrence
  is_recurring boolean DEFAULT false,
  recurrence_rule text, -- RRULE format
  recurrence_exception_dates text[], -- Array of exception dates
  parent_event_id uuid REFERENCES calendar_events(id) ON DELETE CASCADE, -- For recurring event instances
  
  -- Metadata
  created_by uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- External integration
  external_id text, -- For syncing with external calendars
  external_source text, -- 'google', 'outlook', 'ical', etc.
  ical_uid text UNIQUE,
  
  -- Booking and availability
  is_bookable boolean DEFAULT false,
  max_attendees integer,
  booking_window_start interval, -- How far in advance booking opens
  booking_window_end interval, -- How far in advance booking closes
  
  CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

-- Calendars table (for multiple calendar support)
CREATE TABLE IF NOT EXISTS calendars (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  color text DEFAULT '#3B82F6',
  is_default boolean DEFAULT false,
  is_public boolean DEFAULT false,
  timezone text DEFAULT 'UTC',
  
  -- Permissions
  owner_id uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- External integration
  external_id text,
  external_source text,
  sync_enabled boolean DEFAULT false,
  sync_url text,
  last_sync timestamptz
);

-- Event categories
CREATE TABLE IF NOT EXISTS calendar_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  color text DEFAULT '#6B7280',
  icon text,
  created_by uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Event attendees
CREATE TABLE IF NOT EXISTS calendar_event_attendees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid REFERENCES calendar_events(id) ON DELETE CASCADE NOT NULL,
  email text NOT NULL,
  name text,
  role text DEFAULT 'attendee' CHECK (role IN ('organizer', 'attendee', 'optional')),
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'tentative')),
  response_date timestamptz,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Event reminders
CREATE TABLE IF NOT EXISTS calendar_event_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid REFERENCES calendar_events(id) ON DELETE CASCADE NOT NULL,
  type text DEFAULT 'email' CHECK (type IN ('email', 'popup', 'sms', 'push')),
  minutes_before integer NOT NULL,
  sent_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Calendar sharing and permissions
CREATE TABLE IF NOT EXISTS calendar_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  calendar_id uuid REFERENCES calendars(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  permission text DEFAULT 'read' CHECK (permission IN ('read', 'write', 'admin')),
  granted_by uuid REFERENCES auth.users(id) NOT NULL,
  granted_at timestamptz DEFAULT now(),
  
  UNIQUE(calendar_id, user_id)
);

-- Availability slots (for booking)
CREATE TABLE IF NOT EXISTS calendar_availability (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  calendar_id uuid REFERENCES calendars(id) ON DELETE CASCADE NOT NULL,
  day_of_week integer CHECK (day_of_week BETWEEN 0 AND 6), -- 0 = Sunday
  start_time time NOT NULL,
  end_time time NOT NULL,
  timezone text DEFAULT 'UTC',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  
  CONSTRAINT valid_availability_time CHECK (end_time > start_time)
);

-- Event attachments
CREATE TABLE IF NOT EXISTS calendar_event_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid REFERENCES calendar_events(id) ON DELETE CASCADE NOT NULL,
  filename text NOT NULL,
  file_url text NOT NULL,
  file_size integer,
  mime_type text,
  uploaded_by uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_time ON calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_end_time ON calendar_events(end_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_calendar_id ON calendar_events(calendar_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_created_by ON calendar_events(created_by);
CREATE INDEX IF NOT EXISTS idx_calendar_events_recurrence ON calendar_events(is_recurring, parent_event_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_ical_uid ON calendar_events(ical_uid);
CREATE INDEX IF NOT EXISTS idx_calendar_attendees_event_id ON calendar_event_attendees(event_id);
CREATE INDEX IF NOT EXISTS idx_calendar_attendees_email ON calendar_event_attendees(email);
CREATE INDEX IF NOT EXISTS idx_calendar_permissions_calendar_user ON calendar_permissions(calendar_id, user_id);

-- Enable RLS on all tables
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_event_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_event_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_event_attachments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for calendar_events
CREATE POLICY "Users can view events from calendars they have access to" 
  ON calendar_events FOR SELECT 
  USING (
    calendar_id IN (
      SELECT c.id FROM calendars c 
      WHERE c.owner_id = auth.uid() 
      OR c.is_public = true
      OR EXISTS (
        SELECT 1 FROM calendar_permissions cp 
        WHERE cp.calendar_id = c.id AND cp.user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can create events in calendars they own or have write access to" 
  ON calendar_events FOR INSERT 
  WITH CHECK (
    calendar_id IN (
      SELECT c.id FROM calendars c 
      WHERE c.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM calendar_permissions cp 
        WHERE cp.calendar_id = c.id 
        AND cp.user_id = auth.uid() 
        AND cp.permission IN ('write', 'admin')
      )
    )
  );

CREATE POLICY "Users can update events they created or have write access to" 
  ON calendar_events FOR UPDATE 
  USING (
    created_by = auth.uid() 
    OR calendar_id IN (
      SELECT c.id FROM calendars c 
      WHERE c.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM calendar_permissions cp 
        WHERE cp.calendar_id = c.id 
        AND cp.user_id = auth.uid() 
        AND cp.permission IN ('write', 'admin')
      )
    )
  );

CREATE POLICY "Users can delete events they created or have write access to" 
  ON calendar_events FOR DELETE 
  USING (
    created_by = auth.uid() 
    OR calendar_id IN (
      SELECT c.id FROM calendars c 
      WHERE c.owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM calendar_permissions cp 
        WHERE cp.calendar_id = c.id 
        AND cp.user_id = auth.uid() 
        AND cp.permission IN ('write', 'admin')
      )
    )
  );

-- RLS Policies for calendars
CREATE POLICY "Users can view calendars they own, have access to, or are public" 
  ON calendars FOR SELECT 
  USING (
    owner_id = auth.uid() 
    OR is_public = true
    OR EXISTS (
      SELECT 1 FROM calendar_permissions cp 
      WHERE cp.calendar_id = id AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create their own calendars" 
  ON calendars FOR INSERT 
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update calendars they own" 
  ON calendars FOR UPDATE 
  USING (owner_id = auth.uid());

CREATE POLICY "Users can delete calendars they own" 
  ON calendars FOR DELETE 
  USING (owner_id = auth.uid());

-- RLS Policies for other tables
CREATE POLICY "Users can view categories they created" 
  ON calendar_categories FOR ALL 
  USING (created_by = auth.uid());

CREATE POLICY "Users can manage attendees for events they have access to" 
  ON calendar_event_attendees FOR ALL 
  USING (
    event_id IN (
      SELECT e.id FROM calendar_events e
      JOIN calendars c ON e.calendar_id = c.id
      WHERE c.owner_id = auth.uid()
      OR e.created_by = auth.uid()
      OR EXISTS (
        SELECT 1 FROM calendar_permissions cp 
        WHERE cp.calendar_id = c.id 
        AND cp.user_id = auth.uid() 
        AND cp.permission IN ('write', 'admin')
      )
    )
  );

-- Similar policies for other tables...
CREATE POLICY "Users can manage reminders for their events" 
  ON calendar_event_reminders FOR ALL 
  USING (
    event_id IN (
      SELECT e.id FROM calendar_events e
      WHERE e.created_by = auth.uid()
    )
  );

CREATE POLICY "Calendar owners can manage permissions" 
  ON calendar_permissions FOR ALL 
  USING (
    calendar_id IN (
      SELECT c.id FROM calendars c WHERE c.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage availability for their calendars" 
  ON calendar_availability FOR ALL 
  USING (
    calendar_id IN (
      SELECT c.id FROM calendars c WHERE c.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage attachments for their events" 
  ON calendar_event_attachments FOR ALL 
  USING (
    event_id IN (
      SELECT e.id FROM calendar_events e
      WHERE e.created_by = auth.uid()
    )
  );

-- Functions for recurring events
CREATE OR REPLACE FUNCTION generate_recurring_events(
  base_event_id uuid,
  start_date date,
  end_date date
) RETURNS SETOF calendar_events AS $$
DECLARE
  base_event calendar_events%ROWTYPE;
  generated_event calendar_events%ROWTYPE;
  occurrence_date date;
BEGIN
  -- Get the base event
  SELECT * INTO base_event FROM calendar_events WHERE id = base_event_id;
  
  IF NOT base_event.is_recurring THEN
    RETURN;
  END IF;
  
  -- Simple daily recurrence (extend this for full RRULE support)
  IF base_event.recurrence_rule LIKE '%FREQ=DAILY%' THEN
    occurrence_date := start_date;
    WHILE occurrence_date <= end_date LOOP
      -- Create event instance
      generated_event := base_event;
      generated_event.id := gen_random_uuid();
      generated_event.parent_event_id := base_event_id;
      generated_event.start_time := occurrence_date + (base_event.start_time::time);
      generated_event.end_time := occurrence_date + (base_event.end_time::time);
      
      RETURN NEXT generated_event;
      occurrence_date := occurrence_date + interval '1 day';
    END LOOP;
  END IF;
  
  -- Add more recurrence patterns as needed
END;
$$ LANGUAGE plpgsql;

-- Function to generate iCal UID
CREATE OR REPLACE FUNCTION generate_ical_uid() RETURNS text AS $$
BEGIN
  RETURN gen_random_uuid()::text || '@' || current_setting('app.settings.domain', true);
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate iCal UID
CREATE OR REPLACE FUNCTION set_ical_uid() RETURNS trigger AS $$
BEGIN
  IF NEW.ical_uid IS NULL THEN
    NEW.ical_uid := generate_ical_uid();
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_ical_uid_trigger
  BEFORE INSERT OR UPDATE ON calendar_events
  FOR EACH ROW EXECUTE FUNCTION set_ical_uid();

-- Insert default calendar for users
CREATE OR REPLACE FUNCTION create_default_calendar_for_user() RETURNS trigger AS $$
BEGIN
  INSERT INTO calendars (name, owner_id, is_default, color)
  VALUES ('My Calendar', NEW.id, true, '#3B82F6');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Insert default categories
INSERT INTO calendar_categories (name, description, color, icon, created_by) 
SELECT 
  unnest(ARRAY['Work', 'Personal', 'Meeting', 'Appointment', 'Reminder', 'Holiday']),
  unnest(ARRAY['Work related events', 'Personal events', 'Meetings and calls', 'Appointments', 'Reminders', 'Holidays and special days']),
  unnest(ARRAY['#EF4444', '#10B981', '#F59E0B', '#8B5CF6', '#06B6D4', '#F97316']),
  unnest(ARRAY['briefcase', 'user', 'users', 'calendar', 'bell', 'gift']),
  (SELECT id FROM auth.users LIMIT 1)
WHERE EXISTS (SELECT 1 FROM auth.users LIMIT 1)
ON CONFLICT DO NOTHING;
