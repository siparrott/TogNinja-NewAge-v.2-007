# Vercel Environment Variables Setup

Copy and paste these environment variables into your Vercel project settings:

## Database Configuration
```
SUPABASE_DATABASE_URL=postgres://postgres:Matthew01!@db.gtnwccyxwrevfnbkjvzm.supabase.co:6543/postgres
NODE_ENV=production
DEMO_MODE=false
```

## Essential Variables (Add your own values)
```
OPENAI_API_KEY=your-openai-api-key-here
ANTHROPIC_API_KEY=your-anthropic-api-key-here
JWT_SECRET=your-secure-jwt-secret-here
```

## Email Configuration (Optional - if you use email features)
```
SMTP_HOST=your-smtp-host
SMTP_PORT=587
SMTP_USER=your-smtp-username
SMTP_PASS=your-smtp-password
NODEMAILER_FROM=your-from-email@domain.com
```

## Payment Processing (Optional - if you use Stripe)
```
STRIPE_SECRET_KEY=sk_live_your-stripe-secret-key
VITE_STRIPE_PUBLIC_KEY=pk_live_your-stripe-public-key
```

## File Storage (Optional - if you use Supabase storage)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_KEY=your-supabase-service-key
```

## Other Services (Optional)
```
SERPAPI_KEY=your-serpapi-key-for-seo-features
```

---

## How to Add to Vercel:
1. Go to your Vercel dashboard
2. Select your project
3. Go to Settings → Environment Variables
4. Add each variable one by one
5. Deploy your project