# Voucher Sales Integration - Complete Flow Documentation

## Overview
This document explains how online voucher sales from the frontend are integrated with the admin dashboard to ensure all purchases are properly tracked and displayed.

## Integration Flow

### 1. Frontend Purchase Flow
**File**: `src/pages/CheckoutPage.tsx`

When a user purchases a voucher:
1. User fills out checkout form with name, email, and quantity
2. Form validation ensures required fields are present
3. On successful form submission, `purchaseVoucher()` is called

```typescript
// From CheckoutPage.tsx
await purchaseVoucher({
  purchaserName,
  purchaserEmail,
  amount: totalPrice,
  paymentIntentId,
  voucherType: voucher.category
});
```

### 2. API Layer
**File**: `src/lib/voucher.ts`

The `purchaseVoucher()` function:
1. Sends POST request to Supabase function endpoint
2. Endpoint: `/functions/v1/public/voucher/purchase`
3. Includes all purchase data in request body

```typescript
export async function purchaseVoucher(data: VoucherPurchaseData) {
  const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/public/voucher/purchase`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return await response.json();
}
```

### 3. Backend Processing
**File**: `supabase/functions/public/index.ts`

The backend function:
1. Validates required fields
2. Generates unique voucher code
3. Saves purchase to `voucher_sales` table

```typescript
// Insert into voucher_sales table
const { data, error } = await supabase
  .from('voucher_sales')
  .insert({
    purchaser_name: purchaseData.purchaserName,
    purchaser_email: purchaseData.purchaserEmail,
    voucher_code: voucherCode,
    amount: purchaseData.amount,
    currency: 'EUR',
    payment_intent_id: purchaseData.paymentIntentId,
    voucher_type: purchaseData.voucherType || 'GENERAL',
    fulfilled: false
  })
```

### 4. Database Schema
**File**: `supabase/migrations/20250618151818_rough_scene.sql`

The `voucher_sales` table stores:
- `id`: Unique identifier
- `purchaser_name`: Customer name
- `purchaser_email`: Customer email
- `voucher_code`: Generated unique voucher code
- `amount`: Purchase amount
- `currency`: Currency (default EUR)
- `payment_intent_id`: Payment reference
- `voucher_type`: Voucher category
- `fulfilled`: Whether voucher has been used
- `created_at`: Purchase timestamp

### 5. Admin Dashboard
**File**: `src/pages/admin/AdminVoucherSalesPage.tsx`

The admin dashboard:
1. Fetches data using `getVoucherSales()` from `voucher_sales` table
2. Displays metrics: total sales, revenue, average order value
3. Shows filterable table of all voucher purchases
4. Allows toggling fulfillment status
5. Provides CSV export functionality

```typescript
const fetchVoucherSales = async () => {
  const data = await getVoucherSales();
  setSales(data);
};
```

### 6. Navigation Access
**File**: `src/components/admin/AdminLayout.tsx`

Admin users can access the voucher sales dashboard via:
- Path: `/admin/voucher-sales`
- Navigation label: "Online Voucher Sales"
- Icon: ShoppingCart

## Data Flow Summary

```
User Purchase (Frontend) 
    ↓
CheckoutPage.tsx calls purchaseVoucher()
    ↓
lib/voucher.ts sends POST to Supabase function
    ↓
supabase/functions/public/index.ts processes purchase
    ↓
Data saved to voucher_sales table
    ↓
AdminVoucherSalesPage.tsx fetches and displays data
    ↓
Admin sees real-time voucher sales metrics and list
```

## Verification Checklist

✅ **Frontend Integration**: CheckoutPage uses purchaseVoucher() function
✅ **API Layer**: purchaseVoucher() sends data to correct endpoint
✅ **Backend Endpoint**: /public/voucher/purchase route implemented
✅ **Database Storage**: voucher_sales table properly structured
✅ **Admin Dashboard**: AdminVoucherSalesPage fetches from voucher_sales
✅ **Navigation**: Admin can access voucher sales page
✅ **Data Integrity**: All purchase data is preserved and displayed

## Testing Integration

To test the complete integration:

1. **Purchase a voucher** via the frontend checkout process
2. **Check the database** to ensure the purchase is recorded in `voucher_sales`
3. **View the admin dashboard** at `/admin/voucher-sales` to confirm the purchase appears
4. **Verify metrics** are updated correctly (total sales, revenue, etc.)
5. **Test filtering** by date range and fulfillment status
6. **Test fulfillment toggle** to mark vouchers as used

## Key Files Modified/Created

1. **Enhanced Backend**: Added voucher purchase endpoint to `supabase/functions/public/index.ts`
2. **Database Migration**: Added voucher_type column via `supabase/migrations/20250623_add_voucher_type.sql`
3. **Test File**: Created integration test at `src/test/voucher-integration.test.ts`
4. **Documentation**: This comprehensive flow documentation

## Result

✅ **Integration Complete**: Online voucher sales from the frontend now properly reflect on the admin "Online Voucher Sales" page with full end-to-end tracking, metrics, and management capabilities.
