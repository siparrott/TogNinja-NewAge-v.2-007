#!/usr/bin/env node
import { Pool, neonConfig } from '@neondatabase/serverless';
import { writeFileSync, mkdirSync } from 'fs';
import ws from 'ws';

neonConfig.webSocketConstructor = ws;

const NEON_URL = process.env.DATABASE_URL;
const pool = new Pool({ connectionString: NEON_URL });

// Critical tables to export
const TABLES = [
  'crm_clients',
  'crm_leads', 
  'photography_sessions',
  'crm_invoices',
  'digital_files',
  'galleries',
  'blog_posts',
  'email_campaigns',
  'questionnaires',
  'questionnaire_responses',
  'crm_interactions',
  'crm_messages',
  'voucher_products',
  'voucher_sales'
];

function formatCSVValue(value) {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

async function exportTableToCSV(tableName) {
  console.log(`📋 Exporting ${tableName}...`);
  
  try {
    const result = await pool.query(`SELECT * FROM ${tableName}`);
    const rows = result.rows;
    
    if (rows.length === 0) {
      console.log(`⚠️ ${tableName} is empty`);
      return;
    }

    // Create CSV content
    const headers = Object.keys(rows[0]);
    const csvContent = [
      headers.join(','),
      ...rows.map(row => 
        headers.map(header => formatCSVValue(row[header])).join(',')
      )
    ].join('\n');

    // Save to file
    mkdirSync('neon_export', { recursive: true });
    writeFileSync(`neon_export/${tableName}.csv`, csvContent);
    
    console.log(`✅ Exported ${rows.length} records from ${tableName}`);
  } catch (error) {
    console.error(`❌ Error exporting ${tableName}:`, error.message);
  }
}

async function main() {
  console.log('🚀 Exporting Neon Database to CSV files...\n');
  
  try {
    await pool.query('SELECT 1');
    console.log('✅ Connected to Neon database');

    for (const table of TABLES) {
      await exportTableToCSV(table);
    }

    console.log('\n🎉 Export completed! Files saved to neon_export/ directory');
    console.log('📋 These files can be imported to Supabase manually or via script');

  } catch (error) {
    console.error('❌ Export failed:', error.message);
  } finally {
    await pool.end();
  }
}

main().catch(console.error);