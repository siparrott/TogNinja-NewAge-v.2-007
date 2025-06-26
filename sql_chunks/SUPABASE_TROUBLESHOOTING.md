# Supabase Project Troubleshooting Guide

## Current Issue: Edge Function Connection Errors

Based on the logs, your Supabase project is experiencing Edge Function connectivity issues.

## Steps to Fix:

### 1. Check Project Status
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Find your project: `gtnwccyxwrevfnbkjvzm`
3. Check if it shows as "Paused" or "Inactive"

### 2. Resume Paused Project
If your project is paused:
1. Click on your project
2. Look for a "Resume" or "Restore" button
3. Click it to reactivate your project
4. Wait 2-3 minutes for the database and Edge Functions to fully start

### 3. Deploy the Required Edge Function
The CSV import feature requires the `clients-import` Edge Function to be deployed:

#### Option A: Using Supabase CLI (Recommended)
1. Install Supabase CLI if you haven't: `npm install -g supabase`
2. Login to Supabase: `supabase login`
3. Link your project: `supabase link --project-ref gtnwccyxwrevfnbkjvzm`
4. Deploy the Edge Function: `supabase functions deploy clients-import`

#### Option B: Manual Deployment via Dashboard
1. Go to your Supabase Dashboard → Edge Functions
2. Click "Create a new function"
3. Name it `clients-import`
4. Copy the code from `supabase/functions/clients-import/index.ts`
5. Deploy the function

### 4. Verify Edge Function Deployment
1. In your Supabase dashboard, go to Edge Functions
2. Look for the `clients-import` function
3. Ensure it shows as "Deployed" and "Active"
4. Test the function by clicking on it and using the "Invoke" button

### 5. Check Billing Status
1. Go to Settings → Billing in your Supabase dashboard
2. Ensure you have an active plan (even the free tier needs to be active)
3. If there are any billing issues, resolve them

### 6. Verify Database Connection
1. In your Supabase dashboard, go to Settings → Database
2. Check that the database status shows as "Healthy" or "Active"
3. Try running a simple query in the SQL Editor to test connectivity

### 7. Test the Import Feature
Once your project is running and the Edge Function is deployed:
1. Wait 2-3 minutes for everything to initialize
2. Try the CSV import feature again
3. Check the browser console for any remaining errors

### 8. Create Demo User (After Project is Active)
Once your project is running:
1. Go to Authentication → Users in Supabase dashboard
2. Click "Add user"
3. Email: `demo@example.com`
4. Password: `demo123`
5. Click "Create user"

### 9. Set Up Admin Access
The import feature requires admin access. Run this SQL in your Supabase SQL Editor:
```sql
INSERT INTO admin_users (user_id, is_admin) 
VALUES (
  (SELECT id FROM auth.users WHERE email = 'demo@example.com'),
  true
) ON CONFLICT (user_id) DO UPDATE SET is_admin = true;
```

## Alternative: Use Existing User
I can see you have `matt@newagefotografie.com` in your users table. You can:
1. Reset the password for this user in Supabase dashboard
2. Use this account to log in instead
3. Ensure admin privileges are set up for this user

## Common Edge Function Issues

### Function Not Deployed
- **Symptom**: "Upload service not found" or 404 errors
- **Solution**: Deploy the `clients-import` Edge Function using the steps above

### Project Paused
- **Symptom**: "Failed to fetch" or 503 errors
- **Solution**: Resume your Supabase project from the dashboard

### Authentication Issues
- **Symptom**: 401 or 403 errors
- **Solution**: Ensure you're logged in and have admin privileges

### Wrong Function Name
- **Symptom**: 404 errors even when function is deployed
- **Solution**: Ensure the function is named exactly `clients-import` (with hyphen, not slash)

## Edge Function Requirements
The CSV import feature requires:
1. **Edge Function**: `clients-import` must be deployed
2. **Authentication**: User must be logged in
3. **Admin Access**: User must have admin privileges in `admin_users` table
4. **Active Project**: Supabase project must be active and not paused

## If Issues Persist
If you continue having problems after following these steps:
1. Check the Supabase status page: https://status.supabase.com/
2. Try refreshing your browser and clearing cache
3. Wait 5-10 minutes as Edge Functions can take time to start
4. Check the Edge Function logs in your Supabase dashboard
5. Contact Supabase support if the issue persists

## Quick Test
Once your project is active and the Edge Function is deployed:
1. Go to your Supabase dashboard → Edge Functions
2. Click on the `clients-import` function
3. Click "Invoke" with a simple GET request to test if it's working
4. If it responds, the function is ready for use

## Function URL Structure
The correct Edge Function URL should be:
`https://[your-project-id].supabase.co/functions/v1/clients-import`

Make sure the function name matches exactly: `clients-import` (not `clients/import`)