import { supabase } from './supabase';
import { Client } from '../types/client';

// Fetch top clients ordered by totalSales
export async function getHighValueClients(limit = 10): Promise<Client[]> {
  try {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .order('total_sales', { ascending: false })
      .limit(limit);

    if (error) throw error;

    // Map database fields to Client interface (if needed)
    return (data || []).map((row: any) => ({
      id: row.id,
      firstName: row.first_name || row.firstName || '',
      lastName: row.last_name || row.lastName || '',
      clientId: row.client_id || row.clientId || '',
      email: row.email,
      phone: row.phone || '',
      address1: row.address1 || row.address || '',
      address2: row.address2 || '',
      city: row.city || '',
      state: row.state || '',
      zip: row.zip || '',
      country: row.country || '',
      totalSales: row.total_sales || row.totalSales || 0,
      outstandingBalance: row.outstanding_balance || row.outstandingBalance || 0,
      createdAt: row.created_at || row.createdAt,
      updatedAt: row.updated_at || row.updatedAt,
    }));
  } catch (error) {
    console.error('Error fetching high value clients:', error);
    throw error;
  }
}
