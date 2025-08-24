import { Pool } from '@neondatabase/serverless';
import { Pool as PostgresPool } from 'pg';
import { drizzle } from 'drizzle-orm/neon-serverless';
import { drizzle as pgDrizzle } from 'drizzle-orm/node-postgres';
import * as schema from './shared/schema.ts';
import ws from 'ws';
import { neonConfig } from '@neondatabase/serverless';

neonConfig.webSocketConstructor = ws;

// ANSI color codes for better output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

const log = (message, color = colors.cyan) => {
  console.log(`${color}${message}${colors.reset}`);
};

const success = (message) => log(`✅ ${message}`, colors.green);
const error = (message) => log(`❌ ${message}`, colors.red);
const warning = (message) => log(`⚠️  ${message}`, colors.yellow);
const info = (message) => log(`ℹ️  ${message}`, colors.blue);

async function migrateToSupabase() {
  log('\n🚀 Starting Complete Database Migration from Neon to Supabase', colors.bright);
  log('='.repeat(70), colors.cyan);

  try {
    // Check environment variables
    if (!process.env.DATABASE_URL) {
      throw new Error('DATABASE_URL (Neon) is not set');
    }
    if (!process.env.SUPABASE_DATABASE_URL) {
      throw new Error('SUPABASE_DATABASE_URL is not set');
    }

    info('Connecting to source database (Neon)...');
    const neonPool = new Pool({ 
      connectionString: process.env.DATABASE_URL,
      max: 5,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });
    const sourceDb = drizzle(neonPool, { schema });

    info('Connecting to target database (Supabase)...');
    const supabasePool = new PostgresPool({
      connectionString: process.env.SUPABASE_DATABASE_URL,
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });
    const targetDb = pgDrizzle(supabasePool, { schema });

    // Test connections
    info('Testing database connections...');
    await neonPool.query('SELECT 1');
    await supabasePool.query('SELECT 1');
    success('Both database connections established successfully');

    // Create schema and tables in Supabase
    info('Creating database schema in Supabase...');
    await createSchema(supabasePool);

    // Get all table data from source
    info('Fetching data from source database...');
    const sourceData = await fetchAllData(sourceDb);

    // Migrate data to target
    info('Migrating data to Supabase...');
    await migrateAllData(targetDb, sourceData);

    // Verify migration
    info('Verifying migration...');
    await verifyMigration(sourceDb, targetDb);

    success('🎉 Database migration completed successfully!');
    log('\n📊 Migration Summary:', colors.bright);
    
    for (const [table, data] of Object.entries(sourceData)) {
      if (data.length > 0) {
        success(`  ${table}: ${data.length} records migrated`);
      }
    }

    info('\nNext steps:');
    info('1. Update your application to use SUPABASE_DATABASE_URL');
    info('2. Test all functionality to ensure everything works');
    info('3. Keep the original Neon database as backup until fully verified');

    // Close connections
    await neonPool.end();
    await supabasePool.end();

  } catch (err) {
    error(`Migration failed: ${err.message}`);
    console.error(err);
    process.exit(1);
  }
}

