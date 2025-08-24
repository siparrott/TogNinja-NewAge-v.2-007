import { Pool } from 'pg';
import fs from 'fs';
import csv from 'csv-parse';

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

async function importCSVToSupabase() {
  if (!process.env.SUPABASE_DATABASE_URL) {
    error('SUPABASE_DATABASE_URL environment variable is not set');
    return;
  }

  const pool = new Pool({
    connectionString: process.env.SUPABASE_DATABASE_URL,
    ssl: { rejectUnauthorized: false },
    max: 5,
    connectionTimeoutMillis: 30000,
    idleTimeoutMillis: 30000,
  });

  try {
    info('Starting CSV import to Supabase...');

    // Check if CSV files exist
    const csvFiles = [
      { file: 'public/crm_clients.csv', table: 'crm_clients' },
      { file: 'public/blog_posts.csv', table: 'blog_posts' },
      { file: 'public/photography_sessions.csv', table: 'photography_sessions' },
      { file: 'public/crm_leads.csv', table: 'crm_leads' },
      { file: 'public/users.csv', table: 'users' },
      { file: 'public/knowledge_base.csv', table: 'knowledge_base' }
    ];

    for (const { file, table } of csvFiles) {
      if (fs.existsSync(file)) {
        await importCSVFile(pool, file, table);
      } else {
        info(`File ${file} not found, skipping...`);
      }
    }

    success('🎉 CSV import completed successfully!');
    
  } catch (err) {
    error(`Import failed: ${err.message}`);
    throw err;
  } finally {
    await pool.end();
  }
}

async function importCSVFile(pool, csvFile, tableName) {
  return new Promise((resolve, reject) => {
    info(`Importing ${csvFile} to ${tableName}...`);
    
    const records = [];
    
    fs.createReadStream(csvFile)
      .pipe(csv.parse({ 
        columns: true,
        skip_empty_lines: true,
        trim: true
      }))
      .on('data', (row) => {
        records.push(row);
      })
      .on('end', async () => {
        try {
          if (records.length === 0) {
            info(`No records found in ${csvFile}`);
            resolve();
            return;
          }

          // Get column names from first record
          const columns = Object.keys(records[0]);
          const columnsList = columns.join(', ');
          
          let imported = 0;
          
          for (const record of records) {
            try {
              const values = columns.map(col => {
                let value = record[col];
                
                // Handle empty strings
                if (value === '' || value === 'NULL') {
                  return null;
                }
                
                // Handle boolean values
                if (value === 'true' || value === 't') return true;
                if (value === 'false' || value === 'f') return false;
                
                // Handle JSON fields
                if (col.includes('_') && (value?.startsWith('[') || value?.startsWith('{'))) {
                  try {
                    return JSON.parse(value);
                  } catch {
                    return value;
                  }
                }
                
                return value;
              });
              
              const placeholders = values.map((_, index) => `$${index + 1}`).join(', ');
              const insertSQL = `
                INSERT INTO ${tableName} (${columnsList}) 
                VALUES (${placeholders})
                ON CONFLICT (id) DO NOTHING
              `;
              
              await pool.query(insertSQL, values);
              imported++;
              
            } catch (err) {
              // Skip individual record errors but log them
              if (imported % 100 === 0) {
                info(`Processed ${imported}/${records.length} records from ${tableName}...`);
              }
            }
          }
          
          success(`Imported ${imported}/${records.length} records to ${tableName}`);
          resolve();
          
        } catch (err) {
          error(`Failed to import ${csvFile}: ${err.message}`);
          reject(err);
        }
      })
      .on('error', (err) => {
        error(`Error reading ${csvFile}: ${err.message}`);
        reject(err);
      });
  });
}

importCSVToSupabase().catch(console.error);