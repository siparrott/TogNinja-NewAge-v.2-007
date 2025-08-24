#!/usr/bin/env node
import { Pool, neonConfig } from '@neondatabase/serverless';
import { writeFileSync, mkdirSync } from 'fs';
import ws from 'ws';

neonConfig.webSocketConstructor = ws;

const NEON_URL = process.env.DATABASE_URL;
const pool = new Pool({ connectionString: NEON_URL });

// ALL tables including email, calendar, invoicing, etc.
const ALL_TABLES = [
  // Core CRM
  'crm_clients',
  'crm_leads', 
  'crm_messages',
  'crm_invoices',
  'crm_invoice_items',
  'crm_invoice_payments',
  'crm_kb',
  
  // Email & Communications
  'email_outbox',
  'messages',
  'newsletter_subscribers',
  
  // Calendar & Sessions
  'calendar_categories',
  'calendar_events', 
  'calendars',
  'photography_sessions',
  'session_equipment',
  'session_tasks',
  'session_communications',
  'event_attendees',
  'event_reminders',
  
  // Pricing & Products
  'price_list',
  'voucher_products',
  'voucher_sales',
  'discount_coupons',
  'coupon_usage',
  'print_products',
  
  // Galleries & Files
  'galleries',
  'gallery_images',
  'gallery_orders',
  'gallery_order_items',
  'digital_files',
  
  // Blog & Content
  'blog_posts',
  'website_profiles',
  'seo_intel',
  
  // Users & Auth
  'admin_users',
  'users',
  
  // Payments
  'stripe_customers',
  'stripe_orders',
  
  // Business Intelligence
  'business_insights',
  'weather_data',
  'studios',
  'studio_integrations',
  
  // AI & Automation
  'knowledge_base',
  'openai_assistants',
  'ai_policies',
  'agent_action_log',
  'agent_policies',
  'agent_chat_sessions',
  
  // Imports & Logs
  'import_logs'
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
    const result = await pool.query(`SELECT * FROM "${tableName}"`);
    const rows = result.rows;
    
    if (rows.length === 0) {
      console.log(`⚠️ ${tableName} is empty`);
      return { tableName, recordCount: 0 };
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
    mkdirSync('complete_neon_export', { recursive: true });
    writeFileSync(`complete_neon_export/${tableName}.csv`, csvContent);
    
    console.log(`✅ Exported ${rows.length} records from ${tableName}`);
    return { tableName, recordCount: rows.length, headers: headers.length };
    
  } catch (error) {
    console.error(`❌ Error exporting ${tableName}: ${error.message}`);
    return { tableName, recordCount: 0, error: error.message };
  }
}

async function getTableCounts() {
  console.log('\n📊 Getting table counts from Neon...\n');
  
  const counts = {};
  for (const table of ALL_TABLES) {
    try {
      const result = await pool.query(`SELECT COUNT(*) FROM "${table}"`);
      counts[table] = parseInt(result.rows[0].count);
      if (counts[table] > 0) {
        console.log(`${table}: ${counts[table]} records`);
      }
    } catch (error) {
      counts[table] = 0;
    }
  }
  return counts;
}

async function main() {
  console.log('🚀 Exporting COMPLETE Neon Database...');
  console.log('📋 Including all email, calendar, invoicing, price lists, etc.\n');
  
  try {
    await pool.query('SELECT 1');
    console.log('✅ Connected to Neon database');

    // First get counts
    const tableCounts = await getTableCounts();
    
    console.log('\n📋 Starting export of all tables...\n');
    
    const exportResults = [];
    for (const table of ALL_TABLES) {
      if (tableCounts[table] > 0) {
        const result = await exportTableToCSV(table);
        exportResults.push(result);
      } else {
        console.log(`⚠️ Skipping empty table: ${table}`);
      }
    }

    // Create summary
    const summary = {
      exportDate: new Date().toISOString(),
      totalTables: exportResults.length,
      totalRecords: exportResults.reduce((sum, r) => sum + r.recordCount, 0),
      tables: exportResults
    };
    
    writeFileSync('complete_neon_export/export_summary.json', JSON.stringify(summary, null, 2));

    console.log('\n🎉 Complete export finished!');
    console.log(`📊 Exported ${summary.totalTables} tables with ${summary.totalRecords} total records`);
    console.log('📁 Files saved to complete_neon_export/ directory');
    
    // Show key data counts
    console.log('\n📋 Key Data Summary:');
    const keyTables = ['crm_clients', 'crm_messages', 'crm_invoices', 'calendar_events', 'price_list', 'newsletter_subscribers'];
    keyTables.forEach(table => {
      if (tableCounts[table] > 0) {
        console.log(`  ${table}: ${tableCounts[table]} records`);
      }
    });

  } catch (error) {
    console.error('❌ Export failed:', error.message);
  } finally {
    await pool.end();
  }
}

main().catch(console.error);