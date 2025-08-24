import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from "../shared/schema.js";

if (!process.env.SUPABASE_DATABASE_URL) {
  throw new Error(
    "SUPABASE_DATABASE_URL must be set. Did you forget to provision a Supabase database?",
  );
}

// Create pool with proper Supabase configuration
export const supabasePool = new Pool({ 
  connectionString: process.env.SUPABASE_DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

export const supabaseDb = drizzle(supabasePool, { schema });

// Test the connection
supabasePool.on('connect', () => {
  console.log('✅ Connected to Supabase database');
});

supabasePool.on('error', (err) => {
  console.error('❌ Supabase database error:', err);
});