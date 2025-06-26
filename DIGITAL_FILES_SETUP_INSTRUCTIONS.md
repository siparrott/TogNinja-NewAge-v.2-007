# Digital Files System Setup Instructions

## Current Issue
The Digital Files page is showing "Failed to upload files" because the required Supabase database table and storage bucket have not been created yet.

## Required Setup Steps (Must be done in order)

### Step 1: Create Storage Bucket in Supabase Dashboard

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **Storage** in the left sidebar
4. Click **"New bucket"**
5. Create a bucket with these settings:
   - **Name**: `digital-files` (exactly this name)
   - **Public bucket**: ✅ **Check this box** (enable public access)
   - **File size limit**: 50MB (or adjust as needed)
   - **Allowed MIME types**: Leave empty or add: `image/*,video/*,audio/*,application/pdf,text/*`

### Step 2: Set Storage Bucket Policies

After creating the bucket, go to **Storage > Policies** and create these policies:

**Policy 1: Allow authenticated users to upload**
- **Policy name**: `Users can upload files`
- **Allowed operation**: INSERT
- **Target roles**: authenticated
- **USING expression**: `auth.uid() IS NOT NULL`

**Policy 2: Allow public read access**
- **Policy name**: `Public file access`
- **Allowed operation**: SELECT  
- **Target roles**: public
- **USING expression**: `true`

### Step 3: Run Database Setup SQL

1. Go to **SQL Editor** in your Supabase Dashboard
2. Create a new query
3. Copy and paste the entire contents of `DIGITAL_FILES_DATABASE_SETUP.sql`
4. Click **"Run"** to execute the SQL

This will create:
- `digital_files` table with all required columns
- `file_shares` table for file sharing functionality
- All necessary indexes and RLS policies
- Sample data for testing

### Step 4: Verify Setup

After running the SQL, you should see:
- A `digital_files` table in your **Table Editor**
- A `file_shares` table in your **Table Editor** 
- A `digital-files` storage bucket in your **Storage** section

### Step 5: Test File Upload

1. Go back to your live website
2. Navigate to **Admin > Digital Files**
3. Click the **"+"** button to upload a file
4. Try uploading an image - it should work now!

## Troubleshooting

### If you get "Table 'digital_files' doesn't exist":
- Make sure you ran the SQL from `DIGITAL_FILES_DATABASE_SETUP.sql`
- Check the **Table Editor** to confirm the table was created

### If you get "Bucket 'digital-files' doesn't exist":
- Make sure you created the storage bucket with the exact name `digital-files`
- Check **Storage** section to confirm the bucket exists

### If upload fails with permission errors:
- Check that your storage bucket policies allow authenticated users to upload
- Make sure the bucket is set to **public**

## Important Notes

- The bucket name MUST be exactly `digital-files` (with hyphen, not underscore)
- The table name MUST be exactly `digital_files` (with underscore, not hyphen)
- Make sure you're logged in as an admin user when testing uploads
- File uploads will be organized by date and stored securely

Once these steps are completed, the Digital Files system will be fully functional with file upload, preview, download, and management capabilities.
