# Supabase Migration Guide

## ✅ **Status: Data Exported from Neon**

Your Neon database has been successfully exported to CSV files:
- **2,153 clients** → `crm_clients.csv`
- **2 leads** → `crm_leads.csv` 
- **9 sessions** → `photography_sessions.csv`
- **4 invoices** → `crm_invoices.csv`
- **15 blog posts** → `blog_posts.csv`
- **224 messages** → `crm_messages.csv`
- **3 voucher products** → `voucher_products.csv`
- **1 gallery** → `galleries.csv`

## 📊 **Migration Options**

### Option 1: Manual Supabase Import (Recommended)
1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Run the schema setup: `supabase-direct-import.sql`
4. Import CSV files via Table Editor → Import Data

### Option 2: API-based Import
Use the import script once Supabase connection is working:
```bash
node import-to-supabase.mjs
```

### Option 3: Supabase CLI (If you have it installed)
```bash
supabase db push
# Then import CSVs via dashboard
```

## 🔑 **Your Supabase Connection**
- **Project**: gtnwccyxwrevfnbkjvzm
- **Password**: Matthew01!
- **Database**: postgres

## 📋 **Next Steps**
1. Create tables in Supabase using the SQL schema
2. Import your CSV files 
3. Update your app to use Supabase connection
4. Verify all data is working

## 💾 **Backup Status**
✅ **Neon database remains untouched as backup**
✅ **All CSV exports saved in `neon_export/` directory**
✅ **No data loss - everything is preserved**

## 🚀 **When Migration Complete**
Update `server/db.ts` to use the Supabase connection:
```javascript
const SUPABASE_URL = "postgres://postgres:Matthew01!@[correct-host]:5432/postgres";
```

Your data will then be running on Supabase for production deployment.