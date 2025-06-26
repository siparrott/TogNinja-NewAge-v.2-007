import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface ContactFormData {
  fullName: string;
  email: string;
  phone: string;
  message: string;
}

interface WaitlistFormData extends ContactFormData {
  preferredDate: string;
}

interface VoucherPurchaseData {
  purchaserName: string;
  purchaserEmail: string;
  amount: number;
  paymentIntentId: string;
  voucherType?: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const path = url.pathname

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    if (path === '/public/contact/kontakt') {
      if (req.method !== 'POST') {
        return new Response(
          JSON.stringify({ error: 'Method not allowed' }),
          { 
            status: 405, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      const formData: ContactFormData = await req.json()

      // Validate required fields
      if (!formData.fullName || !formData.email || !formData.message) {
        return new Response(
          JSON.stringify({ error: 'Missing required fields' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // Insert into leads table
      const { error } = await supabase
        .from('leads')
        .insert({
          form_source: 'KONTAKT',
          first_name: formData.fullName.split(' ')[0] || '',
          last_name: formData.fullName.split(' ').slice(1).join(' ') || '',
          email: formData.email,
          phone: formData.phone || null,
          message: formData.message,
          status: 'NEW'
        })

      if (error) {
        console.error('Database error:', error)
        return new Response(
          JSON.stringify({ error: 'Failed to save contact form' }),
          { 
            status: 500, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      return new Response(
        JSON.stringify({ success: true, message: 'Contact form submitted successfully' }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (path === '/public/contact/warteliste') {
      if (req.method !== 'POST') {
        return new Response(
          JSON.stringify({ error: 'Method not allowed' }),
          { 
            status: 405, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      const formData: WaitlistFormData = await req.json()

      // Validate required fields
      if (!formData.fullName || !formData.email || !formData.preferredDate) {
        return new Response(
          JSON.stringify({ error: 'Missing required fields' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // Insert into leads table with waitlist-specific data
      const message = `Preferred Date: ${formData.preferredDate}${formData.message ? '\n\nMessage: ' + formData.message : ''}`

      const { error } = await supabase
        .from('leads')
        .insert({
          form_source: 'WARTELISTE',
          first_name: formData.fullName.split(' ')[0] || '',
          last_name: formData.fullName.split(' ').slice(1).join(' ') || '',
          email: formData.email,
          phone: formData.phone || null,
          message: message,
          status: 'NEW'
        })

      if (error) {
        console.error('Database error:', error)
        return new Response(
          JSON.stringify({ error: 'Failed to save waitlist form' }),
          { 
            status: 500, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      return new Response(
        JSON.stringify({ success: true, message: 'Waitlist form submitted successfully' }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (path === '/public/voucher/purchase') {
      if (req.method !== 'POST') {
        return new Response(
          JSON.stringify({ error: 'Method not allowed' }),
          { 
            status: 405, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      const purchaseData: VoucherPurchaseData = await req.json()

      // Validate required fields
      if (!purchaseData.purchaserName || !purchaseData.purchaserEmail || !purchaseData.amount || !purchaseData.paymentIntentId) {
        return new Response(
          JSON.stringify({ error: 'Missing required fields' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // Generate unique voucher code
      const voucherCode = `VC${Date.now()}${Math.random().toString(36).substring(2, 8).toUpperCase()}`

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
        .select()
        .single()

      if (error) {
        console.error('Database error:', error)
        return new Response(
          JSON.stringify({ error: 'Failed to save voucher purchase' }),
          { 
            status: 500, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Voucher purchase completed successfully',
          voucher_code: voucherCode,
          data: data
        }),
        { 
          status: 200, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Route not found
    return new Response(
      JSON.stringify({ error: 'Route not found' }),
      { 
        status: 404, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})