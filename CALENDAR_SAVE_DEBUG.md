# Calendar Not Saving Appointments - Debug Guide

## Issue
Calendar appointments are not being saved to the database.

## Root Cause Analysis

### 1. Database Connection Issue
The calendar is trying to save to Supabase but may be failing due to:
- Environment variables not properly connected
- Database tables missing
- Authentication issues

### 2. Missing Calendar Tables
Check if these tables exist in your Supabase database:
- `calendars`
- `calendar_events` 
- `calendar_categories`
- `calendar_event_attendees`
- `calendar_event_reminders`

### 3. Authentication Required
Calendar operations require user authentication. Make sure:
- User is properly logged in
- RLS (Row Level Security) policies are configured

## Immediate Solutions

### Solution 1: Check Database Tables
1. Go to your Supabase dashboard
2. Navigate to the Table Editor
3. Verify these tables exist:
   - `calendar_events`
   - `calendars`
   - `calendar_categories`

### Solution 2: Create Missing Tables
If tables are missing, run this SQL in your Supabase SQL Editor:

```sql
-- Create calendars table
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    external_id TEXT,
    external_source TEXT,
    sync_enabled BOOLEAN DEFAULT false,
    sync_url TEXT,
    last_sync TIMESTAMP WITH TIME ZONE
);

-- Create calendar_events table
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    all_day BOOLEAN DEFAULT false,
    timezone TEXT DEFAULT 'UTC',
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'tentative', 'cancelled')),
    visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'confidential')),
    importance TEXT DEFAULT 'normal' CHECK (importance IN ('low', 'normal', 'high')),
    category_id UUID,
    calendar_id UUID REFERENCES public.calendars(id) ON DELETE CASCADE,
    color TEXT DEFAULT '#3B82F6',
    is_recurring BOOLEAN DEFAULT false,
    recurrence_rule TEXT,
    recurrence_exception_dates TEXT[],
    parent_event_id UUID REFERENCES public.calendar_events(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    external_id TEXT,
    external_source TEXT,
    ical_uid TEXT UNIQUE DEFAULT gen_random_uuid()::TEXT,
    is_bookable BOOLEAN DEFAULT false,
    max_attendees INTEGER,
    booking_window_start TIMESTAMP WITH TIME ZONE,
    booking_window_end TIMESTAMP WITH TIME ZONE
);

-- Create calendar_categories table
CREATE TABLE IF NOT EXISTS public.calendar_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#3B82F6',
    icon TEXT,
    is_system BOOLEAN DEFAULT false,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.calendars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_categories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own calendars" ON public.calendars
    FOR SELECT USING (auth.uid() = owner_id OR is_public = true);

CREATE POLICY "Users can create their own calendars" ON public.calendars
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own calendars" ON public.calendars
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own calendars" ON public.calendars
    FOR DELETE USING (auth.uid() = owner_id);

CREATE POLICY "Users can view events in their calendars" ON public.calendar_events
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.calendars 
            WHERE calendars.id = calendar_events.calendar_id 
            AND (calendars.owner_id = auth.uid() OR calendars.is_public = true)
        )
    );

CREATE POLICY "Users can create events in their calendars" ON public.calendar_events
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.calendars 
            WHERE calendars.id = calendar_events.calendar_id 
            AND calendars.owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can update events in their calendars" ON public.calendar_events
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.calendars 
            WHERE calendars.id = calendar_events.calendar_id 
            AND calendars.owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete events in their calendars" ON public.calendar_events
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.calendars 
            WHERE calendars.id = calendar_events.calendar_id 
            AND calendars.owner_id = auth.uid()
        )
    );
```

### Solution 3: Create Default Calendar
After creating tables, create a default calendar:

```sql
-- Insert a default calendar for testing
INSERT INTO public.calendars (name, description, color, is_default, owner_id)
VALUES ('My Calendar', 'Default calendar', '#3B82F6', true, auth.uid());
```

### Solution 4: Test Calendar Functionality
1. Open browser console (F12)
2. Go to calendar page
3. Try creating an appointment
4. Check for error messages in console
5. Look for specific error details

## Common Error Messages

### "Calendar ID is required"
- Default calendar not created
- Calendar selection dropdown empty

### "Authentication required"
- User not logged in
- Session expired

### "Permission denied"
- RLS policies not configured
- User doesn't own the calendar

### "Table doesn't exist"
- Database schema not deployed
- Missing calendar tables

## Next Steps

1. **Check Database**: Verify calendar tables exist
2. **Run SQL**: Execute the table creation SQL above
3. **Test Again**: Try creating a calendar appointment
4. **Check Console**: Look for specific error messages
5. **Debug Further**: If still failing, check network tab for API calls

## Prevention
- Ensure complete database schema is deployed
- Test calendar functionality after each deployment
- Verify user authentication is working
- Check RLS policies are properly configured
