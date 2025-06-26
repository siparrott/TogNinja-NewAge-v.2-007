/*
  # Add New CRM Tables

  1. New Tables
    - `crm_projects` - Photography project management
    - `crm_packages` - Service packages and pricing
    - `crm_equipment` - Equipment tracking and maintenance
    - `crm_locations` - Shooting locations database
    - `crm_contracts` - Contract management
    - `crm_expenses` - Business expense tracking
    - `crm_reviews` - Client reviews and testimonials
    - `crm_social_media` - Social media post scheduling
    - `crm_analytics` - Business analytics and metrics
    - `crm_backups` - Data backup logs

  2. Security
    - Enable RLS on all new tables
    - Add admin-only policies
*/

-- Photography Projects Table
CREATE TABLE IF NOT EXISTS crm_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  client_id uuid REFERENCES crm_clients(id),
  project_type text NOT NULL, -- 'wedding', 'family', 'corporate', etc.
  status text DEFAULT 'planning' CHECK (status IN ('planning', 'in_progress', 'editing', 'delivered', 'completed', 'cancelled')),
  start_date date,
  end_date date,
  budget decimal(10,2),
  actual_cost decimal(10,2),
  location text,
  notes text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Service Packages Table
CREATE TABLE IF NOT EXISTS crm_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  package_type text NOT NULL, -- 'wedding', 'family', 'corporate', etc.
  price decimal(10,2) NOT NULL,
  duration_hours integer,
  included_photos integer,
  included_prints integer,
  features jsonb, -- Array of included features
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Equipment Tracking Table
CREATE TABLE IF NOT EXISTS crm_equipment (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text NOT NULL, -- 'camera', 'lens', 'lighting', 'accessory'
  brand text,
  model text,
  serial_number text,
  purchase_date date,
  purchase_price decimal(10,2),
  current_value decimal(10,2),
  condition text DEFAULT 'excellent' CHECK (condition IN ('excellent', 'good', 'fair', 'poor', 'needs_repair')),
  last_maintenance date,
  next_maintenance date,
  location text,
  notes text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Shooting Locations Table
CREATE TABLE IF NOT EXISTS crm_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  address text,
  city text,
  country text,
  latitude decimal(10, 8),
  longitude decimal(11, 8),
  location_type text, -- 'indoor', 'outdoor', 'studio', 'venue'
  capacity integer,
  hourly_rate decimal(10,2),
  contact_person text,
  contact_phone text,
  contact_email text,
  amenities jsonb, -- Array of available amenities
  restrictions text,
  photos jsonb, -- Array of location photo URLs
  rating integer CHECK (rating >= 1 AND rating <= 5),
  notes text,
  is_available boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Contracts Table
CREATE TABLE IF NOT EXISTS crm_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_number text UNIQUE NOT NULL,
  client_id uuid REFERENCES crm_clients(id) NOT NULL,
  project_id uuid REFERENCES crm_projects(id),
  template_name text,
  contract_type text, -- 'photography', 'videography', 'combined'
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'signed', 'completed', 'cancelled')),
  total_amount decimal(10,2),
  deposit_amount decimal(10,2),
  deposit_paid boolean DEFAULT false,
  deposit_date date,
  start_date date,
  end_date date,
  terms_conditions text,
  special_clauses text,
  signed_date date,
  contract_file_url text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Business Expenses Table
CREATE TABLE IF NOT EXISTS crm_expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  description text NOT NULL,
  category text NOT NULL, -- 'equipment', 'travel', 'marketing', 'software', 'insurance', etc.
  amount decimal(10,2) NOT NULL,
  currency text DEFAULT 'EUR',
  expense_date date NOT NULL,
  vendor text,
  payment_method text, -- 'cash', 'card', 'bank_transfer', 'paypal'
  receipt_url text,
  is_business_expense boolean DEFAULT true,
  is_tax_deductible boolean DEFAULT true,
  project_id uuid REFERENCES crm_projects(id),
  notes text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Client Reviews Table
