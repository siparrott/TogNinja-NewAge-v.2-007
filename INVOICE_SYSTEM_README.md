# Professional Invoicing System

## Overview

This is a comprehensive, auditor-standard invoicing system built with React, TypeScript, and Supabase. The system provides full invoice lifecycle management with advanced features for professional accounting and business management.

## Features

### 🧾 Advanced Invoice Management
- **Multi-step Invoice Creation**: Card-based workflow (Client & Details → Line Items → Payment & Terms → Review & Create)
- **Professional Invoice Templates**: Clean, printable invoice layouts
- **Automatic Invoice Numbering**: Sequential numbering with year prefix (INV-25-0001)
- **Multiple Currencies**: Support for EUR, USD, GBP
- **Status Tracking**: Draft → Sent → Paid → Overdue → Cancelled

### 💰 Comprehensive Financial Tracking
- **Line Item Management**: Detailed billing with quantity, unit price, and tax rates
- **Automatic Tax Calculations**: Per-line item tax calculation with configurable rates
- **Discount Support**: Apply discounts to invoices
- **Payment Tracking**: Record multiple payments against invoices
- **Outstanding Balance**: Real-time calculation of remaining amounts

### 📊 Payment Management
- **Multiple Payment Methods**: Bank transfer, credit card, PayPal, Stripe, cash, check
- **Payment History**: Complete audit trail of all payments
- **Partial Payments**: Support for multiple payments against one invoice
- **Automatic Status Updates**: Invoices automatically marked as paid when fully paid

### 🔍 Audit & Compliance
- **Audit Log**: Complete trail of all invoice changes
- **User Tracking**: Track who made what changes and when
- **PDF Generation**: Professional PDF output for invoices
- **Print Support**: Optimized printing layouts

### 📈 Business Intelligence
- **Dashboard Statistics**: Total invoiced, paid amounts, overdue tracking
- **Search & Filtering**: Find invoices by number, client, status
- **Status Management**: Visual status indicators and quick status changes

## Database Schema

### Core Tables

#### `crm_invoices`
Main invoice table with all invoice header information:
```sql
- id (uuid, primary key)
- invoice_number (text, auto-generated)
- client_id (uuid, foreign key to crm_clients)
- amount (decimal, subtotal)
- tax_amount (decimal, calculated)
- total_amount (decimal, final total)
- subtotal_amount (decimal)
- discount_amount (decimal)
- currency (text, default 'EUR')
- status (enum: draft, sent, paid, overdue, cancelled)
- due_date (date)
- paid_date (date, nullable)
- sent_date (timestamp, nullable)
- payment_terms (text, default 'Net 30')
- notes (text, nullable)
- pdf_url (text, nullable)
- template_id (uuid, nullable)
- created_at (timestamp)
- updated_at (timestamp)
- created_by (uuid, foreign key to auth.users)
```

#### `crm_invoice_items`
Line items for detailed billing:
```sql
- id (uuid, primary key)
- invoice_id (uuid, foreign key to crm_invoices)
- description (text, required)
- quantity (decimal, default 1)
- unit_price (decimal, required)
- tax_rate (decimal, default 0)
- tax_amount (decimal, computed)
- line_total (decimal, computed)
- sort_order (integer, default 0)
- created_at (timestamp)
```

#### `crm_invoice_payments`
Payment tracking:
```sql
- id (uuid, primary key)
- invoice_id (uuid, foreign key to crm_invoices)
- amount (decimal, required)
- payment_method (enum: bank_transfer, credit_card, paypal, stripe, cash, check)
- payment_reference (text, nullable)
- payment_date (date, required)
- notes (text, nullable)
- created_by (uuid, foreign key to auth.users)
- created_at (timestamp)
```

#### `crm_invoice_audit_log`
Complete audit trail:
```sql
- id (uuid, primary key)
- invoice_id (uuid, foreign key to crm_invoices)
- action (text: created, updated, sent, paid, cancelled)
- old_values (jsonb, nullable)
- new_values (jsonb, nullable)
- user_id (uuid, foreign key to auth.users)
- user_email (text)
- ip_address (inet, nullable)
- user_agent (text, nullable)
- created_at (timestamp)
```

#### `crm_invoice_templates`
Customizable invoice templates:
```sql
- id (uuid, primary key)
- name (text, required)
- is_default (boolean, default false)
- header_html (text, nullable)
- footer_html (text, nullable)
- terms_and_conditions (text, nullable)
- payment_instructions (text, nullable)
- logo_url (text, nullable)
- color_scheme (jsonb, default colors)
- created_by (uuid, foreign key to auth.users)
- created_at (timestamp)
- updated_at (timestamp)
```

### Automated Functions

