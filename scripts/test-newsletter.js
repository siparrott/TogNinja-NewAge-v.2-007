const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_SERVICE_ROLE_KEY
);

async function testNewsletterSignup() {
  console.log('Testing newsletter signup...');
  
  const testEmail = 'test@example.com';
  
  try {
    // Test 1: Check if leads table exists and what form_source values are allowed
    console.log('\n1. Testing leads table structure...');
    const { data: tableInfo, error: tableError } = await supabase
      .from('leads')
      .select('*')
      .limit(1);
    
    if (tableError) {
      console.error('Error accessing leads table:', tableError);
      return;
    }
    
    console.log('✓ Leads table accessible');
    
    // Test 2: Try to insert a newsletter lead
    console.log('\n2. Testing newsletter lead insertion...');
    
    // First, clean up any existing test data
    await supabase
      .from('leads')
      .delete()
      .eq('email', testEmail);
    
    const leadData = {
      first_name: 'Newsletter',
      last_name: 'Subscriber',
      email: testEmail,
      message: 'Newsletter signup - €50 Print Gutschein (Test)',
      form_source: 'KONTAKT', // Using KONTAKT as it should be allowed
      status: 'NEW'
    };
    
    const { data: leadResult, error: leadError } = await supabase
      .from('leads')
      .insert([leadData])
      .select()
      .single();
    
    if (leadError) {
      console.error('Error inserting lead:', leadError);
    } else {
      console.log('✓ Lead inserted successfully:', leadResult.id);
    }
    
    // Test 3: Try to insert into newsletter_subscribers table
    console.log('\n3. Testing newsletter_subscribers table...');
    
    // Clean up existing test data
    await supabase
      .from('newsletter_subscribers')
      .delete()
      .eq('email', testEmail);
    
    const { data: subResult, error: subError } = await supabase
      .from('newsletter_subscribers')
      .insert([{ 
        email: testEmail,
        active: true
      }])
      .select()
      .single();
    
    if (subError) {
      console.error('Error inserting newsletter subscriber:', subError);
    } else {
      console.log('✓ Newsletter subscriber inserted successfully:', subResult.id);
    }
    
    // Test 4: Check what form_source values are currently allowed
    console.log('\n4. Testing different form_source values...');
    
    const testSources = ['KONTAKT', 'WARTELISTE', 'NEWSLETTER'];
    
    for (const source of testSources) {
      try {
        const testData = {
          first_name: 'Test',
          last_name: 'User',
          email: `test-${source.toLowerCase()}@example.com`,
          message: `Test message for ${source}`,
          form_source: source,
          status: 'NEW'
        };
        
        const { error } = await supabase
          .from('leads')
          .insert([testData]);
        
        if (error) {
          console.log(`✗ ${source}: ${error.message}`);
        } else {
          console.log(`✓ ${source}: Allowed`);
          // Clean up
          await supabase
            .from('leads')
            .delete()
            .eq('email', testData.email);
        }
      } catch (err) {
        console.log(`✗ ${source}: ${err.message}`);
      }
    }
    
    // Cleanup
    console.log('\n5. Cleaning up test data...');
    await supabase
      .from('leads')
      .delete()
      .eq('email', testEmail);
    
    await supabase
      .from('newsletter_subscribers')
      .delete()
      .eq('email', testEmail);
    
    console.log('✓ Test cleanup complete');
    
  } catch (error) {
    console.error('Test failed:', error);
  }
}

testNewsletterSignup();
