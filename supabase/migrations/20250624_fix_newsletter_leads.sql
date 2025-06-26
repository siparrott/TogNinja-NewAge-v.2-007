-- Add NEWSLETTER as allowed form_source for leads table
ALTER TABLE leads DROP CONSTRAINT IF EXISTS leads_form_source_check;
ALTER TABLE leads ADD CONSTRAINT leads_form_source_check 
  CHECK (form_source IN ('WARTELISTE', 'KONTAKT', 'NEWSLETTER'));

-- Make sure leads table has proper RLS policies
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Add policy for newsletter signups (public inserts)
CREATE POLICY "Allow public newsletter signups" ON leads
  FOR INSERT WITH CHECK (form_source = 'NEWSLETTER');

-- Add policy for reading leads (admin only)
CREATE POLICY "Admin can read all leads" ON leads
  FOR SELECT USING (auth.role() = 'service_role' OR auth.jwt() ->> 'role' = 'admin');

-- Add policy for updating leads (admin only)  
CREATE POLICY "Admin can update leads" ON leads
  FOR UPDATE USING (auth.role() = 'service_role' OR auth.jwt() ->> 'role' = 'admin');

-- Add policy for deleting leads (admin only)
CREATE POLICY "Admin can delete leads" ON leads
  FOR DELETE USING (auth.role() = 'service_role' OR auth.jwt() ->> 'role' = 'admin');
