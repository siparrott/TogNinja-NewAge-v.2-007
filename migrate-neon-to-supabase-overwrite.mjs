import { Pool, neonConfig } from '@neondatabase/serverless';
import { Pool as PostgresPool } from 'pg';
import ws from 'ws';

neonConfig.webSocketConstructor = ws;

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m'
};

const log = (message, color = colors.cyan) => console.log(`${color}${message}${colors.reset}`);
const success = (message) => log(`✅ ${message}`, colors.green);
const error = (message) => log(`❌ ${message}`, colors.red);
const info = (message) => log(`ℹ️  ${message}`, colors.blue);
const warning = (message) => log(`⚠️  ${message}`, colors.yellow);

async function migrateNeonToSupabaseOverwrite() {
  log('\n🔄 Migrating Latest Data from Neon to Supabase (Overwrite Mode)', colors.cyan);
  log('='.repeat(70), colors.cyan);

  let neonPool = null;
  let supabasePool = null;

  try {
    // Connect to Neon (source - latest data)
    info('Connecting to Neon database (source)...');
    neonPool = new Pool({
      connectionString: process.env.DATABASE_URL,
      max: 5,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    });

    // Connect to Supabase (target - will overwrite)
    info('Connecting to Supabase database (target)...');
    supabasePool = new PostgresPool({
      connectionString: process.env.SUPABASE_DATABASE_URL,
      ssl: { rejectUnauthorized: false },
      max: 5,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 30000,
    });

    // Test connections
    info('Testing connections...');
    await neonPool.query('SELECT 1');
    await supabasePool.query('SELECT 1');
    success('Both connections established');

    // Get table counts before migration
    info('Checking current data counts...');
    const neonClients = await neonPool.query('SELECT COUNT(*) FROM crm_clients');
    const supabaseClients = await supabasePool.query('SELECT COUNT(*) FROM crm_clients');
    
    info(`Neon clients: ${neonClients.rows[0].count} (source - latest)`);
    info(`Supabase clients: ${supabaseClients.rows[0].count} (target - will overwrite)`);

    // Priority tables to migrate (most critical data)
    const priorityTables = [
      'users',
      'crm_clients', 
      'crm_leads',
      'blog_posts',
      'photography_sessions',
      'crm_invoices',
      'knowledge_base',
      'inbox_emails'
    ];

    for (const table of priorityTables) {
      await migrateTable(neonPool, supabasePool, table);
    }

    // Verify migration
    info('Verifying migration...');
    const newSupabaseClients = await supabasePool.query('SELECT COUNT(*) FROM crm_clients');
    const newSupabasePosts = await supabasePool.query('SELECT COUNT(*) FROM blog_posts');
    
    success(`Migration completed!`);
    success(`Final Supabase clients: ${newSupabaseClients.rows[0].count}`);
    success(`Final Supabase blog posts: ${newSupabasePosts.rows[0].count}`);

    info('Your CRM now uses the latest Neon data in Supabase');

  } catch (err) {
    error(`Migration failed: ${err.message}`);
    throw err;
  } finally {
    if (neonPool) await neonPool.end();
    if (supabasePool) await supabasePool.end();
  }
}

async function migrateTable(sourcePool, targetPool, tableName) {
  try {
    info(`Migrating ${tableName}...`);
    
    // Get data from Neon
    const sourceResult = await sourcePool.query(`SELECT * FROM ${tableName} ORDER BY created_at`);
    const sourceData = sourceResult.rows;
    
    if (sourceData.length === 0) {
      warning(`No data found in ${tableName}`);
      return;
    }

    // Clear existing data in Supabase (overwrite mode)
    await targetPool.query(`DELETE FROM ${tableName}`);
    info(`Cleared existing ${tableName} data from Supabase`);

    // Insert new data
    const columns = Object.keys(sourceData[0]);
    const columnsList = columns.join(', ');
    
    let inserted = 0;
    for (const record of sourceData) {
      try {
        const values = columns.map(col => {
          let value = record[col];
          
          // Handle arrays
          if (Array.isArray(value)) return value;
          
          // Handle dates
          if (value instanceof Date) return value.toISOString();
          
          // Handle JSON objects
          if (typeof value === 'object' && value !== null) {
            return JSON.stringify(value);
          }
          
          return value;
        });
        
        const placeholders = values.map((_, index) => `$${index + 1}`).join(', ');
        const insertSQL = `INSERT INTO ${tableName} (${columnsList}) VALUES (${placeholders})`;
        
        await targetPool.query(insertSQL, values);
        inserted++;
        
      } catch (err) {
        warning(`Failed to insert record in ${tableName}: ${err.message.substring(0, 100)}`);
      }
    }
    
    success(`${tableName}: ${inserted}/${sourceData.length} records migrated`);
    
  } catch (err) {
    error(`Failed to migrate ${tableName}: ${err.message}`);
  }
}

migrateNeonToSupabaseOverwrite().catch(console.error);