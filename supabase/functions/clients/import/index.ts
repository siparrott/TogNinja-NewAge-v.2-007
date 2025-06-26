import { createClient } from 'npm:@supabase/supabase-js@2.39.7';
import { parse } from 'npm:csv-parse@5.5.3';
import { v4 as uuidv4 } from 'npm:uuid@9.0.1';

// Define CORS headers
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

// Temporary storage for import sessions
const importSessions = new Map();

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const path = url.pathname.replace('/functions/v1/clients/import', '');
    
    // Health check endpoint
    if (path === '/health') {
      return new Response(
        JSON.stringify({ status: 'available' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verify authentication for all other endpoints
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

    // Route handling
    if (path === '/upload' && req.method === 'POST') {
      return await handleUpload(req, user.id);
    } else if (path === '/map' && req.method === 'POST') {
      return await handleColumnMapping(req, user.id);
    } else if (path.startsWith('/status/') && req.method === 'GET') {
      const importId = path.split('/')[2];
      return await getImportStatus(importId);
    }

    return new Response(
      JSON.stringify({ error: 'Endpoint not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Import API Error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

async function handleUpload(req: Request, userId: string) {
  try {
    const formData = await req.formData();
    const file = formData.get('file');
    
    if (!file || !(file instanceof File)) {
      return new Response(
        JSON.stringify({ error: 'No file provided' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Read file content
    const fileContent = await file.text();
    
    // Parse CSV
    const parser = parse(fileContent, {
      columns: true,
      skip_empty_lines: true,
      trim: true
    });
    
    const records = [];
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
    
    // Create import session
    const importId = uuidv4();
    const sampleRows = records.slice(0, 3); // First 3 rows for preview
    
    // Store import session data
    importSessions.set(importId, {
      userId,
      filename: file.name,
      records,
      headers,
      status: 'uploaded',
      columnMapping: null,
      progress: 0,
      rowsProcessed: 0,
      rowsSuccess: 0,
      rowsError: 0,
      errors: []
    });
    
    // Create import log
    const { error: logError } = await supabase
      .from('import_logs')
      .insert({
        id: importId,
        filename: file.name,
        imported_by: userId,
        rows_processed: 0,
        rows_success: 0,
        rows_error: 0
      });
    
    if (logError) {
      console.error('Error creating import log:', logError);
    }
    
    return new Response(
      JSON.stringify({ importId, headers, sampleRows }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error handling upload:', error);
    throw error;
  }
}

async function handleColumnMapping(req: Request, userId: string) {
  try {
    const { importId, columnMapping } = await req.json();
    
    if (!importId || !columnMapping) {
      return new Response(
        JSON.stringify({ error: 'Import ID and column mapping are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    const importSession = importSessions.get(importId);
    if (!importSession) {
      return new Response(
        JSON.stringify({ error: 'Import session not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Update import session with column mapping
    importSession.columnMapping = columnMapping;
    importSession.status = 'processing';
    importSessions.set(importId, importSession);
    
    // Start processing in the background
    processImport(importId, userId);
    
    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error handling column mapping:', error);
    throw error;
  }
}

async function getImportStatus(importId: string) {
  try {
    const importSession = importSessions.get(importId);
    if (!importSession) {
      // Try to get from database if not in memory
      const { data: importLog, error } = await supabase
        .from('import_logs')
        .select('*')
        .eq('id', importId)
        .single();
      
      if (error || !importLog) {
        return new Response(
          JSON.stringify({ error: 'Import session not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      
      // Check if there are errors
      let errorFileUrl = null;
      if (importLog.rows_error > 0) {
        const { data: { publicUrl } } = supabase.storage
          .from('import_errors')
          .getPublicUrl(`${importId}.csv`);
        
        errorFileUrl = publicUrl;
      }
      
      return new Response(
        JSON.stringify({
          importId,
          status: importLog.rows_processed > 0 ? 'completed' : 'error',
          progress: 100,
          rowsProcessed: importLog.rows_processed,
          rowsSuccess: importLog.rows_success,
          rowsError: importLog.rows_error,
          errorFileUrl
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Return current status
    return new Response(
      JSON.stringify({
        importId,
        status: importSession.status,
        progress: importSession.progress,
        rowsProcessed: importSession.rowsProcessed,
        rowsSuccess: importSession.rowsSuccess,
        rowsError: importSession.rowsError,
        errorFileUrl: importSession.errorFileUrl
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error getting import status:', error);
    throw error;
  }
}

async function processImport(importId: string, userId: string) {
  const importSession = importSessions.get(importId);
  if (!importSession) return;
  
  const { records, columnMapping } = importSession;
  const totalRows = records.length;
  let rowsProcessed = 0;
  let rowsSuccess = 0;
  let rowsError = 0;
  const errors = [];
  
  try {
    for (const record of records) {
      rowsProcessed++;
      
      try {
        // Map CSV columns to client fields
        const clientData: any = {
          first_name: record[columnMapping.firstName] || '',
          last_name: record[columnMapping.lastName] || '',
          client_id: record[columnMapping.clientId] || '',
          email: record[columnMapping.email] || '',
        };
        
        // Add optional fields if mapped
        if (columnMapping.phone && record[columnMapping.phone]) {
          clientData.phone = record[columnMapping.phone];
        }
        
        if (columnMapping.address1 && record[columnMapping.address1]) {
          clientData.address = record[columnMapping.address1];
        }
        
        if (columnMapping.city && record[columnMapping.city]) {
          clientData.city = record[columnMapping.city];
        }
        
        // Insert into crm_clients table
        const { error } = await supabase
          .from('crm_clients')
          .insert([clientData]);
        
        if (error) {
          throw error;
        }
        
        rowsSuccess++;
      } catch (error) {
        rowsError++;
        errors.push({
          row: rowsProcessed,
          data: record,
          error: error.message
        });
      }
      
      // Update progress
      const progress = Math.round((rowsProcessed / totalRows) * 100);
      importSession.progress = progress;
      importSession.rowsProcessed = rowsProcessed;
      importSession.rowsSuccess = rowsSuccess;
      importSession.rowsError = rowsError;
      importSessions.set(importId, importSession);
      
      // Update import log in database periodically
      if (rowsProcessed % 10 === 0 || rowsProcessed === totalRows) {
        await supabase
          .from('import_logs')
          .update({
            rows_processed: rowsProcessed,
            rows_success: rowsSuccess,
            rows_error: rowsError
          })
          .eq('id', importId);
      }
    }
    
    // Create error file if there are errors
    if (errors.length > 0) {
      // Create CSV content
      const errorHeaders = ['row_number', 'error', ...Object.keys(records[0])];
      const errorRows = errors.map(err => {
        return [
          err.row,
          err.error,
          ...Object.values(err.data)
        ];
      });
      
      const errorCsv = [
        errorHeaders.join(','),
        ...errorRows.map(row => row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
      ].join('\n');
      
      // Upload to storage
      const { error: uploadError } = await supabase.storage
        .from('import_errors')
        .upload(`${importId}.csv`, errorCsv, {
          contentType: 'text/csv',
          upsert: true
        });
      
      if (!uploadError) {
        const { data: { publicUrl } } = supabase.storage
          .from('import_errors')
          .getPublicUrl(`${importId}.csv`);
        
        importSession.errorFileUrl = publicUrl;
        
        // Update import log with error file URL
        await supabase
          .from('import_logs')
          .update({
            error_file_url: publicUrl
          })
          .eq('id', importId);
      }
    }
    
    // Mark import as completed
    importSession.status = 'completed';
    importSessions.set(importId, importSession);
    
    // Final update to import log
    await supabase
      .from('import_logs')
      .update({
        rows_processed: rowsProcessed,
        rows_success: rowsSuccess,
        rows_error: rowsError
      })
      .eq('id', importId);
    
  } catch (error) {
    console.error('Error processing import:', error);
    
    // Mark import as error
    importSession.status = 'error';
    importSessions.set(importId, importSession);
    
    // Update import log
    await supabase
      .from('import_logs')
      .update({
        rows_processed: rowsProcessed,
        rows_success: rowsSuccess,
        rows_error: rowsError
      })
      .eq('id', importId);
  }
}