import { createClient } from 'npm:@supabase/supabase-js@2.39.7';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const path = url.pathname.replace('/functions/v1/crm-api', '');
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

    // Route handling
    if (path === '/dashboard/metrics' && method === 'GET') {
      return await getDashboardMetrics();
    } else if (path === '/leads' && method === 'GET') {
      return await getLeads(url.searchParams);
    } else if (path === '/leads' && method === 'POST') {
      return await createLead(req);
    } else if (path.startsWith('/leads/') && method === 'PUT') {
      const leadId = path.split('/')[2];
      return await updateLead(leadId, req);
    } else if (path.startsWith('/leads/') && method === 'DELETE') {
      const leadId = path.split('/')[2];
      return await deleteLead(leadId);
    } else if (path === '/vouchers' && method === 'GET') {
      return await getVoucherSales(url.searchParams);
    } else if (path === '/clients' && method === 'GET') {
      return await getClients(url.searchParams);
    } else if (path === '/images/popular' && method === 'GET') {
      return await getPopularImages();
    }

    return new Response(
      JSON.stringify({ error: 'Endpoint not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('CRM API Error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

async function getDashboardMetrics() {
  try {
    // Get voucher sales metrics
    const { data: sales } = await supabase
      .from('stripe_orders')
      .select('amount_total, created_at')
      .eq('status', 'completed');

    const totalRevenue = sales?.reduce((sum, sale) => sum + (sale.amount_total / 100), 0) || 0;
    const avgOrderValue = sales?.length ? totalRevenue / sales.length : 0;

    // Get active users count
    const { count: activeUsers } = await supabase
      .from('stripe_customers')
      .select('*', { count: 'exact', head: true })
      .is('deleted_at', null);

    // Generate trend data (last 7 days)
    const trendData = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      
      const dayRevenue = sales?.filter(sale => 
        sale.created_at.startsWith(dateStr)
      ).reduce((sum, sale) => sum + (sale.amount_total / 100), 0) || 0;
      
      trendData.push({
        date: dateStr,
        value: dayRevenue
      });
    }

    const metrics = {
      avgOrderValue: Math.round(avgOrderValue * 100) / 100,
      activeUsers: activeUsers || 0,
      bookedRevenue: Math.round(totalRevenue * 100) / 100,
      trendData
    };

    return new Response(
      JSON.stringify(metrics),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error fetching dashboard metrics:', error);
    throw error;
  }
}

async function getLeads(searchParams: URLSearchParams) {
  try {
    let query = supabase.from('crm_leads').select('*');

    if (searchParams.get('recent') === 'true') {
      query = query.order('created_at', { ascending: false }).limit(10);
    }

    const status = searchParams.get('status');
    if (status && status !== 'all') {
      query = query.eq('status', status);
    }

    const { data: leads, error } = await query;

    if (error) throw error;

    return new Response(
      JSON.stringify(leads || []),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error fetching leads:', error);
    throw error;
  }
}

async function createLead(req: Request) {
  try {
    const leadData = await req.json();
    
    const { data: lead, error } = await supabase
      .from('crm_leads')
      .insert([leadData])
      .select()
      .single();

    if (error) throw error;

    return new Response(
      JSON.stringify(lead),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error creating lead:', error);
    throw error;
  }
}

async function updateLead(leadId: string, req: Request) {
  try {
    const updateData = await req.json();
    updateData.updated_at = new Date().toISOString();
    
    const { data: lead, error } = await supabase
      .from('crm_leads')
      .update(updateData)
      .eq('id', leadId)
      .select()
      .single();

    if (error) throw error;

    return new Response(
      JSON.stringify(lead),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error updating lead:', error);
    throw error;
  }
}

async function deleteLead(leadId: string) {
  try {
    const { error } = await supabase
      .from('crm_leads')
      .delete()
      .eq('id', leadId);

    if (error) throw error;

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error deleting lead:', error);
    throw error;
  }
}

async function getVoucherSales(searchParams: URLSearchParams) {
  try {
    let query = supabase
      .from('stripe_orders')
      .select(`
        *,
        stripe_customers!inner(user_id)
      `)
      .order('created_at', { ascending: false });

    const fromDate = searchParams.get('from');
    const toDate = searchParams.get('to');
    
    if (fromDate) {
      query = query.gte('created_at', fromDate);
    }
    if (toDate) {
      query = query.lte('created_at', toDate);
    }

    const { data: orders, error } = await query;

    if (error) throw error;

    return new Response(
      JSON.stringify(orders || []),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error fetching voucher sales:', error);
    throw error;
  }
}

async function getClients(searchParams: URLSearchParams) {
  try {
    const { data: clients, error } = await supabase
      .from('crm_clients')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    return new Response(
      JSON.stringify(clients || []),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error fetching clients:', error);
    throw error;
  }
}

async function getPopularImages() {
  try {
    // Mock popular images data - replace with actual implementation
    const popularImages = [
      {
        id: '1',
        url: 'https://images.pexels.com/photos/1668928/pexels-photo-1668928.jpeg',
        title: 'Family Portrait Session',
        views: 1250
      },
      {
        id: '2',
        url: 'https://images.pexels.com/photos/3875080/pexels-photo-3875080.jpeg',
        title: 'Newborn Photography',
        views: 980
      },
      {
        id: '3',
        url: 'https://images.pexels.com/photos/3662850/pexels-photo-3662850.jpeg',
        title: 'Maternity Shoot',
        views: 875
      }
    ];

    return new Response(
      JSON.stringify(popularImages),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error fetching popular images:', error);
    throw error;
  }
}