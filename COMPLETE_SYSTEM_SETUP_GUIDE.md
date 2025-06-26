# Complete System Setup Guide - TogNinja CRM

## Current Status
Your TogNinja CRM is deployed but missing critical database tables and storage buckets. This guide will fix all the issues you're seeing.

## 🚨 CRITICAL: Must Complete in Order

### 1. Digital Files System Setup

**Problem**: File upload failing with "Failed to upload files" error  
**Cause**: Missing storage bucket and database table

#### Step 1A: Create Storage Bucket
1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → Your Project
2. Click **Storage** in sidebar
3. Click **"New bucket"**
4. Settings:
   - **Name**: `digital-files` (exactly this, with hyphen)
   - **Public bucket**: ✅ **MUST CHECK THIS BOX**
   - **File size limit**: 50MB
5. Click **"Create bucket"**

#### Step 1B: Set Storage Policies  
1. Go to **Storage** → **Policies**
2. Find your `digital-files` bucket
3. Click **"New Policy"** twice to create:

**Policy 1**: Allow uploads
```sql
CREATE POLICY "Allow authenticated uploads" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'digital-files' AND
    auth.role() = 'authenticated'
);
```

**Policy 2**: Allow public read
```sql
CREATE POLICY "Allow public downloads" ON storage.objects
FOR SELECT USING (bucket_id = 'digital-files');
```

#### Step 1C: Create Database Table
1. Go to **SQL Editor**
2. Copy/paste entire content from `DIGITAL_FILES_DATABASE_SETUP.sql`
3. Click **Run**

### 2. Blog System Setup

**Problem**: Blog may show errors or missing data  
**Solution**: Run blog database setup

1. Go to **SQL Editor** 
2. Copy/paste entire content from `BLOG_DATABASE_SETUP.sql`
3. Click **Run**

### 3. Calendar System Setup

**Problem**: Calendar events not saving or loading
**Solution**: Ensure calendar table exists

1. Go to **SQL Editor**
2. Run this SQL:

```sql
-- Create calendar_events table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    description TEXT,
    location TEXT,
    is_all_day BOOLEAN DEFAULT false,
    recurrence_rule TEXT,
    user_id UUID REFERENCES auth.users(id),
    client_id UUID,
    booking_id UUID,
    event_type TEXT DEFAULT 'appointment',
    status TEXT DEFAULT 'scheduled',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY "Users can manage their calendar events" ON public.calendar_events
    FOR ALL USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_id ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_date ON public.calendar_events(start_date);
```

### 4. Remove Demo Data (IMPORTANT)

**Problem**: Site may show demo/test data instead of your real data  
**Solution**: Clean up demo data

1. Go to **SQL Editor**
2. Copy/paste entire content from `REMOVE_DEMO_DATA_FINAL.sql`  
3. Click **Run**

## ✅ Verification Steps

After completing all setup steps:

### Test Digital Files:
1. Go to your live site → Admin → Digital Files
2. Click "+" to upload
3. Select an image file
4. Should upload successfully without errors

### Test Blog:
1. Go to your live site → Blog
2. Should show real blog posts (not demo data)
3. Featured images should load correctly

### Test Calendar:
1. Go to your live site → Admin → Calendar
2. Try creating a new event
3. Should save successfully and appear on calendar

## 🔧 Troubleshooting

### Digital Files Upload Still Fails:
- ✅ Bucket name is exactly `digital-files` (with hyphen)
- ✅ Bucket is set to **Public**
- ✅ Storage policies are created
- ✅ `digital_files` table exists (with underscore)

### Blog Images Not Loading:
- Run the blog setup SQL to fix image paths
- Clear browser cache and refresh

### Calendar Events Not Saving:
- Make sure `calendar_events` table exists
- Check browser console for errors
- Verify you're logged in as authenticated user

## 📝 Quick Commands Reference

**Create Storage Bucket**: Supabase Dashboard → Storage → New bucket → `digital-files` (public)

**Run SQL Setup**: Supabase Dashboard → SQL Editor → Paste SQL → Run

**Files to run in SQL Editor**:
1. `DIGITAL_FILES_DATABASE_SETUP.sql` (for file uploads)
2. `BLOG_DATABASE_SETUP.sql` (for blog system)  
3. `REMOVE_DEMO_DATA_FINAL.sql` (to clean demo data)
4. Calendar SQL (provided above)

Once all these steps are completed, your TogNinja CRM will be fully functional with real data and no demo content!
