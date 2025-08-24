# Database Migration Instructions

## Current Database Details
- **Type**: Neon Database (Serverless PostgreSQL)
- **Location**: AWS US-West-2
- **Connection**: via @neondatabase/serverless
- **ORM**: Drizzle ORM with TypeScript

## Export Contents

### 1. Complete Data Export
- **File**: `complete_database_export.json`
- **Format**: JSON with full table structure and data
- **Use**: For programmatic migration or analysis

### 2. SQL Dump
- **File**: `database_dump.sql`
- **Format**: PostgreSQL compatible SQL
- **Use**: Direct import into new PostgreSQL database

### 3. Schema Definition
- **File**: `../shared/schema.ts`
- **Format**: Drizzle ORM TypeScript schema
- **Use**: Recreate database structure in new environment

## Migration Options

### Option 1: Direct SQL Import
```bash
# Import into new PostgreSQL database
psql -h your-new-host -U username -d database_name < database_dump.sql
```

### Option 2: Drizzle Migration
```bash
# Setup new database with schema
export DATABASE_URL="postgresql://user:pass@host:port/db"
npm run db:push

# Then import data using the JSON export
node import-data-script.js
```

### Option 3: Neon to Neon Migration
1. Create new Neon database
2. Use Neon's branching feature for instant copy
3. Update DATABASE_URL in new environment

## Database Schema Summary

The exported database contains:
- **User Management**: users, authentication
- **CRM Core**: clients, leads, invoices, sessions  
- **Content**: blog_posts, digital_files
- **Agent System**: agent_interactions, knowledge_base
- **E-commerce**: voucher_products, voucher_sales, gallery_orders
- **Communication**: email_campaigns, inbox_messages
- **Automation**: automation_workflows, questionnaires

## Next Steps

1. **Choose migration method** based on target database
2. **Test import** in staging environment first
3. **Update connection strings** in new application
4. **Verify data integrity** after migration
5. **Update environment variables** for new database

## Important Notes

- All foreign key relationships are preserved
- UUIDs and timestamps are maintained
- JSON fields and arrays are exported as-is
- Binary data (if any) is base64 encoded

## Support Files Included

- Database connection configuration (`server/db.ts`)
- Schema definitions (`shared/schema.ts`)
- Drizzle configuration (`drizzle.config.ts`)
