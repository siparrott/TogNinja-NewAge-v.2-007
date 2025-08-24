# Neon Database Information & Migration Guide

## Current Database Configuration

### Connection Details
- **Type**: Neon Database (Serverless PostgreSQL)
- **Region**: AWS US-West-2 
- **Endpoint**: `ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech`
- **Database**: `neondb`
- **SSL**: Required
- **Connection**: Via `@neondatabase/serverless` driver

### Environment Configuration
```bash
DATABASE_URL=postgresql://[user]:[password]@ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech/neondb?sslmode=require
```

## Database Schema Location
- **Schema File**: `shared/schema.ts` (Complete Drizzle ORM schema)
- **Migration Config**: `drizzle.config.ts`
- **Connection Config**: `server/db.ts`

## Migration Options

### Option 1: Neon Database Branching (Recommended)
Neon provides database branching for instant copying:

1. **Login to Neon Console**: https://console.neon.tech/
2. **Find your project**: Look for database with endpoint `ep-bitter-tooth-a6gzcoua`
3. **Create Branch**: Click "Branches" → "Create Branch"
4. **Choose source**: Select main branch
5. **Name new branch**: e.g., "migration-copy" or "production-backup"
6. **Get new connection string**: Copy the new DATABASE_URL

### Option 2: Direct Database Dump
Use PostgreSQL tools to create a complete dump:

```bash
# Create dump (replace with your actual credentials)
pg_dump "postgresql://user:pass@ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech/neondb?sslmode=require" > neon_database_backup.sql

# Restore to new database
psql "postgresql://user:pass@new-host:port/new-database" < neon_database_backup.sql
```

### Option 3: Drizzle Schema Migration
1. **Export current schema**: Already in `shared/schema.ts`
2. **Setup new database**: Any PostgreSQL instance
3. **Apply schema**: `npm run db:push` 
4. **Data migration**: Custom scripts or CSV export/import

## Complete Schema Structure

Your database contains these main entities:

### Core Tables
- **users** - User authentication and profiles
- **clients** - Customer information and contacts  
- **leads** - Sales pipeline and prospect tracking
- **invoices** - Billing and payment management
- **photography_sessions** - Session scheduling and details
- **digital_files** - File storage and organization

### CRM Agent System
- **agent_interactions** - Conversation history and context
- **knowledge_base** - Agent knowledge storage (pgvector)
- **automation_workflows** - Automated business processes

### Content Management
- **blog_posts** - Blog content and SEO data
- **email_campaigns** - Marketing automation
- **questionnaires** - Customer feedback system

### E-commerce
- **voucher_products** - Gift voucher catalog
- **voucher_sales** - Sales transactions
- **gallery_orders** - Print order management

## Key Features Using Database
1. **Self-Planning CRM Agent** - Uses knowledge_base table with pgvector
2. **AutoBlog System** - Stores generated content in blog_posts
3. **Session Management** - Photography scheduling in photography_sessions
4. **Invoice Generation** - Complete billing system
5. **Lead Pipeline** - CRM functionality in leads/clients tables

## Migration Steps

### 1. Backup Current Database
- Use Neon branching (instant)
- Or export with pg_dump

### 2. Prepare Target Environment
```bash
# Install dependencies
npm install @neondatabase/serverless drizzle-orm drizzle-kit

# Set new DATABASE_URL
export DATABASE_URL="postgresql://user:pass@new-host:port/new-db"

# Apply schema
npm run db:push
```

### 3. Data Migration
- **Small dataset**: Manual CSV export/import
- **Large dataset**: Use pg_dump/pg_restore
- **Live migration**: Database replication tools

### 4. Update Application
```bash
# Update environment variable
DATABASE_URL="new-database-connection-string"

# Test connection
npm run dev
```

## Files to Include in Migration

### Essential Database Files
- `shared/schema.ts` - Complete database schema
- `server/db.ts` - Database connection configuration  
- `drizzle.config.ts` - Migration tool configuration
- `server/storage.ts` - Data access layer

### CRM Agent Dependencies
- `agent/` directory - Complete agent system
- `server/routes/crm-agent.ts` - Agent API endpoints
- Database tables: agent_interactions, knowledge_base

### Application Dependencies  
- All route handlers in `server/routes/`
- Frontend components for database interaction
- Authentication and session management

## Verification Checklist

After migration:
- [ ] Database connection successful
- [ ] All tables created with correct schema
- [ ] Data integrity maintained
- [ ] CRM Agent can access knowledge_base
- [ ] Blog posts and content preserved
- [ ] Invoice and session data intact
- [ ] User authentication working
- [ ] File references and URLs updated

## Support Commands

```bash
# Check database status
npm run db:push --dry-run

# View current schema
npx drizzle-kit introspect:pg

# Generate migration SQL
npx drizzle-kit generate:pg

# Apply migrations
npm run db:push
```

Your Neon database is fully configured and operational. The export directory contains schema and migration guides for transferring to any PostgreSQL-compatible database.