-- Test if the enhanced invoicing tables exist
-- This query will check for the main tables we need

SELECT 
    tablename,
    schemaname
FROM pg_tables 
WHERE 
    tablename IN (
        'crm_invoices',
        'crm_invoice_items', 
        'crm_invoice_payments',
        'crm_invoice_templates',
        'crm_invoice_audit_log',
        'crm_clients'
    )
    AND schemaname = 'public'
ORDER BY tablename;

-- Also check if the invoice number generation function exists
SELECT 
    proname,
    pronargs
FROM pg_proc 
WHERE proname = 'generate_invoice_number';
