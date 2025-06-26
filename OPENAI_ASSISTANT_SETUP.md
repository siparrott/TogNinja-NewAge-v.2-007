# OpenAI Assistant Integration for Customization

## Overview
This integration adds an AI-powered chat assistant to the customization page that can help users modify their CRM system settings through natural language conversations.

## Features
- 🤖 **Smart Customization**: AI assistant can understand and apply customization requests
- 🎨 **Theme Changes**: Modify colors, fonts, layouts, and branding
- 📧 **Email Settings**: Update email templates and signatures
- 💬 **Natural Language**: Use conversational commands to make changes
- 🔄 **Real-time Updates**: See changes applied immediately
- 📱 **Responsive Interface**: Works on desktop and mobile

## Setup Instructions

### 1. Create OpenAI Assistant
1. Go to [OpenAI Platform](https://platform.openai.com/assistants)
2. Create a new assistant with these settings:
   - **Name**: CRM Customization Assistant
   - **Instructions**: 
   ```
   You are a customization assistant for a photography CRM system. Help users modify:
   
   - Theme settings (colors, fonts, layouts, logos)
   - Email templates and signatures
   - UI customizations and branding
   - System preferences
   
   When applying changes, format your response with customization data:
   CUSTOMIZATION_UPDATE: {"theme": {"primaryColor": "#ff0000"}, "activeTab": "theme"}
   
   Available theme fields:
   - primaryColor, secondaryColor, accentColor (hex colors)
   - fontFamily (string)
   - logoUrl (URL string)
   - headerStyle, footerStyle ("light" | "dark" | "transparent")
   
   Available email fields:
   - senderName, senderEmail (strings)
   - emailSignature (HTML string)
   - emailLogo (URL string)
   
   Be helpful, specific, and always confirm changes before applying them.
   ```
   - **Model**: gpt-4-turbo-preview (recommended)
   - **Tools**: None required for basic functionality

3. Copy the Assistant ID (starts with `asst_`)

### 2. Configure Environment Variables
Add to your `.env` file:
```env
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_ASSISTANT_ID=asst_your_assistant_id_here
```

### 3. Deploy API Endpoints

#### Option A: Supabase Edge Functions (Recommended)
1. Create the functions:
```bash
supabase functions new openai-create-thread
supabase functions new openai-send-message
```

2. Copy the code from `src/api/openai-assistant-endpoints.ts`

3. Deploy the functions:
```bash
supabase functions deploy openai-create-thread
supabase functions deploy openai-send-message
```

4. Set environment variables:
```bash
supabase secrets set OPENAI_API_KEY=your_key_here
```

#### Option B: Custom Backend
If using Express.js or another backend, implement the endpoints from the example code.

### 4. Update Assistant ID
In `src/pages/admin/CustomizationPage.tsx`, update the assistant ID:
```typescript
const OPENAI_ASSISTANT_ID = 'asst_your_actual_assistant_id_here';
```

## Usage Examples

### Theme Customization
- "Change the primary color to blue"
- "Make the header dark theme"
- "Update the logo to use our new branding"
- "Use a modern font like Inter"

### Email Settings
- "Update the email signature to include our new contact info"
- "Change the sender name to TogNinja Support"
- "Use our new logo in emails"

### Advanced Requests
- "Make the interface more modern with darker colors"
- "Set up professional email branding"
- "Apply our brand colors throughout the system"

## Technical Details

### Chat Interface Features
- **Floating Button**: Always accessible from customization page
- **Minimizable**: Can minimize to save screen space
- **Persistent State**: Maintains conversation history
- **Real-time Updates**: Applies changes immediately
- **Error Handling**: Graceful fallbacks for API issues

### Security Considerations
- API keys stored securely in environment variables
- CORS headers configured for frontend access
- Request validation and error handling
- Rate limiting recommended for production

### Customization Data Format
The assistant returns structured data for applying changes:
```json
{
  "theme": {
    "primaryColor": "#8b5cf6",
    "secondaryColor": "#4f46e5",
    "logoUrl": "/new-logo.svg"
  },
  "email": {
    "senderName": "TogNinja",
    "emailSignature": "<p>Best regards,<br>The TogNinja Team</p>"
  },
  "activeTab": "theme"
}
```

## Troubleshooting

### Common Issues
1. **API Key Not Working**: Verify OpenAI API key has sufficient credits
2. **Assistant Not Responding**: Check assistant ID is correct
3. **Changes Not Applying**: Verify the response format matches expected structure
4. **CORS Errors**: Ensure API endpoints have proper CORS headers

### Debug Mode
Enable console logging to see API responses:
```typescript
console.log('AI Customization changes:', changes);
```

## Future Enhancements
- Voice input for hands-free customization
- Preview mode to see changes before applying
- Undo/redo functionality
- Batch operations for multiple changes
- Integration with design systems
- Custom assistant training on specific brand guidelines

## Support
For issues with the OpenAI integration:
1. Check the browser console for error messages
2. Verify API endpoints are accessible
3. Test assistant functionality in OpenAI Playground
4. Review Supabase Edge Function logs
