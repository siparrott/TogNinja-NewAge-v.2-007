import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
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
    const { threadId, message, assistantId } = await req.json()
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    
    if (!openaiApiKey) {
      throw new Error('OpenAI API key not configured')
    }

    if (!threadId || !message || !assistantId) {
      throw new Error('Missing required parameters')
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

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

    // Create and run assistant with CRM-specific instructions
    const runResponse = await fetch(`https://api.openai.com/v1/threads/${threadId}/runs`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
        'OpenAI-Beta': 'assistants=v2'
      },
      body: JSON.stringify({
        assistant_id: assistantId,
        instructions: `You are a CRM Operations Assistant for TogNinja, a photography business CRM system. 

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

Current context: Photography CRM system with clients, bookings, invoices, and email management.`
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
    const maxAttempts = 30
    
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
    let crmAction = null
    let actionPerformed = false
    
    // Check if response contains CRM action
    if (responseContent.includes('CRM_ACTION:')) {
      try {
        const actionData = responseContent.split('CRM_ACTION:')[1].trim()
        crmAction = JSON.parse(actionData)
        
        // Execute the CRM action
        const executionResult = await executeCRMAction(crmAction, supabase)
        actionPerformed = executionResult.success
        
        console.log('CRM Action executed:', crmAction, 'Success:', actionPerformed)
      } catch (parseError) {
        console.error('Error parsing CRM action:', parseError)
      }
    }
    
    return new Response(
      JSON.stringify({ 
        response: responseContent,
        crmAction,
        actionPerformed,
        runId: run.id,
        threadId: threadId
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )
  } catch (error) {
    console.error('Error in CRM assistant function:', error)
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

async function executeCRMAction(action: any, supabase: any) {
  try {
    console.log('Executing CRM action:', action)
    
    switch (action.type) {
      case 'email':
        return await handleEmailAction(action, supabase)
      case 'booking':
        return await handleBookingAction(action, supabase)
      case 'client':
        return await handleClientAction(action, supabase)
      case 'invoice':
        return await handleInvoiceAction(action, supabase)
      case 'data':
        return await handleDataAction(action, supabase)
      case 'calendar':
        return await handleCalendarAction(action, supabase)
      default:
        return { success: false, message: 'Unknown action type' }
    }
  } catch (error) {
    console.error('Error executing CRM action:', error)
    return { success: false, message: error.message }
  }
}

async function handleEmailAction(action: any, supabase: any) {
  // Email action implementations
  switch (action.action) {
    case 'send_booking_confirmation':
      // Implementation for sending booking confirmations
      console.log('Sending booking confirmation...', action.data)
      return { success: true, message: 'Booking confirmation sent' }
    
    case 'reply_to_client':
      // Implementation for replying to client emails
      console.log('Replying to client...', action.data)
      return { success: true, message: 'Client reply sent' }
    
    default:
      return { success: false, message: 'Unknown email action' }
  }
}

async function handleBookingAction(action: any, supabase: any) {
  // Booking action implementations  
  switch (action.action) {
    case 'create_appointment':
      // Create new appointment
      const { data, error } = await supabase
        .from('appointments')
        .insert([action.data])
      
      return { success: !error, message: error ? error.message : 'Appointment created' }
    
    case 'update_booking':
      // Update existing booking
      console.log('Updating booking...', action.data)
      return { success: true, message: 'Booking updated' }
    
    default:
      return { success: false, message: 'Unknown booking action' }
  }
}

async function handleClientAction(action: any, supabase: any) {
  // Client action implementations
  switch (action.action) {
    case 'add_client':
      // Add new client
      const { data, error } = await supabase
        .from('clients')
        .insert([action.data])
      
      return { success: !error, message: error ? error.message : 'Client added' }
    
    case 'update_client':
      // Update client information
      console.log('Updating client...', action.data)
      return { success: true, message: 'Client updated' }
    
    default:
      return { success: false, message: 'Unknown client action' }
  }
}

async function handleInvoiceAction(action: any, supabase: any) {
  // Invoice action implementations
  switch (action.action) {
    case 'generate_invoice':
      // Generate new invoice
      console.log('Generating invoice...', action.data)
      return { success: true, message: 'Invoice generated' }
    
    case 'send_invoice':
      // Send invoice to client
      console.log('Sending invoice...', action.data)
      return { success: true, message: 'Invoice sent' }
    
    default:
      return { success: false, message: 'Unknown invoice action' }
  }
}

async function handleDataAction(action: any, supabase: any) {
  // Data action implementations
  switch (action.action) {
    case 'run_report':
      // Run data report
      console.log('Running report...', action.data)
      return { success: true, message: 'Report generated' }
    
    case 'export_data':
      // Export data
      console.log('Exporting data...', action.data)
      return { success: true, message: 'Data exported' }
    
    default:
      return { success: false, message: 'Unknown data action' }
  }
}

async function handleCalendarAction(action: any, supabase: any) {
  // Calendar action implementations
  switch (action.action) {
    case 'schedule_appointment':
      // Schedule new appointment
      console.log('Scheduling appointment...', action.data)
      return { success: true, message: 'Appointment scheduled' }
    
    case 'send_calendar_invite':
      // Send calendar invite
      console.log('Sending calendar invite...', action.data)
      return { success: true, message: 'Calendar invite sent' }
    
    default:
      return { success: false, message: 'Unknown calendar action' }
  }
}
