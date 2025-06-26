-- Add voucher_type column to voucher_sales table for better categorization
ALTER TABLE voucher_sales 
ADD COLUMN IF NOT EXISTS voucher_type text DEFAULT 'GENERAL';

-- Create index for voucher_type for better query performance
CREATE INDEX IF NOT EXISTS idx_voucher_sales_voucher_type ON voucher_sales(voucher_type);
