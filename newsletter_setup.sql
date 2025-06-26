-- This script applies the newsletter signup fixes to the database
-- Run this in your Supabase SQL editor

-- Step 1: Update the form_source constraint to allow NEWSLETTER
ALTER TABLE leads DROP CONSTRAINT IF EXISTS leads_form_source_check;
ALTER TABLE leads ADD CONSTRAINT leads_form_source_check 
  CHECK (form_source IN ('WARTELISTE', 'KONTAKT', 'NEWSLETTER'));

-- Step 2: Enable RLS if not already enabled
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Step 3: Create policy for public newsletter signups
DROP POLICY IF EXISTS "Allow public newsletter signups" ON leads;
CREATE POLICY "Allow public newsletter signups" ON leads
  FOR INSERT WITH CHECK (form_source IN ('NEWSLETTER', 'KONTAKT'));

-- Step 4: Ensure newsletter_subscribers table exists
CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email text UNIQUE NOT NULL,
  active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Step 5: Enable RLS on newsletter_subscribers
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;

-- Step 6: Create policy for public newsletter subscriber inserts
DROP POLICY IF EXISTS "Allow public newsletter subscription" ON newsletter_subscribers;
CREATE POLICY "Allow public newsletter subscription" ON newsletter_subscribers
  FOR INSERT WITH CHECK (true);

-- Step 7: Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Step 8: Create trigger for newsletter_subscribers
DROP TRIGGER IF EXISTS update_newsletter_subscribers_updated_at ON newsletter_subscribers;
CREATE TRIGGER update_newsletter_subscribers_updated_at 
    BEFORE UPDATE ON newsletter_subscribers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 9: Test the setup
DO $$
BEGIN
  -- Test if we can insert a newsletter lead
  INSERT INTO leads (first_name, last_name, email, message, form_source, status)
  VALUES ('Test', 'Newsletter', 'test-newsletter@example.com', 'Newsletter signup test', 'NEWSLETTER', 'NEW');
  
  -- Test if we can insert a newsletter subscriber
  INSERT INTO newsletter_subscribers (email)
  VALUES ('test-newsletter@example.com');
  
  -- Clean up test data
  DELETE FROM leads WHERE email = 'test-newsletter@example.com';
  DELETE FROM newsletter_subscribers WHERE email = 'test-newsletter@example.com';
  
  RAISE NOTICE 'Newsletter signup setup completed successfully!';
END
$$;
