#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'fs';

// Parse CSV and create SQL INSERT statements
function parseCSVToSQL(csvPath, tableName) {
  const csvContent = readFileSync(csvPath, 'utf-8');
  const lines = csvContent.trim().split('\n');
  
  if (lines.length <= 1) return '';

  const headers = parseCSVLine(lines[0]);
  const dataLines = lines.slice(1);
  
  let sqlStatements = [`-- Import data for ${tableName}\n`];
  sqlStatements.push(`TRUNCATE TABLE ${tableName} CASCADE;`);
  
  dataLines.forEach((line, index) => {
    const values = parseCSVLine(line);
    const formattedValues = values.map(val => {
      if (val === null || val === '') return 'NULL';
      if (val === 'true') return 'true';
      if (val === 'false') return 'false';
      if (!isNaN(val) && val !== '') return val;
      return `'${val.replace(/'/g, "''")}'`;
    }).join(', ');
    
    const columnList = headers.map(col => `"${col}"`).join(', ');
    sqlStatements.push(`INSERT INTO ${tableName} (${columnList}) VALUES (${formattedValues});`);
  });
  
  return sqlStatements.join('\n') + '\n\n';
}

function parseCSVLine(line) {
  const result = [];
  let current = '';
  let inQuotes = false;
  
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    
    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      result.push(current === '' ? null : current);
      current = '';
    } else {
      current += char;
    }
  }
  
  result.push(current === '' ? null : current);
  return result;
}

// Tables to process
const tables = [
  'crm_clients',
  'crm_leads',
  'photography_sessions',
  'crm_invoices',
  'galleries',
  'blog_posts',
  'crm_messages',
  'voucher_products'
];

console.log('🚀 Creating Supabase SQL import file...\n');

let fullSQL = `-- Supabase Data Import
-- Generated from Neon database export
-- Run this in Supabase SQL Editor

-- First create the schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables with proper schema
CREATE TABLE IF NOT EXISTS crm_clients (
    id TEXT PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    client_id TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'Austria',
    notes TEXT,
    tags TEXT[],
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crm_leads (
    id TEXT PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    source TEXT,
    status TEXT DEFAULT 'new',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS photography_sessions (
    id TEXT PRIMARY KEY,
    client_id TEXT,
    session_type TEXT,
    scheduled_date TIMESTAMPTZ,
    duration_minutes INTEGER DEFAULT 60,
    location TEXT,
    photographer TEXT,
    status TEXT DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS blog_posts (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    slug TEXT,
    content TEXT,
    excerpt TEXT,
    featured_image TEXT,
    status TEXT DEFAULT 'draft',
    meta_title TEXT,
    meta_description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    published_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS crm_invoices (
    id TEXT PRIMARY KEY,
    client_id TEXT,
    invoice_number TEXT,
    amount DECIMAL(10,2),
    currency TEXT DEFAULT 'EUR',
    status TEXT DEFAULT 'draft',
    due_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS galleries (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    cover_image TEXT,
    is_public BOOLEAN DEFAULT false,
    password_protected BOOLEAN DEFAULT false,
    gallery_password TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crm_messages (
    id TEXT PRIMARY KEY,
    subject TEXT,
    sender_email TEXT,
    recipient_email TEXT,
    message_body TEXT,
    message_type TEXT DEFAULT 'email',
    status TEXT DEFAULT 'sent',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS voucher_products (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    currency TEXT DEFAULT 'EUR',
    validity_days INTEGER DEFAULT 365,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Now insert the data
`;

// Process each table
for (const table of tables) {
  const csvPath = `neon_export/${table}.csv`;
  try {
    const sqlForTable = parseCSVToSQL(csvPath, table);
    fullSQL += sqlForTable;
    console.log(`✅ Processed ${table}`);
  } catch (error) {
    console.log(`⚠️ Skipped ${table}: ${error.message}`);
  }
}

// Add verification queries
fullSQL += `
-- Verification queries - run these to check your data
SELECT 'crm_clients' as table_name, COUNT(*) as record_count FROM crm_clients
UNION ALL
SELECT 'crm_leads', COUNT(*) FROM crm_leads
UNION ALL
SELECT 'photography_sessions', COUNT(*) FROM photography_sessions
UNION ALL
SELECT 'crm_invoices', COUNT(*) FROM crm_invoices
UNION ALL
SELECT 'galleries', COUNT(*) FROM galleries
UNION ALL
SELECT 'blog_posts', COUNT(*) FROM blog_posts
UNION ALL
SELECT 'crm_messages', COUNT(*) FROM crm_messages
UNION ALL
SELECT 'voucher_products', COUNT(*) FROM voucher_products;

-- Success message
SELECT 'Supabase migration completed successfully!' as result;
`;

// Save the SQL file
writeFileSync('supabase-complete-import.sql', fullSQL);

console.log('\n🎉 Created supabase-complete-import.sql');
console.log('📋 This file contains all your data ready for Supabase');
console.log('🔧 Copy and paste into Supabase SQL Editor to import everything');
console.log('\n📊 Data Summary:');
console.log('- All table schemas included');
console.log('- All your data converted to SQL INSERTs');
console.log('- Verification queries included');
console.log('- Ready to run in one go!');