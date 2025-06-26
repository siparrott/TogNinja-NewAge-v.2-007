import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
}

interface ColumnMapping {
  firstName: string;
  lastName: string;
  clientId: string;
  email: string;
  phone?: string;
  address1?: string;
  city?: string;
}

interface ImportSession {
  id: string;
  headers: string[];
  rows: any[];
  status: 'uploaded' | 'processing' | 'completed' | 'error';
  progress: number;
  rowsProcessed: number;
  rowsSuccess: number;
  rowsError: number;
  errors: any[];
}

// In-memory storage for import sessions (in production, use a database)
const importSessions = new Map<string, ImportSession>();

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Get the current user
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Check if user is admin
    const { data: adminUser, error: adminError } = await supabaseClient
      .from('admin_users')
      .select('is_admin')
      .eq('user_id', user.id)
      .single()

    if (adminError || !adminUser?.is_admin) {
      return new Response(
        JSON.stringify({ error: 'Admin access required' }),
        { 
          status: 403, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const url = new URL(req.url)
    const path = url.pathname

    // Health check endpoint
    if (path.endsWith('/health')) {
      return new Response(
        JSON.stringify({ status: 'available' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Upload CSV endpoint
    if (path.endsWith('/upload') && req.method === 'POST') {
      const formData = await req.formData()
      const file = formData.get('file') as File

      if (!file) {
        return new Response(
          JSON.stringify({ error: 'No file provided' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      if (!file.name.toLowerCase().endsWith('.csv')) {
        return new Response(
          JSON.stringify({ error: 'File must be a CSV' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // Parse CSV
      const text = await file.text()
      const lines = text.split('\n').filter(line => line.trim())
      
      if (lines.length < 2) {
        return new Response(
          JSON.stringify({ error: 'CSV must have at least a header row and one data row' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // Parse headers
      const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''))
      
      // Parse sample rows (first 5 data rows)
      const sampleRows = lines.slice(1, 6).map(line => {
        const values = line.split(',').map(v => v.trim().replace(/"/g, ''))
        const row: any = {}
        headers.forEach((header, index) => {
          row[header] = values[index] || ''
        })
        return row
      })

      // Parse all rows
      const allRows = lines.slice(1).map(line => {
        const values = line.split(',').map(v => v.trim().replace(/"/g, ''))
        const row: any = {}
        headers.forEach((header, index) => {
          row[header] = values[index] || ''
        })
        return row
      })

      // Create import session
      const importId = crypto.randomUUID()
      const session: ImportSession = {
        id: importId,
        headers,
        rows: allRows,
        status: 'uploaded',
        progress: 0,
        rowsProcessed: 0,
        rowsSuccess: 0,
        rowsError: 0,
        errors: []
      }

      importSessions.set(importId, session)

      return new Response(
        JSON.stringify({
          importId,
          headers,
          sampleRows,
          totalRows: allRows.length
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Map columns and start import
    if (path.endsWith('/map') && req.method === 'POST') {
      const { importId, columnMapping } = await req.json()
      
      const session = importSessions.get(importId)
      if (!session) {
        return new Response(
          JSON.stringify({ error: 'Import session not found' }),
          { 
            status: 404, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      // Start processing in background
      processImport(supabaseClient, session, columnMapping)

      return new Response(
        JSON.stringify({ success: true }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get import status
    if (path.includes('/status/') && req.method === 'GET') {
      const importId = path.split('/status/')[1]
      
      const session = importSessions.get(importId)
      if (!session) {
        return new Response(
          JSON.stringify({ error: 'Import session not found' }),
          { 
            status: 404, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }

      return new Response(
        JSON.stringify({
          status: session.status,
          progress: session.progress,
          rowsProcessed: session.rowsProcessed,
          rowsSuccess: session.rowsSuccess,
          rowsError: session.rowsError,
          errors: session.errors
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    return new Response(
      JSON.stringify({ error: 'Not found' }),
      { 
        status: 404, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function processImport(
  supabaseClient: any,
  session: ImportSession,
  columnMapping: ColumnMapping
) {
  try {
    session.status = 'processing'
    
    const totalRows = session.rows.length
    let processedRows = 0
    let successRows = 0
    let errorRows = 0
    const errors: any[] = []

    for (const row of session.rows) {
      try {
        // Map the row data to client fields
        const clientData = {
          name: `${row[columnMapping.firstName] || ''} ${row[columnMapping.lastName] || ''}`.trim(),
          email: row[columnMapping.email],
          phone: row[columnMapping.phone] || null,
          address: row[columnMapping.address1] || null,
          city: row[columnMapping.city] || null,
          company: null,
          notes: null,
          status: 'active'
        }

        // Validate required fields
        if (!clientData.name || !clientData.email) {
          throw new Error('Name and email are required')
        }

        // Insert into database
        const { error } = await supabaseClient
          .from('crm_clients')
          .insert(clientData)

        if (error) {
          throw error
        }

        successRows++
      } catch (error) {
        errorRows++
        errors.push({
          row: processedRows + 1,
          data: row,
          error: error.message
        })
      }

      processedRows++
      session.progress = Math.round((processedRows / totalRows) * 100)
      session.rowsProcessed = processedRows
      session.rowsSuccess = successRows
      session.rowsError = errorRows
    }

    session.status = errorRows > 0 ? 'error' : 'completed'
    session.errors = errors

    // Log the import
    await supabaseClient
      .from('import_logs')
      .insert({
        filename: 'csv-import',
        imported_by: (await supabaseClient.auth.getUser()).data.user?.id,
        rows_processed: processedRows,
        rows_success: successRows,
        rows_error: errorRows
      })

  } catch (error) {
    console.error('Import processing error:', error)
    session.status = 'error'
    session.errors.push({
      row: 0,
      data: {},
      error: 'Import processing failed: ' + error.message
    })
  }
}