import { supabase } from './supabase';

export interface Lead {
  id: string;
  form_source: 'WARTELISTE' | 'KONTAKT';
  first_name: string | null;
  last_name: string | null;
  email: string;
  phone: string | null;
  message: string | null;
  created_at: string;
  status: 'NEW' | 'CONTACTED' | 'CONVERTED';
}

export async function getLeads(status?: 'NEW' | 'CONTACTED' | 'CONVERTED') {
  try {
    let query = supabase
      .from('leads')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (status) {
      query = query.eq('status', status);
    }
    
    const { data, error } = await query;
    
    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching leads:', error);
    throw error;
  }
}

export async function updateLeadStatus(id: string, status: 'NEW' | 'CONTACTED' | 'CONVERTED') {
  try {
    const { data, error } = await supabase
      .from('leads')
      .update({ status })
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error updating lead status:', error);
    throw error;
  }
}

export async function deleteLead(id: string) {
  try {
    const { error } = await supabase
      .from('leads')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error deleting lead:', error);
    throw error;
  }
}