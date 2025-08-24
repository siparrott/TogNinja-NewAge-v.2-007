import { Pool } from 'pg';

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m'
};

const log = (message, color = colors.blue) => console.log(`${color}${message}${colors.reset}`);
const success = (message) => log(`✅ ${message}`, colors.green);
const error = (message) => log(`❌ ${message}`, colors.red);
const info = (message) => log(`ℹ️  ${message}`, colors.blue);

async function createSupabaseSchema() {
  if (!process.env.SUPABASE_DATABASE_URL) {
    error('SUPABASE_DATABASE_URL environment variable is not set');
    return;
  }

  const pool = new Pool({
    connectionString: process.env.SUPABASE_DATABASE_URL,
    ssl: { rejectUnauthorized: false },
    max: 1,
    connectionTimeoutMillis: 60000,
    idleTimeoutMillis: 60000,
  });

  try {
    info('Creating Supabase database schema...');
    
    // Enable required extensions
    await pool.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
    await pool.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
    success('Extensions enabled');

    // Create tables one by one
    info('Creating users table...');
    await pool.query(`
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
    `);

    info('Creating studio_configs table...');
    await pool.query(`
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
    `);

    info('Creating template_definitions table...');
    await pool.query(`
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
    `);

    info('Creating admin_users table...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS admin_users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) NOT NULL,
        is_admin BOOLEAN DEFAULT true,
        permissions JSONB,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);

    info('Creating blog_posts table...');
    await pool.query(`
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
    `);

    info('Creating crm_clients table...');
    await pool.query(`
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
    `);

    info('Creating crm_leads table...');
    await pool.query(`
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
    `);

    info('Creating photography_sessions table...');
    await pool.query(`
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
    `);

    info('Creating crm_invoices table...');
    await pool.query(`
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
    `);

    info('Creating inbox_emails table...');
    await pool.query(`
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
    `);

    info('Creating knowledge_base table...');
    await pool.query(`
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
    `);

    info('Creating indexes...');
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
      CREATE INDEX IF NOT EXISTS idx_blog_posts_slug ON blog_posts(slug);
      CREATE INDEX IF NOT EXISTS idx_crm_clients_email ON crm_clients(email);
      CREATE INDEX IF NOT EXISTS idx_crm_leads_email ON crm_leads(email);
      CREATE INDEX IF NOT EXISTS idx_photography_sessions_date ON photography_sessions(session_date);
      CREATE INDEX IF NOT EXISTS idx_crm_invoices_number ON crm_invoices(invoice_number);
      CREATE INDEX IF NOT EXISTS idx_inbox_emails_received ON inbox_emails(received_at);
    `);

    success('🎉 Supabase database schema created successfully!');
    success('All tables and indexes have been set up');
    
  } catch (err) {
    error(`Failed to create schema: ${err.message}`);
    throw err;
  } finally {
    await pool.end();
  }
}

createSupabaseSchema().catch(console.error);