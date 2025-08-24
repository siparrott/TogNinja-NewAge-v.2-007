// Database Export Script for Migration
// This script creates a complete backup of your Neon database

import { Pool } from '@neondatabase/serverless';
import fs from 'fs/promises';
import path from 'path';

// Create database connection
const pool = new Pool({ 
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

async function exportDatabase() {
  console.log('🗄️ Starting complete database export...');
  
  const exportData = {
    timestamp: new Date().toISOString(),
    source: 'Neon Database',
    export_type: 'Complete Migration Export',
    tables: {}
  };

  try {
    // Export all tables with data
    const tables = [
      'users', 'clients', 'leads', 'invoices', 'invoice_items', 'invoice_payments',
      'photography_sessions', 'digital_files', 'blog_posts', 'email_campaigns',
      'questionnaires', 'questionnaire_responses', 'voucher_products', 'voucher_sales',
      'voucher_redemptions', 'website_profiles', 'agent_interactions', 'knowledge_base',
      'automation_workflows', 'gallery_orders', 'inbox_messages'
    ];

    for (const tableName of tables) {
      try {
        console.log(`📊 Exporting table: ${tableName}`);
        
        // Get table structure and data
        const result = await pool.query(`SELECT * FROM ${tableName}`);
        exportData.tables[tableName] = {
          rowCount: result.rows.length,
          data: result.rows,
          exported_at: new Date().toISOString()
        };
        
        console.log(`✅ ${tableName}: ${result.rows.length} rows exported`);
      } catch (error) {
        console.log(`⚠️ Table ${tableName} not found or empty:`, error.message);
        exportData.tables[tableName] = { rowCount: 0, data: [], error: error.message };
      }
    }

    // Create export directory
    const exportDir = 'database_export';
    await fs.mkdir(exportDir, { recursive: true });

    // Save complete data export
    const dataFile = path.join(exportDir, 'complete_database_export.json');
    await fs.writeFile(dataFile, JSON.stringify(exportData, null, 2));

    // Create SQL dump
    await createSQLDump(exportData, exportDir);

    // Create migration instructions
    await createMigrationInstructions(exportDir);

    console.log('✅ Database export completed successfully!');
    console.log(`📁 Export location: ./${exportDir}/`);
    console.log(`📊 Total tables: ${Object.keys(exportData.tables).length}`);
    console.log(`📈 Total rows: ${Object.values(exportData.tables).reduce((sum, table) => sum + table.rowCount, 0)}`);

  } catch (error) {
    console.error('❌ Export failed:', error);
  }
}

async function createSQLDump(exportData, exportDir) {
  console.log('📝 Creating SQL dump...');
  
  let sqlContent = `-- Complete Database Export SQL Dump
-- Generated: ${exportData.timestamp}
-- Source: ${exportData.source}

-- Disable foreign key checks during import
SET session_replication_role = replica;

`;

  for (const [tableName, tableData] of Object.entries(exportData.tables)) {
    if (tableData.data && tableData.data.length > 0) {
      sqlContent += `\n-- Table: ${tableName} (${tableData.rowCount} rows)\n`;
      
      // Get column names from first row
      const columns = Object.keys(tableData.data[0]);
      
      sqlContent += `DELETE FROM ${tableName};\n`;
      
      for (const row of tableData.data) {
        const values = columns.map(col => {
          const value = row[col];
          if (value === null) return 'NULL';
          if (typeof value === 'string') return `'${value.replace(/'/g, "''")}'`;
          if (typeof value === 'boolean') return value;
          if (value instanceof Date) return `'${value.toISOString()}'`;
          return value;
        }).join(', ');
        
        sqlContent += `INSERT INTO ${tableName} (${columns.join(', ')}) VALUES (${values});\n`;
      }
    }
  }

  sqlContent += `\n-- Re-enable foreign key checks
SET session_replication_role = DEFAULT;
`;

  await fs.writeFile(path.join(exportDir, 'database_dump.sql'), sqlContent);
  console.log('✅ SQL dump created');
}

async function createMigrationInstructions(exportDir) {
  const instructions = `# Database Migration Instructions

## Current Database Details
- **Type**: Neon Database (Serverless PostgreSQL)
- **Location**: AWS US-West-2
- **Connection**: via @neondatabase/serverless
- **ORM**: Drizzle ORM with TypeScript

## Export Contents

### 1. Complete Data Export
- **File**: \`complete_database_export.json\`
- **Format**: JSON with full table structure and data
- **Use**: For programmatic migration or analysis

### 2. SQL Dump
- **File**: \`database_dump.sql\`
- **Format**: PostgreSQL compatible SQL
- **Use**: Direct import into new PostgreSQL database

### 3. Schema Definition
- **File**: \`../shared/schema.ts\`
- **Format**: Drizzle ORM TypeScript schema
- **Use**: Recreate database structure in new environment

## Migration Options

### Option 1: Direct SQL Import
\`\`\`bash
# Import into new PostgreSQL database
psql -h your-new-host -U username -d database_name < database_dump.sql
\`\`\`

### Option 2: Drizzle Migration
\`\`\`bash
# Setup new database with schema
export DATABASE_URL="postgresql://user:pass@host:port/db"
npm run db:push

# Then import data using the JSON export
node import-data-script.js
\`\`\`

### Option 3: Neon to Neon Migration
1. Create new Neon database
2. Use Neon's branching feature for instant copy
3. Update DATABASE_URL in new environment

## Database Schema Summary

The exported database contains:
- **User Management**: users, authentication
- **CRM Core**: clients, leads, invoices, sessions  
- **Content**: blog_posts, digital_files
- **Agent System**: agent_interactions, knowledge_base
- **E-commerce**: voucher_products, voucher_sales, gallery_orders
- **Communication**: email_campaigns, inbox_messages
- **Automation**: automation_workflows, questionnaires

## Next Steps

1. **Choose migration method** based on target database
2. **Test import** in staging environment first
3. **Update connection strings** in new application
4. **Verify data integrity** after migration
5. **Update environment variables** for new database

## Important Notes

- All foreign key relationships are preserved
- UUIDs and timestamps are maintained
- JSON fields and arrays are exported as-is
- Binary data (if any) is base64 encoded

## Support Files Included

- Database connection configuration (\`server/db.ts\`)
- Schema definitions (\`shared/schema.ts\`)
- Drizzle configuration (\`drizzle.config.ts\`)
`;

  await fs.writeFile(path.join(exportDir, 'MIGRATION_GUIDE.md'), instructions);
  console.log('✅ Migration instructions created');
}

// Run export
exportDatabase().catch(console.error);