CREATE TABLE IF NOT EXISTS crm_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES crm_clients(id) NOT NULL,
  project_id uuid REFERENCES crm_projects(id),
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title text,
  review_text text,
  is_public boolean DEFAULT false,
  is_featured boolean DEFAULT false,
  platform text, -- 'google', 'facebook', 'website', 'yelp'
  platform_url text,
  review_date date DEFAULT CURRENT_DATE,
  response_text text,
  response_date date,
  photos jsonb, -- Array of review photo URLs
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Social Media Posts Table
CREATE TABLE IF NOT EXISTS crm_social_media (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL, -- 'instagram', 'facebook', 'twitter', 'linkedin'
  post_type text NOT NULL, -- 'photo', 'video', 'story', 'reel'
  content text NOT NULL,
  hashtags text,
  media_urls jsonb, -- Array of image/video URLs
  scheduled_date timestamptz,
  published_date timestamptz,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'published', 'failed')),
  engagement_stats jsonb, -- likes, comments, shares, etc.
  project_id uuid REFERENCES crm_projects(id),
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Business Analytics Table
CREATE TABLE IF NOT EXISTS crm_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name text NOT NULL,
  metric_value decimal(15,2),
  metric_type text NOT NULL, -- 'revenue', 'bookings', 'leads', 'conversion_rate', etc.
  period_type text NOT NULL, -- 'daily', 'weekly', 'monthly', 'yearly'
  period_start date NOT NULL,
  period_end date NOT NULL,
  metadata jsonb, -- Additional metric details
  created_at timestamptz DEFAULT now()
);

-- Data Backup Logs Table
CREATE TABLE IF NOT EXISTS crm_backups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  backup_type text NOT NULL, -- 'full', 'incremental', 'photos', 'database'
  backup_size bigint, -- Size in bytes
  backup_location text,
  backup_status text DEFAULT 'in_progress' CHECK (backup_status IN ('in_progress', 'completed', 'failed')),
  started_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  error_message text,
  created_by uuid REFERENCES auth.users(id)
);

-- Enable RLS on all new tables
ALTER TABLE crm_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_social_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_backups ENABLE ROW LEVEL SECURITY;

-- Create admin-only policies for all new tables
CREATE POLICY "Admin users can manage projects"
  ON crm_projects FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage packages"
  ON crm_packages FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage equipment"
  ON crm_equipment FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage locations"
  ON crm_locations FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage contracts"
  ON crm_contracts FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage expenses"
  ON crm_expenses FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage reviews"
  ON crm_reviews FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage social media"
  ON crm_social_media FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage analytics"
  ON crm_analytics FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage backups"
  ON crm_backups FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

-- Insert sample data for packages
INSERT INTO crm_packages (name, description, package_type, price, duration_hours, included_photos, included_prints, features) VALUES
('Family Basic', 'Perfect for small families', 'family', 195.00, 1, 15, 5, '["Professional editing", "Online gallery", "Print release"]'),
('Family Premium', 'Ideal for larger families', 'family', 295.00, 2, 25, 10, '["Professional editing", "Online gallery", "Print release", "USB drive"]'),
('Wedding Essential', 'Complete wedding coverage', 'wedding', 1495.00, 8, 100, 20, '["Engagement session", "Wedding day coverage", "Online gallery", "Print release", "USB drive"]'),
('Corporate Headshots', 'Professional business portraits', 'corporate', 150.00, 1, 10, 5, '["Professional editing", "High-resolution files", "LinkedIn optimization"]'),
('Newborn Session', 'Gentle newborn photography', 'newborn', 250.00, 2, 20, 8, '["Props included", "Parent shots", "Online gallery", "Print release"]');

-- Insert sample equipment data
INSERT INTO crm_equipment (name, category, brand, model, purchase_date, purchase_price, current_value, condition) VALUES
('Canon EOS R5', 'camera', 'Canon', 'EOS R5', '2023-01-15', 3899.00, 3200.00, 'excellent'),
('Canon RF 24-70mm f/2.8L', 'lens', 'Canon', 'RF 24-70mm f/2.8L IS USM', '2023-01-15', 2299.00, 1900.00, 'excellent'),
('Profoto B10', 'lighting', 'Profoto', 'B10', '2023-03-20', 1695.00, 1400.00, 'good'),
('Manfrotto Carbon Tripod', 'accessory', 'Manfrotto', 'MT055CXPRO4', '2023-02-10', 399.00, 320.00, 'good');

-- Insert sample locations
INSERT INTO crm_locations (name, address, city, country, location_type, capacity, amenities, rating) VALUES
('Stadtpark Wien', 'Stadtpark, 1030 Wien', 'Wien', 'Austria', 'outdoor', 50, '["Natural lighting", "Multiple backdrops", "Parking available"]', 5),
('Schönbrunn Palace Gardens', 'Schönbrunner Schloßstraße 47, 1130 Wien', 'Wien', 'Austria', 'outdoor', 100, '["Historic architecture", "Beautiful gardens", "Tourist attraction"]', 5),
('Studio Loft Vienna', 'Mariahilfer Str. 123, 1060 Wien', 'Wien', 'Austria', 'indoor', 20, '["Professional lighting", "Backdrop system", "Changing room", "Kitchen"]', 4);