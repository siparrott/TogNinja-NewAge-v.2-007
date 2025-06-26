import { createClient } from 'npm:@supabase/supabase-js@2.39.7';
import { Resend } from 'npm:resend@3.2.0';

const resend = new Resend(Deno.env.get('RESEND_API_KEY'));
const VOUCHER_CODE = 'PRINT50'; // Example voucher code

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: corsHeaders,
    });
  }

  try {
    const { email } = await req.json();

    if (!email) {
      return new Response(
        JSON.stringify({ error: 'Email is required' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // Create Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );    // Add subscriber to database and create lead
    const leadData = {
      first_name: 'Newsletter',
      last_name: 'Subscriber',
      email: email,
      message: 'Newsletter signup - €50 Print Gutschein',
      form_source: 'NEWSLETTER',
      status: 'NEW',
      created_at: new Date().toISOString()
    };

    // Insert lead first
    const { data: leadResult, error: leadError } = await supabase
      .from('leads')
      .insert([leadData])
      .select()
      .single();

    if (leadError) {
      // If email already exists as a lead, don't treat as error
      if (leadError.code === '23505') {
        return new Response(
          JSON.stringify({ success: true, message: 'Already subscribed' }),
          { 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        );
      }
      throw leadError;
    }

    // Also add to newsletter_subscribers table
    const { error: dbError } = await supabase
      .from('newsletter_subscribers')
      .insert([{ email }]);

    if (dbError && dbError.code !== '23505') {
      // Don't fail if newsletter_subscribers insert fails (except for unique violations)
      console.warn('Newsletter subscribers insert failed:', dbError);
    }

    // Send welcome email with voucher
    const { data: emailData, error: emailError } = await resend.emails.send({
      from: 'New Age Fotografie <no-reply@newagefotografie.com>',
      to: [email],
      subject: 'Ihr €50 Fotoshooting-Gutschein',
      html: `
        <h1>Willkommen bei New Age Fotografie!</h1>
        <p>Vielen Dank für Ihre Newsletter-Anmeldung.</p>
        <p>Hier ist Ihr €50 Print-Gutschein: <strong>${VOUCHER_CODE}</strong></p>
        <p>Dieser Gutschein kann bei Ihrem nächsten Fotoshooting eingelöst werden.</p>
      `,
    });

    if (emailError) {
      console.error('Failed to send welcome email:', emailError);
      throw emailError;
    }

    return new Response(
      JSON.stringify({ success: true }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  } catch (error) {
    console.error('Error processing newsletter signup:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});