# CRM Operations Assistant Setup Guide

## Overview
The CRM Operations Assistant is an AI-powered interface that can perform actual business operations in your photography CRM system. Unlike traditional chatbots that only provide suggestions, this assistant can execute real actions like sending emails, creating bookings, managing clients, and generating reports.

## Features
- 📧 **Email Automation**: Reply to clients, send booking confirmations, follow-ups
- 📅 **Appointment Management**: Create, update, cancel appointments and bookings
- 👥 **Client Operations**: Add, update, search client records
- 💰 **Invoice Management**: Generate, send, track invoices and payments
- 📊 **Data Operations**: Run reports, analyze metrics, export data
- ⚡ **Task Automation**: Automate routine business processes

## Setup Instructions

### 1. Create OpenAI Assistant
1. Go to [OpenAI Platform](https://platform.openai.com/assistants)
2. Create a new assistant with these settings:
   - **Name**: CRM Operations Assistant
   - **Model**: gpt-4-turbo-preview (recommended)
   - **Instructions**: 
   ```
   You are a CRM Operations Assistant for TogNinja, a photography business CRM system.

   Your primary functions:
   📧 EMAIL MANAGEMENT: Reply to client emails, send booking confirmations, follow-ups
   📅 APPOINTMENT SCHEDULING: Create, modify, cancel appointments and bookings
   👥 CLIENT MANAGEMENT: Add, update, search client records and information
   💰 INVOICE MANAGEMENT: Generate, send, track invoices and payments
   📊 DATA OPERATIONS: Run reports, analyze data, export information
   ⚡ TASK AUTOMATION: Automate routine business processes

   When you can perform an action, respond with:
   CRM_ACTION: {"type": "email|booking|client|invoice|data|calendar", "action": "specific_action", "data": {...}}

   Available actions:
   - EMAIL: send_booking_confirmation, reply_to_client, send_follow_up, send_invoice_reminder
   - BOOKING: create_appointment, update_booking, cancel_booking, send_confirmation
   - CLIENT: add_client, update_client, search_clients, export_client_data
   - INVOICE: generate_invoice, send_invoice, update_payment_status, send_reminder
   - DATA: run_report, export_data, analyze_metrics, backup_data
   - CALENDAR: schedule_appointment, block_time, send_calendar_invite

   Always be professional, efficient, and ask for clarification when needed.
   Confirm actions before executing them and provide clear status updates.
   ```

3. Copy the Assistant ID (starts with `asst_`)

### 2. Configure Environment Variables
Add to your `.env` file:
```env
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
CRM_ASSISTANT_ID=asst_your_crm_assistant_id_here

# Supabase Configuration (if using Supabase Edge Functions)
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 3. Deploy Supabase Edge Functions
1. Create the CRM message function:
```bash
supabase functions new openai-send-crm-message
```

2. Copy the code from `supabase/functions/openai-send-crm-message/index.ts`

3. Deploy the function:
```bash
supabase functions deploy openai-send-crm-message
```

4. Set environment variables:
```bash
supabase secrets set OPENAI_API_KEY=your_key_here
supabase secrets set SUPABASE_URL=your_supabase_url
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_key
```

### 4. Update Assistant ID
In `src/pages/admin/AdminDashboardPage.tsx`, update the assistant ID:
```typescript
const CRM_ASSISTANT_ID = 'asst_your_actual_crm_assistant_id_here';
```

## Usage Examples

### Email Operations
- "Reply to John's email about his wedding booking"
- "Send booking confirmations for all appointments tomorrow"
- "Send payment reminders to clients with overdue invoices"
- "Follow up with leads from last week"

### Booking Management
- "Create an appointment for Sarah on Friday at 2 PM"
- "Cancel the booking for Smith family on Saturday"
- "Reschedule Jane's session to next week"
- "Block my calendar for editing time this afternoon"

### Client Management
- "Add a new client: Emma Johnson, email emma@example.com, phone 555-0123"
- "Update client record for John Smith with new address"
- "Search for all clients in New York area"
- "Export client list for marketing campaign"

### Invoice Operations
- "Generate invoice for Michael's wedding photography"
- "Send invoice to all clients with completed sessions"
- "Mark payment received for invoice #123"
- "Create recurring invoice for monthly retainer"

### Data & Reports
- "Run monthly revenue report"
- "Show me booking trends for the last quarter"
- "Export all client data to CSV"
- "Analyze conversion rates from leads to bookings"

## Interface Features

### Quick Actions
The assistant includes quick action buttons for common tasks:
- 📧 Reply to emails
- 📅 Send booking confirmations
- 👥 Add new client
- 💰 Generate invoice

### Smart Context
The assistant understands context from:
- Current dashboard data
- Recent client interactions
- Pending bookings and invoices
- Business metrics and trends

### Action Confirmation
- All actions are confirmed before execution
- Visual feedback when actions are performed
- Error handling with clear explanations
- Status updates for long-running tasks

## Security Features
- Secure API key storage in environment variables
- Supabase RLS (Row Level Security) enforcement
- Action logging for audit trails
- Permission checks before executing operations

## Troubleshooting

### Common Issues
1. **Assistant not responding**: Check OpenAI API key and credits
2. **Actions not executing**: Verify Supabase connection and permissions
3. **CORS errors**: Ensure Edge Functions have proper CORS headers
4. **Database errors**: Check RLS policies and table permissions

### Debug Mode
Enable debug logging in the dashboard:
```typescript
console.log('CRM Action received:', action);
// Check browser console for detailed action logs
```

### Testing Actions
Test individual actions without the AI:
```javascript
// Test direct CRM action
handleCRMAction({
  type: 'client',
  action: 'add_client',
  data: { name: 'Test Client', email: 'test@example.com' }
});
```

## Advanced Configuration

### Custom Actions
Add custom business-specific actions by extending the `executeCRMAction` function in the Edge Function:

```typescript
case 'custom':
  return await handleCustomAction(action, supabase)
```

### Integration with External Services
- Email services (SendGrid, Mailgun)
- Calendar systems (Google Calendar, Outlook)
- Payment processors (Stripe, PayPal)
- Booking platforms (Calendly, Acuity)

### Workflow Automation
Create complex workflows by chaining actions:
```
1. Create appointment
2. Send confirmation email
3. Add to calendar
4. Generate invoice
5. Set follow-up reminder
```

## Performance Notes
- Assistant responses typically take 2-5 seconds
- Database operations are optimized for speed
- Large data exports may take longer
- Rate limiting applies to OpenAI API calls

## Future Enhancements
- Voice interface for hands-free operation
- Mobile app integration
- Advanced workflow builder
- Custom AI training on business data
- Integration with photography equipment
- Automated social media posting
- Client portal notifications

## Support
For issues with the CRM Operations Assistant:
1. Check the browser console for error messages
2. Verify Supabase Edge Function logs
3. Test OpenAI assistant in the Playground
4. Review database permissions and RLS policies

The CRM Operations Assistant transforms your photography business by automating routine tasks and enabling natural language business management!
