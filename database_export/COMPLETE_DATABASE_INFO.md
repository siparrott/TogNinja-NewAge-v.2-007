# Complete Neon Database Export Information

## Database Overview

**Database Type**: Neon PostgreSQL (Serverless)
**Region**: AWS US-West-2
**Endpoint**: `ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech`
**Database Name**: `neondb`
**Total Tables**: 49 tables

## Complete Table List

### Core CRM Tables
- `crm_clients` - Customer information and contacts
- `crm_leads` - Sales pipeline and prospect tracking  
- `crm_invoices` - Billing and payment management
- `crm_invoice_items` - Invoice line items
- `crm_invoice_payments` - Payment tracking
- `crm_messages` - Customer communications
- `crm_kb` - CRM knowledge base

### User Management
- `users` - User authentication and profiles
- `admin_users` - Administrative accounts

### CRM Agent System
- `agent_action_log` - Agent action tracking
- `agent_chat_sessions` - Conversation sessions
- `agent_policies` - Agent operation policies
- `ai_policies` - AI behavior policies
- `knowledge_base` - Agent knowledge storage (pgvector)
- `openai_assistants` - AI assistant configurations

### Content Management
- `blog_posts` - Blog content and SEO data
- `messages` - System messaging
- `newsletter_subscribers` - Email marketing lists

### Photography Business
- `photography_sessions` - Session scheduling and details
- `digital_files` - File storage and organization
- `galleries` - Photo gallery management
- `gallery_images` - Gallery image catalog
- `gallery_orders` - Print order management
- `gallery_order_items` - Order line items

### Calendar System
- `calendars` - Calendar configurations
- `calendar_categories` - Event categorization
- `calendar_events` - Scheduled events
- `event_attendees` - Event participants
- `event_reminders` - Reminder system

### Session Management
- `session_communications` - Session messaging
- `session_equipment` - Equipment tracking
- `session_tasks` - Task management

### E-commerce
- `voucher_products` - Gift voucher catalog
- `voucher_sales` - Voucher transactions
- `discount_coupons` - Discount management
- `coupon_usage` - Usage tracking
- `stripe_customers` - Stripe integration
- `stripe_orders` - Payment processing
- `price_list` - Pricing catalog
- `print_products` - Print product catalog

### Integrations
- `studio_integrations` - External service integrations
- `studios` - Studio management
- `website_profiles` - Website data and analytics
- `seo_intel` - SEO intelligence data
- `weather_data` - Weather information

### System Operations
- `import_logs` - Data import tracking
- `business_insights` - Analytics and metrics
- `email_outbox` - Email queue management

## Database Migration Instructions

### Option 1: Neon Database Branching (Recommended)
```bash
# 1. Login to Neon Console: https://console.neon.tech/
# 2. Find project: ep-bitter-tooth-a6gzcoua
# 3. Create branch: "migration-copy" 
# 4. Get new DATABASE_URL from branch
```

### Option 2: Full Database Dump
```bash
# Create complete backup
pg_dump "postgresql://[user]:[pass]@ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech/neondb?sslmode=require" > complete_neon_backup.sql

# Restore to new database  
psql "postgresql://[user]:[pass]@new-host:port/new-db" < complete_neon_backup.sql
```

### Option 3: Schema + Data Migration
```bash
# 1. Apply schema to new database
export DATABASE_URL="postgresql://new-connection"
npm run db:push

# 2. Export data per table
pg_dump --data-only --table=table_name [connection] > table_data.sql

# 3. Import data
psql [new-connection] < table_data.sql
```

## Essential Files for Migration

### Database Configuration
- `shared/schema.ts` - Complete Drizzle ORM schema (✅ Included)
- `server/db.ts` - Database connection setup (✅ Included)  
- `drizzle.config.ts` - Migration configuration (✅ Included)
- `server/storage.ts` - Data access layer

### CRM Agent Dependencies
- `agent/` directory - Complete agent system
- `server/routes/crm-agent.ts` - Agent API endpoints
- Tables: agent_*, knowledge_base, ai_policies

### Critical Business Data
- All `crm_*` tables - Customer and sales data
- `photography_sessions` - Session bookings
- `voucher_*` tables - E-commerce transactions
- `blog_posts` - Content management
- `users` & `admin_users` - Authentication

## Connection Details

**Current Environment Variables Required:**
```env
DATABASE_URL=postgresql://[credentials]@ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech/neondb?sslmode=require
PGHOST=ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech
PGDATABASE=neondb
PGUSER=[username]
PGPASSWORD=[password]
PGPORT=5432
```

## Verification Commands

```bash
# Test connection
npx drizzle-kit introspect:pg

# Check table count
psql $DATABASE_URL -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';"

# Verify CRM agent tables
psql $DATABASE_URL -c "SELECT tablename FROM pg_tables WHERE tablename LIKE 'agent_%' OR tablename LIKE 'crm_%';"

# Check data integrity
psql $DATABASE_URL -c "SELECT count(*) FROM crm_leads; SELECT count(*) FROM crm_clients; SELECT count(*) FROM photography_sessions;"
```

## Post-Migration Checklist

- [ ] All 49 tables migrated successfully
- [ ] CRM agent can access knowledge_base table
- [ ] User authentication works with users/admin_users
- [ ] Photography sessions and digital files accessible
- [ ] E-commerce voucher system operational
- [ ] Blog posts and content preserved
- [ ] Calendar and event data intact
- [ ] Payment and invoice data secure
- [ ] File references and URLs updated
- [ ] Integration endpoints functional

Your Neon database contains a complete photography business management system with CRM agent, e-commerce, content management, and comprehensive business operations data across 49 tables.