#### `generate_invoice_number()`
Automatically generates sequential invoice numbers with year prefix:
- Format: `INV-YY-NNNN` (e.g., INV-25-0001)
- Resets sequence each year
- Handles concurrent access safely

#### `update_invoice_totals(invoice_uuid)`
Automatically calculates and updates invoice totals:
- Calculates subtotal from line items
- Calculates total tax from line items
- Applies discounts
- Updates invoice totals

### Triggers
- Automatic invoice total calculation when line items change
- Audit log entries for all invoice modifications

## Components

### Main Components

#### `AdvancedInvoiceForm`
Multi-step invoice creation form with:
- Step 1: Client selection and basic invoice details
- Step 2: Line item management with dynamic add/remove
- Step 3: Payment terms and discount configuration
- Step 4: Review and final creation

#### `InvoiceViewer`
Professional invoice display with:
- Print-optimized layout
- PDF generation capabilities
- Send invoice functionality
- Professional template rendering

#### `PaymentTracker`
Comprehensive payment management:
- Payment history display
- Add new payments
- Multiple payment methods
- Automatic balance calculations

#### `InvoiceTemplate`
Professional invoice template with:
- Company header information
- Client billing details
- Itemized line items
- Tax and discount calculations
- Payment terms and notes

### API Functions

#### Invoice Management
- `createInvoice(payload)` - Create new invoice with line items
- `getInvoice(id)` - Retrieve invoice with all related data
- `listInvoices()` - Get all invoices with client information
- `updateInvoiceStatus(id, status)` - Update invoice status with audit trail
- `deleteInvoice(id)` - Delete invoice with audit logging

#### Payment Management
- `addInvoicePayment(invoiceId, payment)` - Record new payment
- Automatic invoice status updates when fully paid

## Security & Permissions

### Row Level Security (RLS)
All tables have RLS enabled with policies for:
- Authenticated users can view all invoices
- Authenticated users can manage invoices they created
- Audit log is append-only for authenticated users

### Data Validation
- Required field validation
- Currency amount formatting
- Date validation
- Tax rate limits (0-100%)

## Usage

### Creating an Invoice

1. **Navigate to Admin → Invoices**
2. **Click "Create Invoice"**
3. **Step 1 - Client & Details:**
   - Select existing client from dropdown
   - Set due date
   - Choose currency

4. **Step 2 - Line Items:**
   - Add description, quantity, unit price
   - Set tax rate per item
   - Add multiple items as needed
   - Real-time total calculation

5. **Step 3 - Payment & Terms:**
   - Set payment terms (Net 15/30/60)
   - Apply discounts if needed
   - Add invoice notes

6. **Step 4 - Review & Create:**
   - Review all details
   - Confirm and create invoice

### Managing Payments

1. **From invoice list, click payment tracking button**
2. **View payment summary and history**
3. **Add new payments:**
   - Enter payment amount
   - Select payment method
   - Set payment date
   - Add reference number
   - Include notes

### Viewing & Printing Invoices

1. **Click "View" button on any invoice**
2. **Professional invoice template displays**
3. **Options available:**
   - Print invoice
   - Download as PDF
   - Send via email (integration required)

## Installation & Setup

### Prerequisites
- React 18+ with TypeScript
- Supabase project
- Node.js 16+

### Database Setup
1. Apply the enhanced invoicing migration:
   ```sql
   -- Apply the migration file: 20250623_enhanced_invoicing_system.sql
   ```

2. Ensure you have a `crm_clients` table for client management

### Environment Variables
```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Component Integration
```typescript
import AdvancedInvoiceForm from './components/admin/AdvancedInvoiceForm';
import PaymentTracker from './components/admin/PaymentTracker';
import InvoiceViewer from './components/admin/InvoiceViewer';
```

## Compliance & Standards

### Auditor Standards
- Complete audit trail of all changes
- User attribution for all actions
- Immutable payment records
- Sequential invoice numbering
- Proper tax calculations

### Accounting Standards
- Separate tax tracking per line item
- Discount handling
- Multiple payment support
- Outstanding balance calculations
- Professional invoice formatting

### Data Integrity
- Foreign key constraints
- Computed columns for totals
- Automatic calculation triggers
- Row-level security

## Future Enhancements

### Planned Features
- [ ] Email integration for sending invoices
- [ ] Recurring invoice support
- [ ] Invoice templates editor
- [ ] Multi-language support
- [ ] Advanced reporting and analytics
- [ ] Integration with accounting software
- [ ] Mobile-responsive invoice viewer
- [ ] Bulk invoice operations

### Integration Opportunities
- Stripe/PayPal payment processing
- Email service providers (SendGrid, AWS SES)
- PDF generation services
- Accounting software (QuickBooks, Xero)
- CRM systems

## Support

For technical support or feature requests, please refer to the project documentation or contact the development team.

---

**Built with ❤️ using React, TypeScript, and Supabase**
