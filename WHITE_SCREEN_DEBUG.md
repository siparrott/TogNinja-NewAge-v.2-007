# 🚨 WHITE SCREEN DEBUG GUIDE

## WHITE SCREEN = Missing Environment Variables

Your deployment succeeded but shows a white screen because **Supabase environment variables are missing**.

## IMMEDIATE FIX - Add Environment Variables to Netlify:

### Step 1: Go to Netlify Dashboard
1. Go to your Netlify site dashboard
2. Click **Site settings** 
3. Click **Environment variables** in the left menu
4. Click **Add variable**

### Step 2: Add These Variables:
```
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
VITE_OPENAI_API_KEY=your_openai_api_key (if using AI features)
```

### Step 3: Get Your Supabase Credentials:
1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → Use for `VITE_SUPABASE_URL`
   - **anon public key** → Use for `VITE_SUPABASE_ANON_KEY`

### Step 4: Redeploy
1. In Netlify, go to **Deploys**
2. Click **Trigger deploy** → **Deploy site**
3. Wait 2-3 minutes

## Alternative Quick Check:
1. Open your live site
2. Press **F12** (Developer Tools)
3. Look at **Console** tab - you'll see the actual error
4. If it says "Supabase URL not found" or similar → Add environment variables

## Your Workspace Environment File:
Check your `.env` file in the workspace - copy those values to Netlify.

---

**The good news**: Your deployment worked! You just need to add the missing configuration.