async function createSchema(pool) {
  // Enable required extensions
  await pool.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
  await pool.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
  
  info('Extensions enabled in Supabase');

  // Create all tables with proper schema
  const createTablesSQL = `
    -- Users table
    CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      email TEXT UNIQUE NOT NULL,
      password TEXT,
      first_name TEXT,
      last_name TEXT,
      avatar TEXT,
      is_admin BOOLEAN DEFAULT false,
      studio_id UUID,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    -- Studio configs table
    CREATE TABLE IF NOT EXISTS studio_configs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      studio_name TEXT NOT NULL,
      owner_email TEXT NOT NULL,
      domain TEXT,
      subdomain TEXT UNIQUE,
      active_template TEXT DEFAULT 'template-01-modern-minimal',
      logo_url TEXT,
      primary_color TEXT DEFAULT '#7C3AED',
      secondary_color TEXT DEFAULT '#F59E0B',
      font_family TEXT DEFAULT 'Inter',
      business_name TEXT,
      address TEXT,
      city TEXT,
      state TEXT,
      zip TEXT,
      country TEXT DEFAULT 'Austria',
      phone TEXT,
      email TEXT,
      website TEXT,
      facebook_url TEXT,
      instagram_url TEXT,
      twitter_url TEXT,
      opening_hours JSONB,
      enabled_features TEXT[] DEFAULT ARRAY['gallery', 'booking', 'blog', 'crm'],
      meta_title TEXT,
      meta_description TEXT,
      is_active BOOLEAN DEFAULT true,
      subscription_status TEXT DEFAULT 'trial',
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    -- Template definitions table
    CREATE TABLE IF NOT EXISTS template_definitions (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      category TEXT,
      preview_image TEXT,
      demo_url TEXT,
      features TEXT[],
      color_scheme JSONB,
      is_active BOOLEAN DEFAULT true,
      is_premium BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW()
    );

    -- Admin users table
    CREATE TABLE IF NOT EXISTS admin_users (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID REFERENCES users(id) NOT NULL,
      is_admin BOOLEAN DEFAULT true,
      permissions JSONB,
      created_at TIMESTAMP DEFAULT NOW()
    );

    -- Blog posts table
    CREATE TABLE IF NOT EXISTS blog_posts (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title TEXT NOT NULL,
      slug TEXT UNIQUE NOT NULL,
      content TEXT,
      content_html TEXT,
      excerpt TEXT,
      image_url TEXT,
      published BOOLEAN DEFAULT false,
      published_at TIMESTAMP,
      scheduled_for TIMESTAMP,
      status TEXT DEFAULT 'DRAFT',
      author_id UUID REFERENCES users(id),
      tags TEXT[],
      meta_description TEXT,
      seo_title TEXT,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    -- CRM Clients table
    CREATE TABLE IF NOT EXISTS crm_clients (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      first_name TEXT,
      last_name TEXT,
      email TEXT,
      phone TEXT,
      address TEXT,
      city TEXT,
      postal_code TEXT,
      country TEXT DEFAULT 'Austria',
      date_of_birth DATE,
      preferred_contact_method TEXT DEFAULT 'email',
      notes TEXT,
      tags TEXT[],
      status TEXT DEFAULT 'active',
      source TEXT,
      total_spent DECIMAL(10,2) DEFAULT 0,
      last_contact_date TIMESTAMP,
      next_follow_up_date TIMESTAMP,
      assigned_to UUID REFERENCES users(id),
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    -- CRM Leads table
    CREATE TABLE IF NOT EXISTS crm_leads (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      first_name TEXT,
      last_name TEXT,
      email TEXT,
      phone TEXT,
      source TEXT,
      status TEXT DEFAULT 'new',
      interest_level TEXT DEFAULT 'medium',
      preferred_contact_method TEXT DEFAULT 'email',
      service_interest TEXT,
      budget_range TEXT,
      timeline TEXT,
      notes TEXT,
      tags TEXT[],
      assigned_to UUID REFERENCES users(id),
      follow_up_date TIMESTAMP,
      converted BOOLEAN DEFAULT false,
      converted_to_client_id UUID REFERENCES crm_clients(id),
      conversion_date TIMESTAMP,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    -- Photography sessions table
    CREATE TABLE IF NOT EXISTS photography_sessions (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      client_id UUID REFERENCES crm_clients(id),
      session_type TEXT NOT NULL,
      session_date TIMESTAMP NOT NULL,
      start_time TIME,
      end_time TIME,
      duration_minutes INTEGER DEFAULT 60,
      location TEXT,
      location_type TEXT DEFAULT 'studio',
      photographer_id UUID REFERENCES users(id),
      status TEXT DEFAULT 'scheduled',
      price DECIMAL(10,2),
      deposit_amount DECIMAL(10,2),
      deposit_paid BOOLEAN DEFAULT false,
      notes TEXT,
      equipment_needed TEXT[],
      special_requests TEXT,
      weather_backup_plan TEXT,
      reminder_sent BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    -- CRM Invoices table
    CREATE TABLE IF NOT EXISTS crm_invoices (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      invoice_number TEXT UNIQUE NOT NULL,
      client_id UUID REFERENCES crm_clients(id),
      session_id UUID REFERENCES photography_sessions(id),
      status TEXT DEFAULT 'draft',
      issue_date DATE NOT NULL,
      due_date DATE NOT NULL,
      subtotal DECIMAL(10,2) NOT NULL,
      tax_amount DECIMAL(10,2) DEFAULT 0,
      total_amount DECIMAL(10,2) NOT NULL,
      paid_amount DECIMAL(10,2) DEFAULT 0,
      paid_date DATE,
      payment_method TEXT,
      notes TEXT,
      terms TEXT,
      line_items JSONB,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    -- Inbox emails table
    CREATE TABLE IF NOT EXISTS inbox_emails (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      sender_email TEXT NOT NULL,
      sender_name TEXT,
      recipient_email TEXT NOT NULL,
      subject TEXT NOT NULL,
      body TEXT,
      received_at TIMESTAMP DEFAULT NOW(),
      is_read BOOLEAN DEFAULT false,
      is_archived BOOLEAN DEFAULT false,
      thread_id TEXT,
      message_id TEXT UNIQUE,
      labels TEXT[],
      attachments JSONB,
      created_at TIMESTAMP DEFAULT NOW()
    );

    -- Knowledge base table
    CREATE TABLE IF NOT EXISTS knowledge_base (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      category TEXT,
      tags TEXT[],
      embedding VECTOR(1536),
      metadata JSONB,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );

    -- Create indexes for better performance
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_blog_posts_slug ON blog_posts(slug);
    CREATE INDEX IF NOT EXISTS idx_crm_clients_email ON crm_clients(email);
    CREATE INDEX IF NOT EXISTS idx_crm_leads_email ON crm_leads(email);
    CREATE INDEX IF NOT EXISTS idx_photography_sessions_date ON photography_sessions(session_date);
    CREATE INDEX IF NOT EXISTS idx_crm_invoices_number ON crm_invoices(invoice_number);
    CREATE INDEX IF NOT EXISTS idx_inbox_emails_received ON inbox_emails(received_at);
  `;

  await pool.query(createTablesSQL);
  success('Database schema created in Supabase');
}

