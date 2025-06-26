import { createClient } from 'npm:@supabase/supabase-js@2.39.7';
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { parse } from 'npm:csv-parse@5.5.3';
import { v4 as uuidv4 } from 'npm:uuid@9.0.1';

// CORS headers for all responses
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

// Create Supabase client with service role key for admin access
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const path = url.pathname.replace('/functions/v1/clients', '');
    const method = req.method;

    // Get auth token
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization header required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if user is admin
    const { data: adminUser } = await supabase
      .from('admin_users')
      .select('is_admin')
      .eq('user_id', user.id)
      .single();

    if (!adminUser?.is_admin) {
      return new Response(
        JSON.stringify({ error: 'Admin access required' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Health check endpoint
    if (path === '/health' && method === 'GET') {
      return new Response(
        JSON.stringify({ status: 'available' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Import endpoints
    if (path === '/import/upload' && method === 'POST') {
      return await handleFileUpload(req);
    } else if (path === '/import/map' && method === 'POST') {
      return await handleColumnMapping(req);
    } else if (path.startsWith('/import/status/') && method === 'GET') {
      const importId = path.split('/').pop();
      return await getImportStatus(importId);
    }

    return new Response(
      JSON.stringify({ error: 'Endpoint not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error processing request:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

async function handleFileUpload(req: Request) {
  try {
    const formData = await req.formData();
    const file = formData.get('file');
    
    if (!file || !(file instanceof File)) {
      return new Response(
        JSON.stringify({ error: 'No file provided' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check file type
    if (!file.name.toLowerCase().endsWith('.csv')) {
      return new Response(
        JSON.stringify({ error: 'Only CSV files are supported' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check file size (10MB limit)
    if (file.size > 10 * 1024 * 1024) {
      return new Response(
        JSON.stringify({ error: 'File size must be less than 10MB' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Read file content
    const fileContent = await file.text();
    
    // Parse CSV
    const records: any[] = [];
    const parser = parse(fileContent, {
      columns: true,
      skip_empty_lines: true,
      trim: true
    });

    for await (const record of parser) {
      records.push(record);
    }

    if (records.length === 0) {
      return new Response(
        JSON.stringify({ error: 'CSV file is empty or has no valid data' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get headers from first record
    const headers = Object.keys(records[0]);
    
    // Generate import ID
    const importId = uuidv4();
    
    // Store import data in temporary storage
    // In a real implementation, this would be stored in a database or cache
    // For this example, we'll use Deno.env as a simple in-memory store
    Deno.env.set(`import_${importId}_headers`, JSON.stringify(headers));
    Deno.env.set(`import_${importId}_records`, JSON.stringify(records));
    Deno.env.set(`import_${importId}_status`, JSON.stringify({
      status: 'uploaded',
      rowsProcessed: 0,
      rowsSuccess: 0,
      rowsError: 0,
      progress: 0
    }));

    // Return sample data for preview
    return new Response(
      JSON.stringify({
        importId,
        headers,
        sampleRows: records.slice(0, 5)
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error handling file upload:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to process CSV file' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

async function handleColumnMapping(req: Request) {
  try {
    const { importId, columnMapping } = await req.json();
    
    if (!importId || !columnMapping) {
      return new Response(
        JSON.stringify({ error: 'Import ID and column mapping are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Validate required mappings
    if (!columnMapping.firstName || !columnMapping.lastName || !columnMapping.clientId || !columnMapping.email) {
      return new Response(
        JSON.stringify({ error: 'First name, last name, client ID, and email mappings are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get stored data
    const headersJson = Deno.env.get(`import_${importId}_headers`);
    const recordsJson = Deno.env.get(`import_${importId}_records`);
    
    if (!headersJson || !recordsJson) {
      return new Response(
        JSON.stringify({ error: 'Import data not found. Please upload the file again.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const headers = JSON.parse(headersJson);
    const records = JSON.parse(recordsJson);

    // Store column mapping
    Deno.env.set(`import_${importId}_mapping`, JSON.stringify(columnMapping));
    
    // Update status to processing
    Deno.env.set(`import_${importId}_status`, JSON.stringify({
      status: 'processing',
      rowsProcessed: 0,
      rowsSuccess: 0,
      rowsError: 0,
      progress: 0
    }));

    // Process import in background
    processImport(importId, records, columnMapping);

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error handling column mapping:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to process column mapping' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

async function getImportStatus(importId: string) {
  try {
    const statusJson = Deno.env.get(`import_${importId}_status`);
    
    if (!statusJson) {
      return new Response(
        JSON.stringify({ error: 'Import not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const status = JSON.parse(statusJson);
    
    // Add error file URL if there are errors
    if (status.rowsError > 0) {
      status.errorFileUrl = `/functions/v1/clients/import/errors/${importId}`;
    }

    return new Response(
      JSON.stringify(status),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error getting import status:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to get import status' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

async function processImport(importId: string, records: any[], columnMapping: any) {
  try {
    const totalRows = records.length;
    let processedRows = 0;
    let successRows = 0;
    let errorRows = 0;
    const errors: any[] = [];

    // Process each record
    for (const record of records) {
      try {
        processedRows++;
        
        // Map fields according to column mapping
        const clientData = {
          first_name: record[columnMapping.firstName],
          last_name: record[columnMapping.lastName],
          client_id: record[columnMapping.clientId],
          email: record[columnMapping.email],
          phone: columnMapping.phone ? record[columnMapping.phone] : null,
          address: columnMapping.address1 ? record[columnMapping.address1] : null,
          city: columnMapping.city ? record[columnMapping.city] : null,
          state: columnMapping.state ? record[columnMapping.state] : null,
          zip: columnMapping.zip ? record[columnMapping.zip] : null,
          country: columnMapping.country ? record[columnMapping.country] : null,
          company: null,
          notes: null,
          status: 'active',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        };

        // Insert into database
        const { error } = await supabase
          .from('crm_clients')
          .insert([clientData]);

        if (error) {
          throw error;
        }

        successRows++;
      } catch (error) {
        errorRows++;
        errors.push({
          row: processedRows,
          data: record,
          error: error instanceof Error ? error.message : 'Unknown error'
        });
      }

      // Update status every 10 rows
      if (processedRows % 10 === 0 || processedRows === totalRows) {
        const progress = Math.round((processedRows / totalRows) * 100);
        Deno.env.set(`import_${importId}_status`, JSON.stringify({
          status: processedRows === totalRows ? 'completed' : 'processing',
          rowsProcessed: processedRows,
          rowsSuccess: successRows,
          rowsError: errorRows,
          progress
        }));
      }
    }

    // Store errors for download
    if (errors.length > 0) {
      Deno.env.set(`import_${importId}_errors`, JSON.stringify(errors));
    }

    // Final status update
    Deno.env.set(`import_${importId}_status`, JSON.stringify({
      status: 'completed',
      rowsProcessed: processedRows,
      rowsSuccess: successRows,
      rowsError: errorRows,
      progress: 100
    }));

    // Create import log in database
    const { data: { user } } = await supabase.auth.getUser();
    
    if (user) {
      await supabase
        .from('import_logs')
        .insert({
          filename: `import_${importId}.csv`,
          imported_by: user.id,
          rows_processed: processedRows,
          rows_success: successRows,
          rows_error: errorRows,
          error_file_url: errors.length > 0 ? `/functions/v1/clients/import/errors/${importId}` : null
        });
    }
  } catch (error) {
    console.error('Error processing import:', error);
    
    // Update status to error
    Deno.env.set(`import_${importId}_status`, JSON.stringify({
      status: 'error',
      rowsProcessed: 0,
      rowsSuccess: 0,
      rowsError: 0,
      progress: 0,
      error: error instanceof Error ? error.message : 'Unknown error'
    }));
  }
}