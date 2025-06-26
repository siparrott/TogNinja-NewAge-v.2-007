#!/usr/bin/env node

/**
 * TogNinja CRM - Post-Deployment Testing Script
 * This script verifies that all critical features are working
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🧪 TogNinja CRM - Post-Deployment Testing');
console.log('==========================================\n');

const tests = {
  environment: [],
  database: [],
  frontend: [],
  backend: []
};

// Test 1: Environment Variables
console.log('📋 Testing Environment Configuration...');
try {
  const envPath = path.join(__dirname, '.env');
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf8');
    const requiredVars = [
      'VITE_SUPABASE_URL',
      'VITE_SUPABASE_ANON_KEY',
      'VITE_SUPABASE_SERVICE_ROLE_KEY',
      'VITE_OPENAI_API_KEY'
    ];
    
    requiredVars.forEach(varName => {
      if (envContent.includes(varName) && !envContent.includes(`${varName}=`)) {
        tests.environment.push(`❌ ${varName} is missing value`);
      } else if (envContent.includes(`${varName}=`)) {
        tests.environment.push(`✅ ${varName} is configured`);
      } else {
        tests.environment.push(`❌ ${varName} is missing`);
      }
    });
  } else {
    tests.environment.push('❌ .env file not found');
    tests.environment.push('ℹ️  Copy .env.example to .env and configure');
  }
} catch (err) {
  tests.environment.push(`❌ Environment test failed: ${err.message}`);
}

// Test 2: Database Schema Files
console.log('🗄️  Testing Database Schema...');
try {
  const schemaPath = path.join(__dirname, 'CRITICAL_DATABASE_SCHEMA.sql');
  if (fs.existsSync(schemaPath)) {
    const schemaContent = fs.readFileSync(schemaPath, 'utf8');
    const requiredTables = [
      'leads',
      'invoices',
      'gallery_albums',
      'gallery_images',
      'newsletter_subscribers',
      'digital_files',
      'questionnaire_responses'
    ];
    
    requiredTables.forEach(table => {
      if (schemaContent.toLowerCase().includes(`create table ${table}`) || 
          schemaContent.toLowerCase().includes(`create table if not exists ${table}`)) {
        tests.database.push(`✅ ${table} table schema exists`);
      } else {
        tests.database.push(`❌ ${table} table schema missing`);
      }
    });
  } else {
    tests.database.push('❌ Database schema file not found');
  }
} catch (err) {
  tests.database.push(`❌ Database schema test failed: ${err.message}`);
}

// Test 3: Critical Files
console.log('📁 Testing Critical Files...');
try {
  const criticalFiles = [
    'src/lib/supabase.ts',
    'src/lib/invoicing.ts',
    'src/lib/newsletter.ts',
    'src/lib/calendar.ts',
    'src/components/newsletter/NewsletterManager.tsx',
    'src/components/calendar/CalendarIntegration.tsx',
    'src/components/gallery/GalleryGrid.tsx',
    'src/utils/i18n.tsx',
    'src/pages/admin/AdminLeadsPage.tsx',
    'src/pages/admin/AdminInvoicesPage.tsx'
  ];
  
  criticalFiles.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
      tests.frontend.push(`✅ ${file} exists`);
    } else {
      tests.frontend.push(`❌ ${file} missing`);
    }
  });
} catch (err) {
  tests.frontend.push(`❌ File test failed: ${err.message}`);
}

// Test 4: Build Process
console.log('🔨 Testing Build Process...');
try {
  console.log('Running build test...');
  execSync('npm run build', { stdio: 'pipe' });
  tests.frontend.push('✅ Build process successful');
} catch (err) {
  tests.frontend.push('❌ Build process failed');
  tests.frontend.push(`   Error: ${err.message.substring(0, 100)}...`);
}

// Test 5: Package Dependencies
console.log('📦 Testing Dependencies...');
try {
  const packagePath = path.join(__dirname, 'package.json');
  if (fs.existsSync(packagePath)) {
    const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
    const requiredDeps = [
      '@supabase/supabase-js',
      'react',
      'react-router-dom',
      'lucide-react',
      'tailwindcss',
      'framer-motion'
    ];
    
    requiredDeps.forEach(dep => {
      if (packageJson.dependencies?.[dep] || packageJson.devDependencies?.[dep]) {
        tests.backend.push(`✅ ${dep} dependency installed`);
      } else {
        tests.backend.push(`❌ ${dep} dependency missing`);
      }
    });
  } else {
    tests.backend.push('❌ package.json not found');
  }
} catch (err) {
  tests.backend.push(`❌ Dependencies test failed: ${err.message}`);
}

// Results Summary
console.log('\n📊 TEST RESULTS SUMMARY');
console.log('=======================\n');

console.log('🌍 Environment Configuration:');
tests.environment.forEach(result => console.log(`   ${result}`));

console.log('\n🗄️  Database Schema:');
tests.database.forEach(result => console.log(`   ${result}`));

console.log('\n🎨 Frontend Files:');
tests.frontend.forEach(result => console.log(`   ${result}`));

console.log('\n⚙️  Backend & Dependencies:');
tests.backend.forEach(result => console.log(`   ${result}`));

// Overall Status
const totalTests = tests.environment.length + tests.database.length + tests.frontend.length + tests.backend.length;
const passedTests = [
  ...tests.environment,
  ...tests.database,
  ...tests.frontend,
  ...tests.backend
].filter(test => test.includes('✅')).length;

const failedTests = totalTests - passedTests;

console.log('\n🎯 OVERALL STATUS');
console.log('==================');
console.log(`✅ Passed: ${passedTests}/${totalTests}`);
console.log(`❌ Failed: ${failedTests}/${totalTests}`);

if (failedTests === 0) {
  console.log('\n🎉 ALL TESTS PASSED! Your deployment is ready.');
  console.log('Next steps:');
  console.log('1. Deploy database schema to Supabase');
  console.log('2. Configure environment variables in Netlify');
  console.log('3. Deploy Supabase Edge Functions');
  console.log('4. Test all features on live site');
} else {
  console.log('\n⚠️  Some tests failed. Please review and fix the issues above.');
  console.log('Priority actions:');
  
  if (tests.environment.some(t => t.includes('❌'))) {
    console.log('- Configure missing environment variables');
  }
  if (tests.database.some(t => t.includes('❌'))) {
    console.log('- Deploy database schema to Supabase');
  }
  if (tests.frontend.some(t => t.includes('❌'))) {
    console.log('- Restore missing frontend files');
  }
  if (tests.backend.some(t => t.includes('❌'))) {
    console.log('- Install missing dependencies');
  }
}

console.log('\n📚 For detailed setup instructions, see:');
console.log('   - CRITICAL_DEPLOYMENT_FIXES.md');
console.log('   - NETLIFY_ENVIRONMENT_SETUP.md');
console.log('   - SUPABASE_EDGE_FUNCTIONS_SETUP.md');

process.exit(failedTests > 0 ? 1 : 0);
