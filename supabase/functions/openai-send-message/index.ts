import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { threadId, message, assistantId } = await req.json()
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    
    if (!openaiApiKey) {
      throw new Error('OpenAI API key not configured')
    }

    if (!threadId || !message || !assistantId) {
      throw new Error('Missing required parameters')
    }

    // Add message to thread
    const messageResponse = await fetch(`https://api.openai.com/v1/threads/${threadId}/messages`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
        'OpenAI-Beta': 'assistants=v2'
      },
      body: JSON.stringify({
        role: 'user',
        content: message
      })
    })

    if (!messageResponse.ok) {
      const errorData = await messageResponse.text()
      console.error('Error adding message:', messageResponse.status, errorData)
      throw new Error(`Failed to add message: ${messageResponse.status}`)
    }

    // Create and run assistant
    const runResponse = await fetch(`https://api.openai.com/v1/threads/${threadId}/runs`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
        'OpenAI-Beta': 'assistants=v2'
      },
      body: JSON.stringify({
        assistant_id: assistantId,
        instructions: `You are a customization assistant for a photography CRM system called TogNinja. Help users modify:

        - Theme settings (colors, fonts, layouts, logos)
        - Email templates and signatures  
        - UI customizations and branding
        - System preferences

        When you want to apply changes, format your response with customization data at the end:
        CUSTOMIZATION_UPDATE: {"theme": {"primaryColor": "#ff0000"}, "activeTab": "theme"}

        Available theme fields:
        - primaryColor, secondaryColor, accentColor (hex color values)
        - fontFamily (font name string)
        - logoUrl (URL string)
        - headerStyle, footerStyle ("light" | "dark" | "transparent")

        Available email fields:
        - senderName, senderEmail (strings)
        - emailSignature (HTML string)
        - emailLogo (URL string)

        Be helpful, specific, and always explain what changes you're making before applying them.
        Provide clear instructions and ask for confirmation when making significant changes.`
      })
    })

    if (!runResponse.ok) {
      const errorData = await runResponse.text()
      console.error('Error creating run:', runResponse.status, errorData)
      throw new Error(`Failed to create run: ${runResponse.status}`)
    }

    const run = await runResponse.json()
    
    // Poll for completion with timeout
    let runStatus = run.status
    let attempts = 0
    const maxAttempts = 30 // 30 seconds timeout
    
    while ((runStatus === 'queued' || runStatus === 'in_progress') && attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 1000))
      attempts++
      
      const statusResponse = await fetch(`https://api.openai.com/v1/threads/${threadId}/runs/${run.id}`, {
        headers: {
          'Authorization': `Bearer ${openaiApiKey}`,
          'OpenAI-Beta': 'assistants=v2'
        }
      })
      
      if (!statusResponse.ok) {
        console.error('Error checking run status:', statusResponse.status)
        break
      }
      
      const statusData = await statusResponse.json()
      runStatus = statusData.status
      
      if (runStatus === 'failed' || runStatus === 'cancelled' || runStatus === 'expired') {
        throw new Error(`Run failed with status: ${runStatus}`)
      }
    }

    if (attempts >= maxAttempts) {
      throw new Error('Assistant response timeout')
    }

    // Get messages
    const messagesResponse = await fetch(`https://api.openai.com/v1/threads/${threadId}/messages`, {
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'OpenAI-Beta': 'assistants=v2'
      }
    })

    if (!messagesResponse.ok) {
      throw new Error(`Failed to get messages: ${messagesResponse.status}`)
    }

    const messagesData = await messagesResponse.json()
    const lastMessage = messagesData.data[0]
    
    if (!lastMessage || !lastMessage.content || !lastMessage.content[0]) {
      throw new Error('No response from assistant')
    }
    
    const responseContent = lastMessage.content[0].text.value
    
    return new Response(
      JSON.stringify({ 
        response: responseContent,
        runId: run.id,
        threadId: threadId
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )
  } catch (error) {
    console.error('Error in send-message function:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        details: 'Check function logs for more information'
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})
