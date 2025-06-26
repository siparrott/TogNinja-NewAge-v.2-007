# CRITICAL FIX GUIDE - Calendar & Digital Files Not Working

## 🚨 URGENT: Follow these steps immediately to fix the calendar and digital files

### STEP 1: Run SQL Script in Supabase (MOST IMPORTANT)

1. **Go to your Supabase Dashboard**
   - Open: https://supabase.com/dashboard
   - Select your project

2. **Open SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New query"

3. **Copy and paste the ENTIRE contents of `CRITICAL_URGENT_FIX.sql`**
   - Open the file `CRITICAL_URGENT_FIX.sql` in your workspace
   - Select ALL the text (Ctrl+A)
   - Copy it (Ctrl+C)
   - Paste it into the Supabase SQL Editor

4. **Run the SQL script**
   - Click "Run" button
   - Wait for it to complete (should take 10-20 seconds)
   - You should see "Success" messages

### STEP 2: Create Storage Bucket for Digital Files

1. **In Supabase Dashboard, go to Storage**
   - Click "Storage" in the left sidebar
   - Click "Create a new bucket"

2. **Create bucket with these settings:**
   - **Bucket name**: `digital-files` (EXACTLY this name)
   - **Public bucket**: ❌ OFF (keep it private)
   - **File size limit**: 50MB
   - **Allowed MIME types**: Leave empty (allow all)

3. **Click "Create bucket"**

### STEP 3: Set Storage Policies

1. **Still in Storage, click on the "digital-files" bucket**
2. **Go to the "Policies" tab**
3. **Click "Add policy" and add these 4 policies:**

**Policy 1 - Upload:**
```sql
CREATE POLICY "Users can upload their own files" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'digital-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );
```

**Policy 2 - View:**
```sql
CREATE POLICY "Users can view their own files" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'digital-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );
```

**Policy 3 - Update:**  
```sql
CREATE POLICY "Users can update their own files" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'digital-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );
```

**Policy 4 - Delete:**
```sql
CREATE POLICY "Users can delete their own files" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'digital-files' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );
```

### STEP 4: Verify Tables Were Created

1. **Go to "Table Editor" in Supabase**
2. **Check that these tables exist:**
   - ✅ `calendar_categories`
   - ✅ `calendars` 
   - ✅ `calendar_events`
   - ✅ `calendar_event_attendees`
   - ✅ `calendar_event_reminders`
   - ✅ `digital_files`

### STEP 5: Test the Fixes

1. **Clear browser cache** (Ctrl+Shift+R or Cmd+Shift+R)
2. **Go to Calendar page** - try creating a new event
3. **Go to Digital Files page** - try uploading a file

## What These Fixes Do:

### Calendar Fixes:
- ✅ Creates all required calendar tables
- ✅ Sets up proper relationships between tables
- ✅ Creates default calendar and category
- ✅ Enables Row Level Security (RLS)
- ✅ Creates proper RLS policies for data access

### Digital Files Fixes:
- ✅ Creates the digital_files table
- ✅ Creates storage bucket for file uploads
- ✅ Sets up proper file metadata fields
- ✅ Enables secure file upload/download

## Common Issues & Solutions:

**If Calendar still doesn't work:**
- Make sure you ran the ENTIRE SQL script
- Check the browser console for errors (F12)
- Verify the `calendars` table has at least one row

**If Digital Files still doesn't work:**
- Make sure the storage bucket is named exactly `digital-files`
- Check that all 4 storage policies were created
- Verify RLS is enabled on the `digital_files` table

**If you get authentication errors:**
- Make sure you're logged in to the admin panel
- Clear browser cache and cookies
- Try logging out and back in

## ⚠️ IMPORTANT NOTES:

1. **Run the SQL script FIRST** - everything else depends on this
2. **Storage bucket name must be exactly "digital-files"** (with hyphen, not underscore)
3. **Don't skip the storage policies** - files won't upload without them
4. **Clear browser cache** after making database changes

## Testing Checklist:

- [ ] SQL script ran successfully without errors
- [ ] Storage bucket "digital-files" exists and is private
- [ ] All 4 storage policies are created
- [ ] Calendar page loads without errors
- [ ] Can create and save calendar events
- [ ] Digital Files page loads without errors  
- [ ] Can upload files successfully
- [ ] Files appear in the file list after upload

If you still have issues after following these steps, please share:
1. Screenshots of any error messages
2. Browser console errors (F12 → Console tab)
3. Which step failed
