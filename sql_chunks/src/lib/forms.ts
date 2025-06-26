import { supabase } from './supabase';

interface ContactFormData {
  fullName: string;
  email: string;
  phone: string;
  message: string;
}

interface WaitlistFormData extends ContactFormData {
  preferredDate: string;
}

export async function submitContactForm(formData: ContactFormData) {
  try {
    // First try the Edge Function
    const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/public/contact/kontakt`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
      },
      body: JSON.stringify(formData),
    });

    if (!response.ok) {
      // If Edge Function fails, fall back to direct database insert
      console.warn('Edge Function failed, using fallback method');
      return await submitContactFormFallback(formData);
    }

    return await response.json();
  } catch (error) {
    console.error('Error with Edge Function, trying fallback:', error);
    // Fallback to direct database insert
    return await submitContactFormFallback(formData);
  }
}

export async function submitWaitlistForm(formData: WaitlistFormData) {
  try {
    // First try the Edge Function
    const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/public/contact/warteliste`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
      },
      body: JSON.stringify(formData),
    });

    if (!response.ok) {
      // If Edge Function fails, fall back to direct database insert
      console.warn('Edge Function failed, using fallback method');
      return await submitWaitlistFormFallback(formData);
    }

    return await response.json();
  } catch (error) {
    console.error('Error with Edge Function, trying fallback:', error);
    // Fallback to direct database insert
    return await submitWaitlistFormFallback(formData);
  }
}

// Fallback functions that insert directly into the database
async function submitContactFormFallback(formData: ContactFormData) {
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
    });

  if (error) {
    console.error('Database error:', error);
    throw new Error('Failed to submit contact form');
  }

  return { success: true, message: 'Contact form submitted successfully' };
}

async function submitWaitlistFormFallback(formData: WaitlistFormData) {
  const message = `Preferred Date: ${formData.preferredDate}${formData.message ? '\n\nMessage: ' + formData.message : ''}`;

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
    });

  if (error) {
    console.error('Database error:', error);
    throw new Error('Failed to submit waitlist form');
  }

  return { success: true, message: 'Waitlist form submitted successfully' };
}

export async function submitNewsletterForm(email: string) {
  try {
    const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/newsletter-signup`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.error || 'Failed to submit newsletter signup');
    }

    return await response.json();
  } catch (error) {
    console.error('Error submitting newsletter signup:', error);
    throw error;
  }
}