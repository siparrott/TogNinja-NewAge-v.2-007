-- Create Leads Table
CREATE TABLE IF NOT EXISTS leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  form_source text NOT NULL CHECK (form_source IN ('WARTELISTE', 'KONTAKT')),
  first_name text,
  last_name text,
  email text NOT NULL,
  phone text,
  message text,
  created_at timestamptz DEFAULT now(),
  status text DEFAULT 'NEW' CHECK (status IN ('NEW', 'CONTACTED', 'CONVERTED'))
);

-- Create VoucherSales Table
CREATE TABLE IF NOT EXISTS voucher_sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchaser_name text NOT NULL,
  purchaser_email text NOT NULL,
  voucher_code text UNIQUE NOT NULL,
  amount decimal(10,2) NOT NULL,
  currency text DEFAULT 'EUR',
  payment_intent_id text,
  fulfilled boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE voucher_sales ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Admin users can manage leads" ON leads;
DROP POLICY IF EXISTS "Admin users can manage voucher_sales" ON voucher_sales;

-- Create admin-only policies for leads
CREATE POLICY "Admin users can manage leads"
  ON leads FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create admin-only policies for voucher_sales
CREATE POLICY "Admin users can manage voucher_sales"
  ON voucher_sales FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_leads_form_source ON leads(form_source);
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at);
CREATE INDEX IF NOT EXISTS idx_voucher_sales_created_at ON voucher_sales(created_at);
CREATE INDEX IF NOT EXISTS idx_voucher_sales_voucher_code ON voucher_sales(voucher_code);