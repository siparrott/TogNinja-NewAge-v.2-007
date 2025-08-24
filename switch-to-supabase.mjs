#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'fs';

console.log('🔄 Updating server/db.ts to use Supabase...');

const dbConfig = `import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from "../shared/schema.js";

// Use Supabase database URL as primary connection
const databaseUrl = process.env.SUPABASE_DATABASE_URL || process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error(
    "SUPABASE_DATABASE_URL or DATABASE_URL must be set. Did you forget to provision a database?",
  );
}

// Create pool optimized for Supabase
export const pool = new Pool({ 
  connectionString: databaseUrl,
  ssl: process.env.SUPABASE_DATABASE_URL ? { rejectUnauthorized: false } : false,
  max: 10,
  min: 2,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 20000,
  acquireTimeoutMillis: 20000,
  allowExitOnIdle: false,
});

export const db = drizzle(pool, { schema });

// Log which database we're using
console.log(\`📊 Database: \${process.env.SUPABASE_DATABASE_URL ? 'Supabase' : 'Neon'} connection established\`);`;

writeFileSync('server/db.ts', dbConfig);

console.log('✅ Updated server/db.ts for Supabase');
console.log('📋 Set SUPABASE_DATABASE_URL environment variable when ready');
console.log('🔄 App will automatically use Supabase when environment variable is set');