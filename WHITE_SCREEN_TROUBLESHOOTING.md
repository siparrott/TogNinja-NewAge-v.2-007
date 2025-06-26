# 🚨 WHITE SCREEN TROUBLESHOOTING

## The Problem
White screen = JavaScript error preventing the app from loading

## Step 1: Check Browser Console
1. **Open your live site**
2. **Press F12** (Developer Tools)
3. **Click Console tab**
4. **Look for red error messages**
5. **Tell me what errors you see**

## Step 2: Common Causes & Fixes

### Issue A: Environment Variables Not Applied
- **Solution**: Go back to Netlify → Environment Variables
- **Double-check**: All 3 variables are saved
- **Then**: Trigger a new deploy

### Issue B: Invalid Environment Variable Values
- **Check**: No extra spaces before/after the values
- **Check**: Values are exactly as provided (no missing characters)

### Issue C: Deployment Cache Issues
- **Solution**: Clear deploy cache
- **In Netlify**: Site Settings → Build & Deploy → Clear Cache

## Step 3: Quick Test URLs
Try these to see if specific pages load:

1. **Your site URL** (main page)
2. **Your site URL/admin/login** (admin login)
3. **Your site URL/kontakt** (contact page)

## Step 4: Environment Variables Check
In Netlify Environment Variables, you should have:

```
VITE_SUPABASE_URL = https://gtnwccyxwrevfnbkjvzm.supabase.co
VITE_SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0bndjY3l4d3JldmZuYmtqdnptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNDgwMTgsImV4cCI6MjA2NTgyNDAxOH0.MiOeCq2NCD969D_SXQ1wAlheSvRY5h04cUnV0XNuOrc
VITE_SUPABASE_SERVICE_ROLE_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0bndjY3l4d3JldmZuYmtqdnptIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDI0ODAxOCwiZXhwIjoyMDY1ODI0MDE4fQ.8c2gwIf7vLGmuEgMOvKWbcFviaC39hAR-qqiDYQEYpw
```

## Step 5: Alternative Test
1. **Download** the deployed files from Netlify
2. **Compare** with your workspace files
3. **Check** if all files were copied correctly

---

**Tell me what you see in the browser console (F12) - that will show the exact error!**
