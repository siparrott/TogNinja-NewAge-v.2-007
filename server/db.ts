import { Pool } from 'pg';
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
console.log(`📊 Database: ${process.env.SUPABASE_DATABASE_URL ? 'Supabase' : 'Neon'} connection established`);