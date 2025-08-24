# Deployment Guide for New Age Fotografie CRM

## 🚀 Vercel Deployment Setup

### Prerequisites
- GitHub repository set up
- Vercel account connected to GitHub
- Supabase database ready

### Step 1: GitHub Setup
1. Push all code to your GitHub repository
2. Ensure `server/db.ts` is updated for Supabase connection
3. Include `vercel.json` configuration file

### Step 2: Vercel Project Setup
1. Go to [vercel.com](https://vercel.com) and import your GitHub repository
2. Choose "Other" framework preset
3. Configure build settings:
   - **Build Command:** `npm run build:client`
   - **Output Directory:** `client/dist`
   - **Install Command:** `npm install`

### Step 3: Environment Variables
Add these environment variables in Vercel Dashboard → Project Settings → Environment Variables:

#### Database
```
SUPABASE_DATABASE_URL=postgres://postgres:Matthew01!@db.gtnwccyxwrevfnbkjvzm.supabase.co:6543/postgres
DATABASE_URL=your-neon-backup-url
```

#### AI Services
```
OPENAI_API_KEY=your-openai-key
ANTHROPIC_API_KEY=your-anthropic-key
```

#### Email
```
SMTP_HOST=your-smtp-host
SMTP_PORT=587
SMTP_USER=your-smtp-user
SMTP_PASS=your-smtp-password
NODEMAILER_FROM=your-from-email
```

#### Payment (Stripe)
```
STRIPE_SECRET_KEY=your-stripe-secret
VITE_STRIPE_PUBLIC_KEY=your-stripe-public
```

#### File Storage (Supabase)
```
SUPABASE_URL=your-supabase-project-url
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_KEY=your-supabase-service-key
```

#### Other Services
```
SERPAPI_KEY=your-serpapi-key
JWT_SECRET=your-jwt-secret
NODE_ENV=production
DEMO_MODE=false
```

### Step 4: Deploy
1. Click "Deploy" in Vercel
2. Monitor build logs for any issues
3. Test functionality after deployment

### Step 5: Custom Domain (Optional)
1. In Vercel Dashboard → Project → Settings → Domains
2. Add your custom domain
3. Configure DNS records as instructed

## 🔧 Build Configuration

### Vercel Configuration (`vercel.json`)
```json
{
  "version": 2,
  "buildCommand": "npm run build",
  "builds": [
    {
      "src": "server/index.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "server/index.ts"
    },
    {
      "src": "/(.*)",
      "dest": "client/dist/$1"
    }
  ],
  "functions": {
    "server/index.ts": {
      "maxDuration": 60
    }
  }
}
```

## 📊 Database Migration Status
- ✅ 2,153 clients migrated to Supabase
- ✅ 15 blog posts with content
- ✅ All CRM functionality preserved
- ✅ 74 AI agent tools registered

## 🔍 Verification Steps
After deployment:
1. Test login functionality
2. Verify client data displays correctly
3. Test CRM agent functionality
4. Check blog posts and galleries
5. Verify email sending capabilities

## 🆘 Troubleshooting

### Common Issues:
- **Build fails:** Check environment variables are set
- **Database connection:** Verify SUPABASE_DATABASE_URL is correct
- **API routes not working:** Ensure server/index.ts builds correctly
- **Static files 404:** Check client/dist is generated during build

### Support:
- Check Vercel build logs
- Monitor application logs in Vercel dashboard
- Test database connection in Vercel functions tab