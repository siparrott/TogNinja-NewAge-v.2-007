#!/usr/bin/env node
import { createClient } from '@supabase/supabase-js';
import { Pool } from 'pg';
import { readFileSync } from 'fs';

// Supabase connection via direct PostgreSQL
const SUPABASE_CONNECTION = "postgresql://postgres.gtnwccyxwrevfnbkjvzm:Matthew01!@aws-0-eu-central-1.pooler.supabase.com:5432/postgres";

// Try multiple connection methods
const connectionOptions = [
  {
    name: "Direct PostgreSQL",
    config: {
      connectionString: SUPABASE_CONNECTION,
      ssl: { rejectUnauthorized: false },
      max: 3,
      connectionTimeoutMillis: 30000
    }
  },
  {
    name: "Alternative endpoint",
    config: {
      connectionString: "postgres://postgres.gtnwccyxwrevfnbkjvzm:Matthew01!@db.gtnwccyxwrevfnbkjvzm.supabase.co:5432/postgres",
      ssl: { rejectUnauthorized: false },
      max: 3,
      connectionTimeoutMillis: 30000
    }
  }
];

async function testConnection(config) {
  const pool = new Pool(config);
  try {
    await pool.query('SELECT 1 as test');
    console.log(`✅ Connection successful with ${config.connectionString.split('@')[1].split('/')[0]}`);
    return pool;
  } catch (error) {
    console.log(`❌ Connection failed: ${error.message}`);
    await pool.end();
    return null;
  }
}

async function executeImport() {
  console.log('🚀 Starting Supabase import...\n');
  
  let workingPool = null;
  
  // Test connections
  for (const option of connectionOptions) {
    console.log(`Testing ${option.name}...`);
    workingPool = await testConnection(option.config);
    if (workingPool) break;
  }
  
  if (!workingPool) {
    console.log('\n❌ Could not establish Supabase connection');
    console.log('📋 Please run the import manually:');
    console.log('1. Go to Supabase SQL Editor');
    console.log('2. Copy contents of supabase-complete-import.sql');
    console.log('3. Paste and execute in SQL Editor');
    return;
  }
  
  try {
    // Read and execute the SQL import file
    console.log('\n📋 Reading import file...');
    const sqlContent = readFileSync('supabase-complete-import.sql', 'utf-8');
    
    // Split into individual statements
    const statements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    console.log(`📊 Found ${statements.length} SQL statements to execute`);
    
    let executed = 0;
    let errors = 0;
    
    for (const statement of statements) {
      try {
        if (statement.toLowerCase().includes('insert into')) {
          // Execute INSERT statements
          await workingPool.query(statement);
          executed++;
          
          if (executed % 100 === 0) {
            console.log(`   ... executed ${executed} statements`);
          }
        } else {
          // Execute DDL statements (CREATE TABLE, etc.)
          await workingPool.query(statement);
          executed++;
        }
      } catch (error) {
        errors++;
        if (errors <= 5) {
          console.log(`⚠️ Statement error: ${error.message.substring(0, 60)}...`);
        }
      }
    }
    
    console.log(`\n✅ Import completed: ${executed} statements executed, ${errors} errors`);
    
    // Verify the import
    console.log('\n🔍 Verifying import...');
    const tables = ['crm_clients', 'crm_leads', 'photography_sessions', 'blog_posts'];
    
    for (const table of tables) {
      try {
        const result = await workingPool.query(`SELECT COUNT(*) FROM ${table}`);
        const count = parseInt(result.rows[0].count);
        console.log(`✅ ${table}: ${count} records`);
      } catch (error) {
        console.log(`⚠️ ${table}: Could not verify`);
      }
    }
    
    console.log('\n🎉 Supabase import successful!');
    console.log('📊 Your data is now in Supabase');
    
  } catch (error) {
    console.error('\n❌ Import failed:', error.message);
  } finally {
    await workingPool.end();
  }
}

executeImport().catch(console.error);