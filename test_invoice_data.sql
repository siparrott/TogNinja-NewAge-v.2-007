-- Sample data for testing the invoice system
-- Run this after applying the enhanced invoicing migration

-- Insert a test client (if crm_clients table exists)
INSERT INTO crm_clients (id, name, email, address1, city, country) 
VALUES (
  gen_random_uuid(),
  'Test Client GmbH',
  'test@client.com',
  'Musterstraße 123',
  'Berlin',
  'Germany'
) ON CONFLICT DO NOTHING;

-- Insert default invoice template
INSERT INTO crm_invoice_templates (
  name, 
  is_default, 
  terms_and_conditions, 
  payment_instructions,
  color_scheme
) VALUES (
  'Professional Template',
  true,
  'Payment is due within 30 days of invoice date. Late payments may be subject to a 1.5% monthly service charge.',
  'Please pay by bank transfer to the account details provided. Include the invoice number as reference.',
  '{"primary": "#7C3AED", "secondary": "#6B7280"}'
) ON CONFLICT DO NOTHING;

-- Test query to verify tables exist
SELECT 
  'crm_invoices' as table_name,
  COUNT(*) as record_count
FROM crm_invoices
UNION ALL
SELECT 
  'crm_invoice_items' as table_name,
  COUNT(*) as record_count
FROM crm_invoice_items
UNION ALL
SELECT 
  'crm_invoice_payments' as table_name,
  COUNT(*) as record_count
FROM crm_invoice_payments
UNION ALL
SELECT 
  'crm_invoice_templates' as table_name,
  COUNT(*) as record_count
FROM crm_invoice_templates
UNION ALL
SELECT 
  'crm_clients' as table_name,
  COUNT(*) as record_count
FROM crm_clients;
