# Environment Variables Setup for Netlify Deployment

## Required Environment Variables

### Supabase Configuration
```bash
# Get these from your Supabase project settings
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (long JWT token)
VITE_SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (service role JWT token)
```

### OpenAI Integration
```bash
# Get from OpenAI Dashboard
VITE_OPENAI_API_KEY=sk-proj-... (your OpenAI API key)
```

### reCAPTCHA (Optional but recommended)
```bash
# Get from Google reCAPTCHA console
VITE_GOOGLE_RECAPTCHA_SITE_KEY=6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI
```

### Email Configuration (Optional)
```bash
# For contact form notifications
VITE_SMTP_HOST=smtp.gmail.com
VITE_SMTP_PORT=587
VITE_SMTP_USER=your-email@gmail.com
VITE_SMTP_PASS=your-app-password
```

## How to Add Variables to Netlify

### Method 1: Netlify Dashboard
1. Go to your site in Netlify dashboard
2. Navigate to **Site settings** > **Environment variables**
3. Click **Add variable**
4. Add each variable name and value
5. Click **Save**
6. Redeploy your site

### Method 2: Netlify CLI
```bash
# Install Netlify CLI if not installed
npm install -g netlify-cli

# Login to Netlify
netlify login

# Set environment variables
netlify env:set VITE_SUPABASE_URL "https://your-project-id.supabase.co"
netlify env:set VITE_SUPABASE_ANON_KEY "your-anon-key"
netlify env:set VITE_SUPABASE_SERVICE_ROLE_KEY "your-service-role-key"
netlify env:set VITE_OPENAI_API_KEY "your-openai-key"

# Deploy with new variables
netlify deploy --prod
```

## Getting Your Supabase Keys

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to **Settings** > **API**
4. Copy the values:
   - **Project URL** → `VITE_SUPABASE_URL`
   - **anon public** → `VITE_SUPABASE_ANON_KEY`
   - **service_role** → `VITE_SUPABASE_SERVICE_ROLE_KEY`

## Getting Your OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Click **Create new secret key**
3. Copy the key (starts with `sk-proj-...`)
4. Add as `VITE_OPENAI_API_KEY`

## Verification

After adding variables and redeploying:

1. Check browser console for connection errors
2. Test lead form submission
3. Try creating an invoice
4. Test gallery upload
5. Verify OpenAI assistant responses

## Troubleshooting

### Common Issues:
- **CORS errors:** Check Supabase project settings
- **401 Unauthorized:** Verify API keys are correct
- **Module not found:** Ensure all dependencies are installed
- **Build failures:** Check for syntax errors in environment setup

### Debug Commands:
```bash
# Check if variables are loaded
console.log('Supabase URL:', import.meta.env.VITE_SUPABASE_URL);
console.log('Has OpenAI key:', !!import.meta.env.VITE_OPENAI_API_KEY);
```

---
**Created:** $(Get-Date)
**Note:** Keep your service role key secure - it has admin access to your database!
