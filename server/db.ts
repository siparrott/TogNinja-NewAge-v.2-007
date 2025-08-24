import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from "../shared/schema.js";

// Use Supabase URL from Replit secrets
const supabaseUrl = process.env.SUPABASE_DATABASE_URL;
const neonUrl = process.env.DATABASE_URL;

let databaseUrl: string;
let connectionType: string;

if (supabaseUrl) {
  databaseUrl = supabaseUrl;
  connectionType = "Supabase";
} else if (neonUrl) {
  databaseUrl = neonUrl;
  connectionType = "Neon (fallback)";
} else {
  throw new Error("SUPABASE_DATABASE_URL or DATABASE_URL must be set");
}

export const pool = new Pool({ 
  connectionString: databaseUrl,
  ssl: supabaseUrl ? { rejectUnauthorized: false } : false,
  max: 10,
  min: 2,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 20000,
});

export const db = drizzle(pool, { schema });

console.log(`📊 Database: ${connectionType} connection established`);