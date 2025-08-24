#!/usr/bin/env node

/**
 * Dual Database Backup Configuration Script
 * Sets up primary/backup database configuration
 */

import fs from 'fs/promises';

async function setupBackupConfig() {
  console.log('🔄 Setting up dual database configuration...');
  
  // Get current DATABASE_URL from environment
  const currentDbUrl = process.env.DATABASE_URL;
  
  if (!currentDbUrl) {
    console.error('❌ No DATABASE_URL found in environment');
    process.exit(1);
  }
  
  console.log('📋 Current database:', currentDbUrl.substring(0, 50) + '...');
  
  // New Neon account URL
  const newDbUrl = 'postgresql://neondb_owner:npg_D2bKWziIZj1G@ep-morning-star-a2i1gglu-pooler.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require';
  
  // Create backup configuration
  const backupConfig = `# Database Configuration - Dual Setup
# Primary: New Neon Account (Production)
DATABASE_URL=${newDbUrl}

# Backup: Original Database (Replit Backup)
BACKUP_DATABASE_URL=${currentDbUrl}

# Migration Notes
# - Data migrated on ${new Date().toISOString()}
# - Original data preserved in BACKUP_DATABASE_URL
# - Can rollback by swapping URLs
`;

  // Read current .env
  let envContent = '';
  try {
    envContent = await fs.readFile('.env', 'utf8');
  } catch (error) {
    console.log('📝 Creating new .env file...');
  }
  
  // Remove existing DATABASE_URL line
  const envLines = envContent.split('\n').filter(line => 
    !line.startsWith('DATABASE_URL=') && 
    !line.startsWith('BACKUP_DATABASE_URL=')
  );
  
  // Add new configuration at the top
  const newEnvContent = backupConfig + '\n' + envLines.join('\n');
  
  // Write updated .env
  await fs.writeFile('.env', newEnvContent);
  
  console.log('✅ Backup configuration complete!');
  console.log('');
  console.log('Configuration:');
  console.log('- Primary DB: New Neon Account');
  console.log('- Backup DB: Original Replit Database');
  console.log('');
  console.log('🔄 Restart application to use new database');
  console.log('🔙 Rollback: Swap DATABASE_URL and BACKUP_DATABASE_URL');
}

setupBackupConfig().catch(console.error);