// Export All Database Tables as CSV Files
// This script creates CSV exports for all tables with data

import { Pool } from '@neondatabase/serverless';
import ws from 'ws';

// Configure Neon
const neonConfig = await import('@neondatabase/serverless').then(m => m.neonConfig);
neonConfig.webSocketConstructor = ws;

const pool = new Pool({ 
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
import fs from 'fs/promises';
import path from 'path';

// Tables with actual data (based on your database analysis)
const TABLES_WITH_DATA = [
  'crm_clients',      // 2,153 records - Your main client database
  'blog_posts',       // 15 records - Published content
  'photography_sessions', // 9 records - Scheduled shoots
  'knowledge_base',   // 5 records - CRM agent data
  'users',           // 2 records - Admin accounts
  'crm_leads'        // 2 records - Sales prospects
];

// Additional empty tables you might want structure for
const IMPORTANT_EMPTY_TABLES = [
  'crm_invoices',
  'crm_messages', 
  'voucher_products',
  'voucher_sales',
  'galleries',
  'digital_files',
  'calendar_events'
];

async function exportAllTablesToCSV() {
  console.log('📊 Starting CSV export of all database tables...');
  
  // Create export directory
  const csvDir = 'csv_export';
  await fs.mkdir(csvDir, { recursive: true });
  
  const exportSummary = {
    timestamp: new Date().toISOString(),
    tables_exported: 0,
    total_records: 0,
    files_created: []
  };

  // Export tables with data
  console.log('\n🗄️ Exporting tables with data...');
  for (const tableName of TABLES_WITH_DATA) {
    try {
      console.log(`📋 Exporting: ${tableName}`);
      const result = await pool.query(`SELECT * FROM ${tableName}`);
      
      if (result.rows.length > 0) {
        const csvContent = convertToCSV(result.rows);
        const filename = `${tableName}.csv`;
        const filepath = path.join(csvDir, filename);
        
        await fs.writeFile(filepath, csvContent);
        
        console.log(`✅ ${tableName}: ${result.rows.length} records → ${filename}`);
        exportSummary.tables_exported++;
        exportSummary.total_records += result.rows.length;
        exportSummary.files_created.push(filename);
      } else {
        console.log(`⚠️ ${tableName}: No data to export`);
      }
    } catch (error) {
      console.log(`❌ Failed to export ${tableName}:`, error.message);
    }
  }

  // Export table structures (schema only)
  console.log('\n📐 Exporting table structures...');
  for (const tableName of IMPORTANT_EMPTY_TABLES) {
    try {
      const result = await pool.query(`SELECT * FROM ${tableName} LIMIT 0`);
      // Get column information
      const columns = await pool.query(`
        SELECT column_name, data_type, is_nullable, column_default 
        FROM information_schema.columns 
        WHERE table_name = '${tableName}' 
        ORDER BY ordinal_position
      `);
      
      if (columns.rows.length > 0) {
        const schemaContent = convertSchemaToCSV(columns.rows);
        const filename = `${tableName}_schema.csv`;
        const filepath = path.join(csvDir, filename);
        
        await fs.writeFile(filepath, schemaContent);
        console.log(`✅ ${tableName}: Schema structure → ${filename}`);
        exportSummary.files_created.push(filename);
      }
    } catch (error) {
      console.log(`⚠️ Schema export failed for ${tableName}:`, error.message);
    }
  }

  // Create summary report
  const summaryContent = `Database CSV Export Summary
Generated: ${exportSummary.timestamp}
Tables Exported: ${exportSummary.tables_exported}
Total Records: ${exportSummary.total_records}

Files Created:
${exportSummary.files_created.map(file => `- ${file}`).join('\n')}

Data Summary:
- crm_clients.csv: Your complete client database (2,153+ records)
- blog_posts.csv: Published blog content (15 posts)
- photography_sessions.csv: Scheduled shoots (9 sessions)
- users.csv: Admin accounts (2 users)
- knowledge_base.csv: CRM agent learning data (5 entries)
- crm_leads.csv: Sales prospects (2 leads)

Schema Files (for empty tables):
- Table structure definitions for future reference
- Column names, data types, and constraints

Usage:
- Import CSV files into Excel, Google Sheets, or any database
- Use schema files to recreate table structures
- Complete backup of your business data
`;

  await fs.writeFile(path.join(csvDir, 'EXPORT_SUMMARY.txt'), summaryContent);
  
  console.log(`\n✅ CSV export completed successfully!`);
  console.log(`📁 Location: ./${csvDir}/`);
  console.log(`📊 Files created: ${exportSummary.files_created.length}`);
  console.log(`📈 Total records exported: ${exportSummary.total_records}`);
}

function convertToCSV(rows) {
  if (rows.length === 0) return '';
  
  // Get headers from first row
  const headers = Object.keys(rows[0]);
  const csvHeaders = headers.join(',');
  
  // Convert rows to CSV format
  const csvRows = rows.map(row => {
    return headers.map(header => {
      const value = row[header];
      if (value === null) return '';
      if (typeof value === 'string' && (value.includes(',') || value.includes('"') || value.includes('\n'))) {
        return `"${value.replace(/"/g, '""')}"`;
      }
      return value;
    }).join(',');
  });
  
  return [csvHeaders, ...csvRows].join('\n');
}

function convertSchemaToCSV(schemaRows) {
  const headers = 'column_name,data_type,is_nullable,column_default';
  const csvRows = schemaRows.map(row => {
    return `${row.column_name},${row.data_type},${row.is_nullable},${row.column_default || ''}`;
  });
  return [headers, ...csvRows].join('\n');
}

// Run the export
exportAllTablesToCSV().catch(console.error);