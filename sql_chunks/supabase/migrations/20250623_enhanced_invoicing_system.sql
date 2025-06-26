/*
  # Enhanced Professional Invoicing System
  
  This migration creates a comprehensive auditor-standard invoicing system with:
  - Invoice line items for detailed billing
  - Tax calculations and multiple tax rates
  - Payment tracking and methods
  - Invoice templates and customization
  - Audit trail for all changes
  - Professional invoice numbering
*/

-- Invoice Line Items Table
CREATE TABLE IF NOT EXISTS crm_invoice_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid REFERENCES crm_invoices(id) ON DELETE CASCADE NOT NULL,
  description text NOT NULL,
  quantity decimal(10,2) NOT NULL DEFAULT 1,
  unit_price decimal(10,2) NOT NULL,
  tax_rate decimal(5,2) DEFAULT 0,
  tax_amount decimal(10,2) GENERATED ALWAYS AS (quantity * unit_price * tax_rate / 100) STORED,
  line_total decimal(10,2) GENERATED ALWAYS AS (quantity * unit_price + (quantity * unit_price * tax_rate / 100)) STORED,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Invoice Payments Table
CREATE TABLE IF NOT EXISTS crm_invoice_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid REFERENCES crm_invoices(id) ON DELETE CASCADE NOT NULL,
  amount decimal(10,2) NOT NULL,
  payment_method text DEFAULT 'bank_transfer' CHECK (payment_method IN ('bank_transfer', 'credit_card', 'paypal', 'stripe', 'cash', 'check')),
  payment_reference text,
  payment_date date NOT NULL,
  notes text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- Invoice Templates Table
CREATE TABLE IF NOT EXISTS crm_invoice_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  is_default boolean DEFAULT false,
  header_html text,
  footer_html text,
  terms_and_conditions text,
  payment_instructions text,
  logo_url text,
  color_scheme jsonb DEFAULT '{"primary": "#4F46E5", "secondary": "#6B7280"}',
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Invoice Audit Log Table
CREATE TABLE IF NOT EXISTS crm_invoice_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid REFERENCES crm_invoices(id) ON DELETE CASCADE NOT NULL,
  action text NOT NULL, -- 'created', 'updated', 'sent', 'paid', 'cancelled'
  old_values jsonb,
  new_values jsonb,
  user_id uuid REFERENCES auth.users(id),
  user_email text,
  ip_address inet,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

-- Add missing columns to existing crm_invoices table
DO $$
BEGIN
  -- Add invoice template reference
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_invoices' AND column_name = 'template_id') THEN
    ALTER TABLE crm_invoices ADD COLUMN template_id uuid REFERENCES crm_invoice_templates(id);
  END IF;

  -- Add currency support
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_invoices' AND column_name = 'currency') THEN
    ALTER TABLE crm_invoices ADD COLUMN currency text DEFAULT 'EUR';
  END IF;

  -- Add discount support
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_invoices' AND column_name = 'discount_amount') THEN
    ALTER TABLE crm_invoices ADD COLUMN discount_amount decimal(10,2) DEFAULT 0;
  END IF;

  -- Add terms and payment instructions
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_invoices' AND column_name = 'payment_terms') THEN
    ALTER TABLE crm_invoices ADD COLUMN payment_terms text DEFAULT 'Net 30';
  END IF;

  -- Add invoice sent date
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_invoices' AND column_name = 'sent_date') THEN
    ALTER TABLE crm_invoices ADD COLUMN sent_date timestamptz;
  END IF;

  -- Add PDF generation status
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_invoices' AND column_name = 'pdf_url') THEN
    ALTER TABLE crm_invoices ADD COLUMN pdf_url text;
  END IF;

  -- Add subtotal calculation
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'crm_invoices' AND column_name = 'subtotal_amount') THEN
    ALTER TABLE crm_invoices ADD COLUMN subtotal_amount decimal(10,2) DEFAULT 0;
  END IF;
END $$;

-- Create function to generate invoice numbers
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS text AS $$
DECLARE
  year_suffix text;
  sequence_num integer;
  invoice_number text;
