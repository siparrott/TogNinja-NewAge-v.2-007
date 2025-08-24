-- Supabase Schema Setup and Data Import
-- This script creates tables and imports data directly

-- First, ensure we have the required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create CRM Clients table
CREATE TABLE IF NOT EXISTS crm_clients (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    first_name TEXT,
    last_name TEXT,
    client_id TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'Austria',
    notes TEXT,
    tags TEXT[],
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create CRM Leads table
CREATE TABLE IF NOT EXISTS crm_leads (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    source TEXT,
    status TEXT DEFAULT 'new',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Photography Sessions table
CREATE TABLE IF NOT EXISTS photography_sessions (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    client_id VARCHAR REFERENCES crm_clients(id),
    session_type TEXT,
    scheduled_date TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER DEFAULT 60,
    location TEXT,
    photographer TEXT,
    status TEXT DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Blog Posts table
CREATE TABLE IF NOT EXISTS blog_posts (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    title TEXT NOT NULL,
    slug TEXT UNIQUE,
    content TEXT,
    excerpt TEXT,
    featured_image TEXT,
    status TEXT DEFAULT 'draft',
    meta_title TEXT,
    meta_description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    published_at TIMESTAMP WITH TIME ZONE
);

-- Create Galleries table
CREATE TABLE IF NOT EXISTS galleries (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    description TEXT,
    cover_image TEXT,
    is_public BOOLEAN DEFAULT false,
    password_protected BOOLEAN DEFAULT false,
    gallery_password TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create CRM Messages table
CREATE TABLE IF NOT EXISTS crm_messages (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    subject TEXT,
    sender_email TEXT,
    recipient_email TEXT,
    message_body TEXT,
    message_type TEXT DEFAULT 'email',
    status TEXT DEFAULT 'sent',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Voucher Products table
CREATE TABLE IF NOT EXISTS voucher_products (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    currency TEXT DEFAULT 'EUR',
    validity_days INTEGER DEFAULT 365,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create CRM Invoices table
CREATE TABLE IF NOT EXISTS crm_invoices (
    id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
    client_id VARCHAR REFERENCES crm_clients(id),
    invoice_number TEXT UNIQUE,
    amount DECIMAL(10,2),
    currency TEXT DEFAULT 'EUR',
    status TEXT DEFAULT 'draft',
    due_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Success message
SELECT 'Supabase schema setup completed successfully!' as result;