# CRM Agent Tools Registry

## Complete List of 74 Registered Tools

The CRM agent has access to 74 registered tools covering all business operations:

### Communication Tools
- `send_email` - Send emails to clients and leads
- `draft_email` - Create email drafts for review
- `analyze_email` - Analyze incoming emails for sentiment and content
- `monitor_email_account` - Monitor email account for new messages
- `smart_auto_reply` - Generate intelligent auto-replies
- `reply_email` - Reply to specific emails

### Search and Discovery
- `scrape_website_content` - Extract content from websites
- `global_search` - Search across all data sources
- `find_entity` - Find specific entities in database
- `kb_search` - Search knowledge base for information

### CRM Operations
- `count_invoices` - Count invoices with filters
- `count_sessions` - Count photography sessions
- `count_leads` - Count leads in pipeline
- `list_leads` - List all leads with filtering
- `create_invoice` - Generate new invoices
- `list_top_clients` - Identify top performing clients
- `get_client_segments` - Analyze client demographics
- `log_interaction` - Record client interactions

### E-commerce and Sales
- `create_gallery_checkout` - Process gallery orders
- `submit_prodigi_order` - Submit print orders to Prodigi
- `create_voucher_product` - Create voucher products
- `sell_voucher` - Process voucher sales
- `read_voucher_sales` - Review voucher sales data
- `redeem_voucher` - Process voucher redemptions

### Calendar and Sessions
- `create_photography_session` - Schedule new photo sessions
- `read_calendar_sessions` - View calendar appointments
- `update_photography_session` - Modify existing sessions
- `cancel_photography_session` - Cancel sessions
- `check_calendar_availability` - Check available time slots

### File Management
- `upload_file` - Upload files to system
- `read_digital_files` - Access digital file library
- `update_digital_file` - Modify file metadata
- `delete_digital_file` - Remove files from system
- `organize_files_by_folder` - Organize file structure

### Content Management
- `create_blog_post` - Create new blog content
- `read_blog_posts` - Access blog post library
- `update_blog_post` - Edit existing blog posts
- `delete_blog_post` - Remove blog posts
- `publish_blog_post` - Publish blog content

### Email Campaigns
- `create_email_campaign` - Design email campaigns
- `read_email_campaigns` - Review campaign data
- `send_email_campaign` - Execute email campaigns
- `update_email_campaign` - Modify campaigns
- `delete_email_campaign` - Remove campaigns

### Questionnaires and Surveys
- `create_questionnaire` - Build customer questionnaires
- `read_questionnaires` - Access questionnaire library
- `send_questionnaire` - Distribute questionnaires
- `read_questionnaire_responses` - Analyze responses
- `update_questionnaire` - Modify questionnaires

### Analytics and Reporting
- `generate_business_report` - Create business reports
- `get_kpi_dashboard` - Access KPI metrics
- `export_data_analytics` - Export analytics data
- `get_performance_metrics` - Retrieve performance data

### System Administration
- `manage_user_accounts` - User account management
- `system_configuration` - System settings
- `database_management` - Database operations
- `system_monitoring` - Monitor system health
- `audit_trail` - Access audit logs

### Integrations
- `manage_integrations` - External service management
- `api_management` - API endpoint management
- `webhook_management` - Webhook configuration
- `data_sync` - Synchronize external data
- `external_service_status` - Check service health

### Automation
- `create_automation_workflow` - Design workflows
- `manage_automated_triggers` - Configure triggers
- `schedule_automated_tasks` - Schedule tasks
- `read_automation_status` - Monitor automation
- `update_automation_settings` - Modify automation

### Customer Portal
- `create_portal_access` - Grant portal access
- `manage_portal_content` - Update portal content
- `read_portal_analytics` - Portal usage analytics
- `update_portal_settings` - Configure portal
- `send_portal_notifications` - Portal notifications

### Agent Capabilities
- `describe_capabilities` - List agent abilities

## Tool Security and Permissions

### Guarded Write Operations
The following tools require approval workflows:
- `create_invoice`
- `send_email`
- `create_photography_session`
- `submit_prodigi_order`
- `sell_voucher`

### Audit Logged Operations
All database modifications are logged:
- User ID and timestamp
- Operation performed
- Data affected
- Approval status

### Read-Only Operations
Safe operations that don't modify data:
- All search and read operations
- Analytics and reporting
- Status monitoring

## Usage Examples

### Customer Inquiry Response
```
Agent receives: "I want to book a family session"
Agent uses: find_entity → check_calendar_availability → create_photography_session
```

### Lead Follow-up
```
Agent uses: list_leads → analyze_email → draft_email → send_email
```

### Order Processing
```
Agent uses: create_gallery_checkout → submit_prodigi_order → create_invoice → send_email
```

## Integration Notes

Each tool is implemented as a separate module in `/agent/tools/` with:
- Input validation using Zod schemas
- Error handling and recovery
- Security checks and permissions
- Audit logging
- Documentation and examples