BEGIN
  -- Get current year suffix (e.g., "25" for 2025)
  year_suffix := to_char(CURRENT_DATE, 'YY');
  
  -- Get next sequence number for this year
  SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM '[0-9]+$') AS integer)), 0) + 1
  INTO sequence_num
  FROM crm_invoices
  WHERE invoice_number LIKE 'INV-' || year_suffix || '-%';
  
  -- Format: INV-25-0001
  invoice_number := 'INV-' || year_suffix || '-' || LPAD(sequence_num::text, 4, '0');
  
  RETURN invoice_number;
END;
$$ LANGUAGE plpgsql;

-- Create function to update invoice totals
CREATE OR REPLACE FUNCTION update_invoice_totals(invoice_uuid uuid)
RETURNS void AS $$
DECLARE
  subtotal decimal(10,2);
  total_tax decimal(10,2);
  discount decimal(10,2);
  final_total decimal(10,2);
BEGIN
  -- Calculate subtotal from line items
  SELECT COALESCE(SUM(quantity * unit_price), 0)
  INTO subtotal
  FROM crm_invoice_items
  WHERE invoice_id = invoice_uuid;
  
  -- Calculate total tax from line items
  SELECT COALESCE(SUM(tax_amount), 0)
  INTO total_tax
  FROM crm_invoice_items
  WHERE invoice_id = invoice_uuid;
  
  -- Get discount amount
  SELECT COALESCE(discount_amount, 0)
  INTO discount
  FROM crm_invoices
  WHERE id = invoice_uuid;
  
  -- Calculate final total
  final_total := subtotal + total_tax - discount;
  
  -- Update invoice totals
  UPDATE crm_invoices
  SET 
    subtotal_amount = subtotal,
    tax_amount = total_tax,
    amount = subtotal,
    total_amount = final_total,
    updated_at = now()
  WHERE id = invoice_uuid;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update invoice totals when line items change
CREATE OR REPLACE FUNCTION trigger_update_invoice_totals()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM update_invoice_totals(OLD.invoice_id);
    RETURN OLD;
  ELSE
    PERFORM update_invoice_totals(NEW.invoice_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS update_invoice_totals_trigger ON crm_invoice_items;
CREATE TRIGGER update_invoice_totals_trigger
  AFTER INSERT OR UPDATE OR DELETE ON crm_invoice_items
  FOR EACH ROW EXECUTE FUNCTION trigger_update_invoice_totals();

-- Enable RLS on new tables
ALTER TABLE crm_invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_invoice_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_invoice_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_invoice_audit_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for invoice items
CREATE POLICY "Invoice items viewable by authenticated users" 
  ON crm_invoice_items FOR SELECT TO authenticated 
  USING (true);

CREATE POLICY "Invoice items manageable by authenticated users" 
  ON crm_invoice_items FOR ALL TO authenticated 
  USING (true);

-- Create RLS policies for payments
CREATE POLICY "Invoice payments viewable by authenticated users" 
  ON crm_invoice_payments FOR SELECT TO authenticated 
  USING (true);

CREATE POLICY "Invoice payments manageable by authenticated users" 
  ON crm_invoice_payments FOR ALL TO authenticated 
  USING (true);

-- Create RLS policies for templates
CREATE POLICY "Invoice templates viewable by authenticated users" 
  ON crm_invoice_templates FOR SELECT TO authenticated 
  USING (true);

CREATE POLICY "Invoice templates manageable by authenticated users" 
  ON crm_invoice_templates FOR ALL TO authenticated 
  USING (true);

-- Create RLS policies for audit log
CREATE POLICY "Invoice audit log viewable by authenticated users" 
  ON crm_invoice_audit_log FOR SELECT TO authenticated 
  USING (true);

CREATE POLICY "Invoice audit log insertable by authenticated users" 
  ON crm_invoice_audit_log FOR INSERT TO authenticated 
  WITH CHECK (true);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON crm_invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_payments_invoice_id ON crm_invoice_payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_audit_log_invoice_id ON crm_invoice_audit_log(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON crm_invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON crm_invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_client_id ON crm_invoices(client_id);

-- Insert default invoice template
INSERT INTO crm_invoice_templates (name, is_default, terms_and_conditions, payment_instructions)
VALUES (
  'Default Professional Template',
  true,
  'Payment is due within 30 days of invoice date. Late payments may be subject to a 1.5% monthly service charge.',
  'Please pay by bank transfer to the account details provided. Include the invoice number as reference.'
) ON CONFLICT DO NOTHING;
