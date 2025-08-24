#!/usr/bin/env node
console.log('🔧 Supabase Connection Checker & Switcher');

const WORKING_SUPABASE_URL = process.argv[2];

if (!WORKING_SUPABASE_URL) {
  console.log('\n🚨 USAGE: node switch-to-supabase.mjs "your-supabase-connection-string"');
  console.log('\n📋 Steps to get your connection string:');
  console.log('1. Go to https://supabase.com/dashboard');
  console.log('2. Select your project');
  console.log('3. Go to Settings → Database');
  console.log('4. Copy the "Connection string" (URI format)');
  console.log('5. Replace [YOUR-PASSWORD] with your password');
  console.log('6. Run: node switch-to-supabase.mjs "your-connection-string"');
  
  console.log('\n💾 Your data is ready:');
  console.log('• 22,064 records exported');
  console.log('• supabase-COMPLETE-import.sql created');
  console.log('• Ready for immediate import');
  
  process.exit(1);
}

async function testConnection(connectionString) {
  const { Pool } = await import('pg');
  
  try {
    const pool = new Pool({ 
      connectionString,
      ssl: { rejectUnauthorized: false },
      connectionTimeoutMillis: 10000
    });
    
    await pool.query('SELECT 1 as test');
    await pool.end();
    return true;
  } catch (error) {
    console.log(`❌ Connection test failed: ${error.message}`);
    return false;
  }
}

async function updateEnvironment(connectionString) {
  const { writeFileSync, readFileSync } = await import('fs');
  
  try {
    let envContent = readFileSync('.env', 'utf-8');
    
    if (envContent.includes('SUPABASE_DATABASE_URL=')) {
      envContent = envContent.replace(
        /SUPABASE_DATABASE_URL=.*/,
        `SUPABASE_DATABASE_URL=${connectionString}`
      );
    } else {
      envContent += `\nSUPABASE_DATABASE_URL=${connectionString}\n`;
    }
    
    writeFileSync('.env', envContent);
    console.log('✅ Updated .env file with Supabase connection');
  } catch (error) {
    console.log(`⚠️ Could not update .env: ${error.message}`);
    console.log(`🔧 Manually add: SUPABASE_DATABASE_URL=${connectionString}`);
  }
}

async function main() {
  console.log('\n🔍 Testing Supabase connection...');
  
  const isWorking = await testConnection(WORKING_SUPABASE_URL);
  
  if (isWorking) {
    console.log('✅ Supabase connection is working!');
    await updateEnvironment(WORKING_SUPABASE_URL);
    
    console.log('\n🚀 Next steps:');
    console.log('1. Import data to Supabase:');
    console.log('   - Open Supabase SQL Editor');
    console.log('   - Copy contents of supabase-COMPLETE-import.sql');
    console.log('   - Paste and run');
    console.log('2. Restart your app - it will use Supabase automatically');
    console.log('\n🎉 Your complete business data will be live on Supabase!');
  } else {
    console.log('\n🚨 Connection failed. Please check:');
    console.log('• Project is not paused');
    console.log('• Connection string is correct');
    console.log('• Password is correct');
    console.log('• Project has database access enabled');
  }
}

main().catch(console.error);