async function fetchAllData(db) {
  const data = {};
  
  try {
    info('Fetching users...');
    data.users = await db.select().from(schema.users);
    
    info('Fetching studio configs...');
    data.studioConfigs = await db.select().from(schema.studioConfigs);
    
    info('Fetching template definitions...');
    data.templateDefinitions = await db.select().from(schema.templateDefinitions);
    
    info('Fetching admin users...');
    data.adminUsers = await db.select().from(schema.adminUsers);
    
    info('Fetching blog posts...');
    data.blogPosts = await db.select().from(schema.blogPosts);
    
    info('Fetching CRM clients...');
    data.crmClients = await db.select().from(schema.crmClients);
    
    info('Fetching CRM leads...');
    data.crmLeads = await db.select().from(schema.crmLeads);
    
    info('Fetching photography sessions...');
    data.photographySessions = await db.select().from(schema.photographySessions);
    
    info('Fetching CRM invoices...');
    data.crmInvoices = await db.select().from(schema.crmInvoices);
    
    info('Fetching inbox emails...');
    data.inboxEmails = await db.select().from(schema.inboxEmails);
    
    info('Fetching knowledge base...');
    data.knowledgeBase = await db.select().from(schema.knowledgeBase);

    success('All data fetched from source database');
    return data;
  } catch (err) {
    error(`Failed to fetch data: ${err.message}`);
    throw err;
  }
}

