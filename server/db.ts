import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import ws from "ws";
import * as schema from "../shared/schema.js";

neonConfig.webSocketConstructor = ws;

// Use Neon temporarily until Supabase connection string is working
const neonUrl = process.env.DATABASE_URL;

if (!neonUrl) {
  throw new Error("DATABASE_URL must be set");
}

export const pool = new Pool({ 
  connectionString: neonUrl,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

export const db = drizzle(pool, { schema });

console.log(`📊 Database: Neon connection (Supabase ready when working connection provided)`);