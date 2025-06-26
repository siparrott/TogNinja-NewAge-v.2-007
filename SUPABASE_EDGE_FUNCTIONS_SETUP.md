# Supabase Edge Functions Setup Guide

## Overview
Edge Functions provide server-side logic for advanced features like OpenAI integration, email processing, and file handling.

## Required Edge Functions

### 1. OpenAI Assistant Function
**File:** `supabase/functions/openai-assistant/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.208.0/http/server.ts"
import "https://deno.land/x/xhr@0.1.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { message, context } = await req.json()
    
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [
          {
            role: 'system',
            content: `You are a helpful assistant for a photography business. 
                     Context: ${context || 'General photography business inquiry'}`
          },
          {
            role: 'user',
            content: message
          }
        ],
        max_tokens: 500,
        temperature: 0.7,
      }),
    })

    const data = await openaiResponse.json()
    
    return new Response(
      JSON.stringify({ 
        response: data.choices[0]?.message?.content || 'I apologize, but I could not process your request.' 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})
```

### 2. Newsletter Function
**File:** `supabase/functions/newsletter-signup/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.208.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, firstName, lastName } = await req.json()
    
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Insert newsletter signup
    const { data, error } = await supabase
      .from('newsletter_subscribers')
      .insert([
        {
          email,
          first_name: firstName,
          last_name: lastName,
          subscribed_at: new Date().toISOString(),
          status: 'active'
        }
      ])

    if (error) throw error

    return new Response(
      JSON.stringify({ success: true, message: 'Successfully subscribed to newsletter!' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})
```

### 3. Email Notification Function
**File:** `supabase/functions/send-notification/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.208.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { to, subject, message, type } = await req.json()
    
    // Email sending logic would go here
    // For now, just log the notification
    console.log('Notification:', { to, subject, message, type })
    
    return new Response(
      JSON.stringify({ success: true, message: 'Notification sent successfully!' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})
```

## Deployment Steps

### 1. Install Supabase CLI
```bash
# Install globally
npm install -g supabase

# Login to Supabase
supabase login
```

### 2. Initialize Functions (if not already done)
```bash
# In your project root
supabase init

# Link to your project
supabase link --project-ref your-project-id
```

### 3. Create Function Files
```bash
# Create the functions directory structure
mkdir -p supabase/functions/openai-assistant
mkdir -p supabase/functions/newsletter-signup
mkdir -p supabase/functions/send-notification

# Create the function files with the code above
```

### 4. Deploy Functions
```bash
# Deploy all functions
supabase functions deploy

# Or deploy individually
supabase functions deploy openai-assistant
supabase functions deploy newsletter-signup
supabase functions deploy send-notification
```

### 5. Set Environment Variables
```bash
# Set OpenAI API key
supabase secrets set OPENAI_API_KEY=your-openai-api-key

# Set any other required secrets
supabase secrets set SMTP_HOST=smtp.gmail.com
supabase secrets set SMTP_USER=your-email@gmail.com
```

## Testing Functions

### Test OpenAI Assistant
```bash
curl -X POST 'https://your-project-id.supabase.co/functions/v1/openai-assistant' \
  -H 'Authorization: Bearer your-anon-key' \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello, can you help me with photography pricing?", "context": "photography business"}'
```

### Test Newsletter Signup
```bash
curl -X POST 'https://your-project-id.supabase.co/functions/v1/newsletter-signup' \
  -H 'Authorization: Bearer your-anon-key' \
  -H 'Content-Type: application/json' \
  -d '{"email": "test@example.com", "firstName": "Test", "lastName": "User"}'
```

## Integration with Frontend

Update your frontend API calls to use the Edge Functions:

```typescript
// In your React components
const callOpenAI = async (message: string, context?: string) => {
  const response = await fetch(`${supabaseUrl}/functions/v1/openai-assistant`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${supabaseAnonKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ message, context }),
  });
  
  return await response.json();
};
```

## Troubleshooting

### Common Issues:
1. **Function not found:** Ensure deployment was successful
2. **CORS errors:** Check CORS headers in function code
3. **Environment variables:** Verify secrets are set correctly
4. **Timeout errors:** Functions have a 60-second timeout limit

### Debug Commands:
```bash
# View function logs
supabase functions logs openai-assistant

# List deployed functions
supabase functions list

# Check secrets
supabase secrets list
```

---
**Created:** $(Get-Date)
**Note:** Functions may take a few minutes to be available after deployment
