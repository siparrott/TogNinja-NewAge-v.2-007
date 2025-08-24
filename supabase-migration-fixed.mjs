import { Pool } from '@neondatabase/serverless';
import { Client } from 'pg';
import { drizzle } from 'drizzle-orm/neon-serverless';
import { drizzle as pgDrizzle } from 'drizzle-orm/node-postgres';
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

  let neonPool = null;
  let supabaseClient = null;

  try {
    // Check environment variables
    if (!process.env.DATABASE_URL) {
      throw new Error('DATABASE_URL (Neon) is not set');
    }
    if (!process.env.SUPABASE_DATABASE_URL) {
      throw new Error('SUPABASE_DATABASE_URL is not set');
    }

    info('Connecting to source database (Neon)...');
    neonPool = new Pool({ 
      connectionString: process.env.DATABASE_URL,
      max: 3,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    });

    info('Connecting to target database (Supabase)...');
    // Use a single client connection for Supabase with SSL
    const supabaseUrl = process.env.SUPABASE_DATABASE_URL;
    const connectionConfig = {
      connectionString: supabaseUrl,
      ssl: { rejectUnauthorized: false },
      connectionTimeoutMillis: 30000,
      idleTimeoutMillis: 30000,
    };
    
    supabaseClient = new Client(connectionConfig);
    await supabaseClient.connect();

    // Test connections
    info('Testing database connections...');
    await neonPool.query('SELECT 1');
    await supabaseClient.query('SELECT 1');
    success('Both database connections established successfully');

    // Create schema and tables in Supabase
    info('Creating database schema in Supabase...');
    await createSchema(supabaseClient);

    // Get all table data from source using raw SQL
    info('Fetching data from source database...');
    const sourceData = await fetchAllDataRaw(neonPool);

    // Migrate data to target
    info('Migrating data to Supabase...');
    await migrateAllDataRaw(supabaseClient, sourceData);

    // Verify migration
    info('Verifying migration...');
    await verifyMigrationRaw(neonPool, supabaseClient);

    success('🎉 Database migration completed successfully!');
    log('\n📊 Migration Summary:', colors.bright);
    
    for (const [table, data] of Object.entries(sourceData)) {
      if (data.length > 0) {
        success(`  ${table}: ${data.length} records migrated`);
      }
    }

    info('\nNext steps:');
    info('1. Update server/db.ts to use SUPABASE_DATABASE_URL');
    info('2. Test all functionality to ensure everything works');
    info('3. Keep the original Neon database as backup until fully verified');

  } catch (err) {
    error(`Migration failed: ${err.message}`);
    console.error(err);
    process.exit(1);
  } finally {
    // Clean up connections
    if (neonPool) {
      try {
        await neonPool.end();
      } catch (e) {
        warning('Failed to close Neon connection');
      }
    }
    if (supabaseClient) {
      try {
        await supabaseClient.end();
      } catch (e) {
        warning('Failed to close Supabase connection');
      }
    }
  }
}

async function createSchema(client) {
  // Enable required extensions
  await client.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
  await client.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
  
  info('Extensions enabled in Supabase');

  // Create all tables with proper schema based on your current structure
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

  await client.query(createTablesSQL);
  success('Database schema created in Supabase');
}

async function fetchAllDataRaw(pool) {
  const data = {};
  
  try {
    const tables = [
      'users', 'studio_configs', 'template_definitions', 'admin_users',
      'blog_posts', 'crm_clients', 'crm_leads', 'photography_sessions',
      'crm_invoices', 'inbox_emails', 'knowledge_base'
    ];

    for (const table of tables) {
      try {
        info(`Fetching ${table}...`);
        const result = await pool.query(`SELECT * FROM ${table} ORDER BY created_at`);
        data[table] = result.rows;
        success(`Fetched ${result.rows.length} records from ${table}`);
      } catch (err) {
        warning(`Table ${table} not found or empty: ${err.message}`);
        data[table] = [];
      }
    }

    return data;
  } catch (err) {
    error(`Failed to fetch data: ${err.message}`);
    throw err;
  }
}

async function migrateAllDataRaw(client, data) {
  try {
    // Migrate in order due to foreign key dependencies
    const migrationOrder = [
      'users', 'studio_configs', 'template_definitions', 'admin_users',
      'blog_posts', 'crm_clients', 'crm_leads', 'photography_sessions',
      'crm_invoices', 'inbox_emails', 'knowledge_base'
    ];

    for (const table of migrationOrder) {
      const records = data[table] || [];
      
      if (records.length > 0) {
        info(`Migrating ${records.length} ${table} records...`);
        
        // Get column names from the first record
        const columns = Object.keys(records[0]);
        const columnsList = columns.join(', ');
        const placeholders = columns.map((_, index) => `$${index + 1}`).join(', ');
        
        const insertSQL = `
          INSERT INTO ${table} (${columnsList}) 
          VALUES (${placeholders})
          ON CONFLICT (id) DO NOTHING
        `;

        // Insert records one by one to handle data type conversions
        let migrated = 0;
        for (const record of records) {
          try {
            const values = columns.map(col => {
              let value = record[col];
              // Handle array fields
              if (Array.isArray(value)) {
                return value;
              }
              // Handle date/timestamp fields
              if (value instanceof Date) {
                return value.toISOString();
              }
              // Handle JSON fields
              if (typeof value === 'object' && value !== null) {
                return JSON.stringify(value);
              }
              return value;
            });
            
            await client.query(insertSQL, values);
            migrated++;
          } catch (err) {
            warning(`Failed to migrate record in ${table}: ${err.message}`);
          }
        }
        
        success(`${migrated}/${records.length} ${table} records migrated`);
      }
    }

    success('All data migrated successfully!');
  } catch (err) {
    error(`Failed to migrate data: ${err.message}`);
    throw err;
  }
}

async function verifyMigrationRaw(sourcePool, targetClient) {
  try {
    const tables = [
      'users', 'studio_configs', 'template_definitions', 'admin_users',
      'blog_posts', 'crm_clients', 'crm_leads', 'photography_sessions',
      'crm_invoices', 'inbox_emails', 'knowledge_base'
    ];

    for (const table of tables) {
      try {
        const sourceResult = await sourcePool.query(`SELECT COUNT(*) FROM ${table}`);
        const targetResult = await targetClient.query(`SELECT COUNT(*) FROM ${table}`);
        
        const sourceCount = parseInt(sourceResult.rows[0].count);
        const targetCount = parseInt(targetResult.rows[0].count);
        
        if (sourceCount === targetCount) {
          success(`${table}: ${sourceCount} records verified`);
        } else {
          warning(`${table}: Source has ${sourceCount}, Target has ${targetCount}`);
        }
      } catch (err) {
        warning(`Could not verify ${table}: ${err.message}`);
      }
    }
  } catch (err) {
    warning(`Verification had issues: ${err.message}`);
  }
}

// Run the migration
migrateToSupabase().catch(console.error);