async function migrateAllData(db, data) {
  try {
    // Migrate in order due to foreign key dependencies
    
    if (data.users.length > 0) {
      info(`Migrating ${data.users.length} users...`);
      await db.insert(schema.users).values(data.users).onConflictDoNothing();
      success(`${data.users.length} users migrated`);
    }

    if (data.studioConfigs.length > 0) {
      info(`Migrating ${data.studioConfigs.length} studio configs...`);
      await db.insert(schema.studioConfigs).values(data.studioConfigs).onConflictDoNothing();
      success(`${data.studioConfigs.length} studio configs migrated`);
    }

    if (data.templateDefinitions.length > 0) {
      info(`Migrating ${data.templateDefinitions.length} template definitions...`);
      await db.insert(schema.templateDefinitions).values(data.templateDefinitions).onConflictDoNothing();
      success(`${data.templateDefinitions.length} template definitions migrated`);
    }

    if (data.adminUsers.length > 0) {
      info(`Migrating ${data.adminUsers.length} admin users...`);
      await db.insert(schema.adminUsers).values(data.adminUsers).onConflictDoNothing();
      success(`${data.adminUsers.length} admin users migrated`);
    }

    if (data.blogPosts.length > 0) {
      info(`Migrating ${data.blogPosts.length} blog posts...`);
      await db.insert(schema.blogPosts).values(data.blogPosts).onConflictDoNothing();
      success(`${data.blogPosts.length} blog posts migrated`);
    }

    if (data.crmClients.length > 0) {
      info(`Migrating ${data.crmClients.length} CRM clients...`);
      await db.insert(schema.crmClients).values(data.crmClients).onConflictDoNothing();
      success(`${data.crmClients.length} CRM clients migrated`);
    }

    if (data.crmLeads.length > 0) {
      info(`Migrating ${data.crmLeads.length} CRM leads...`);
      await db.insert(schema.crmLeads).values(data.crmLeads).onConflictDoNothing();
      success(`${data.crmLeads.length} CRM leads migrated`);
    }

    if (data.photographySessions.length > 0) {
      info(`Migrating ${data.photographySessions.length} photography sessions...`);
      await db.insert(schema.photographySessions).values(data.photographySessions).onConflictDoNothing();
      success(`${data.photographySessions.length} photography sessions migrated`);
    }

    if (data.crmInvoices.length > 0) {
      info(`Migrating ${data.crmInvoices.length} CRM invoices...`);
      await db.insert(schema.crmInvoices).values(data.crmInvoices).onConflictDoNothing();
      success(`${data.crmInvoices.length} CRM invoices migrated`);
    }

    if (data.inboxEmails.length > 0) {
      info(`Migrating ${data.inboxEmails.length} inbox emails...`);
      await db.insert(schema.inboxEmails).values(data.inboxEmails).onConflictDoNothing();
      success(`${data.inboxEmails.length} inbox emails migrated`);
    }

    if (data.knowledgeBase.length > 0) {
      info(`Migrating ${data.knowledgeBase.length} knowledge base entries...`);
      await db.insert(schema.knowledgeBase).values(data.knowledgeBase).onConflictDoNothing();
      success(`${data.knowledgeBase.length} knowledge base entries migrated`);
    }

    success('All data migrated successfully!');
  } catch (err) {
    error(`Failed to migrate data: ${err.message}`);
    throw err;
  }
}

async function verifyMigration(sourceDb, targetDb) {
  try {
    const tables = [
      'users', 'studioConfigs', 'templateDefinitions', 'adminUsers', 
      'blogPosts', 'crmClients', 'crmLeads', 'photographySessions', 
      'crmInvoices', 'inboxEmails', 'knowledgeBase'
    ];

    for (const table of tables) {
      const schemaTable = schema[table];
      if (schemaTable) {
        const sourceCount = await sourceDb.select().from(schemaTable);
        const targetCount = await targetDb.select().from(schemaTable);
        
        if (sourceCount.length === targetCount.length) {
          success(`${table}: ${sourceCount.length} records verified`);
        } else {
          warning(`${table}: Source has ${sourceCount.length}, Target has ${targetCount.length}`);
        }
      }
    }
  } catch (err) {
    warning(`Verification had issues: ${err.message}`);
  }
}

// Run the migration
migrateToSupabase().catch(console.error);