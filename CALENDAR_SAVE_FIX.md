# IMMEDIATE CALENDAR FIX - Events Not Saving

## Problem:
- Calendar events don't save
- "No calendar available" message
- Empty category dropdown

## Root Cause:
Missing database tables: `calendar_categories`, `calendars`, `calendar_events`

## IMMEDIATE FIX (60 seconds):

### Step 1: Run SQL in Supabase
1. **Go to your Supabase Dashboard**
2. **Click "SQL Editor"** in the left sidebar
3. **Copy and paste** the entire content of `QUICK_CALENDAR_FIX.sql`
4. **Click "Run"**

### Step 2: Test Calendar
1. **Refresh the calendar page**: `/admin/calendar`
2. **Click "New Event"**
3. **You should now see**:
   - ✅ Calendar dropdown populated
   - ✅ Category dropdown populated
   - ✅ Events save successfully

## What the SQL Script Does:
- ✅ Creates `calendar_categories` table
- ✅ Creates `calendars` table  
- ✅ Creates `calendar_events` table
- ✅ Adds security policies (RLS)
- ✅ Inserts default categories
- ✅ Creates default calendar for your user
- ✅ Adds performance indexes

## Expected Results After Fix:
- ✅ **Calendar dropdown**: Shows "My Calendar"
- ✅ **Category dropdown**: Shows "Work, Personal, Photography, Meetings, Events"
- ✅ **Event creation**: Works without errors
- ✅ **Event display**: Shows saved events on calendar
- ✅ **Event editing**: Can modify existing events

## Test Scenario:
1. Create new event: "Test Meeting"
2. Set date/time: Today 2:00 PM - 3:00 PM
3. Select calendar: "My Calendar" 
4. Select category: "Work"
5. Click "Create Event"
6. **Result**: Event should appear on calendar

## If Still Not Working:
Check browser console (F12) for specific error messages and let me know.

## Complete Database Setup:
For full CRM functionality, also run `EMERGENCY_FIX_DATABASE.sql` which includes:
- All CRM tables (clients, leads, invoices, bookings)
- Digital files support
- Complete calendar system
- All security policies

This immediate fix gets your calendar working in under 60 seconds!
