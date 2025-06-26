/*
  # Photography Business Enhancement Tables

  1. New Tables
    - `projects` - Photography session management
    - `equipment` - Camera gear and equipment tracking
    - `locations` - Shooting location database
    - `contracts` - Client contract management
    - `expenses` - Business expense tracking
    - `reviews` - Client review system
    - `social_posts` - Social media content planning
    - `backups` - Backup logging system

  2. Security
    - Enable RLS on all tables
    - Admin-only access for management
    - Public read access for reviews
*/

-- Projects Table (Photography Sessions)
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_name text NOT NULL,
  client_email text,
  client_phone text,
  project_name text NOT NULL,
  project_type text CHECK (project_type IN ('wedding', 'family', 'newborn', 'maternity', 'business', 'event', 'other')),
  status text DEFAULT 'planning' CHECK (status IN ('planning', 'in_progress', 'editing', 'delivered', 'completed', 'cancelled')),
  shoot_date timestamptz,
  delivery_date timestamptz,
  location text,
  equipment_used text[],
  photos_taken integer DEFAULT 0,
  photos_delivered integer DEFAULT 0,
  editing_notes text,
  client_feedback text,
  rating integer CHECK (rating >= 1 AND rating <= 5),
  total_amount decimal(10,2),
  deposit_amount decimal(10,2),
  deposit_paid boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Equipment Table
CREATE TABLE IF NOT EXISTS equipment (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text CHECK (category IN ('camera', 'lens', 'lighting', 'tripod', 'accessory', 'other')),
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

-- Locations Table
CREATE TABLE IF NOT EXISTS locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  address text,
  city text,
  country text DEFAULT 'Austria',
  location_type text CHECK (location_type IN ('studio', 'outdoor', 'venue', 'church', 'park', 'beach', 'urban', 'other')),
  accessibility text,
  parking_info text,
  best_time text,
  lighting_conditions text,
  permits_required boolean DEFAULT false,
  cost decimal(10,2),
  contact_person text,
  contact_phone text,
  contact_email text,
  notes text,
  photos text[], -- URLs to location photos
  is_favorite boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Contracts Table
CREATE TABLE IF NOT EXISTS contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id),
  client_name text NOT NULL,
  client_email text NOT NULL,
  contract_number text UNIQUE NOT NULL,
  contract_type text CHECK (contract_type IN ('photography', 'videography', 'combined', 'other')),
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'signed', 'completed', 'cancelled')),
  total_amount decimal(10,2) NOT NULL,
  deposit_amount decimal(10,2),
  deposit_paid boolean DEFAULT false,
  deposit_date date,
  final_payment_due date,
  final_payment_date date,
  terms_and_conditions text,
  cancellation_policy text,
  signed_date date,
  client_signature text, -- Base64 encoded signature
  photographer_signature text,
  contract_file_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Expenses Table
CREATE TABLE IF NOT EXISTS expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text CHECK (category IN ('equipment', 'travel', 'marketing', 'software', 'insurance', 'education', 'office', 'other')),
  subcategory text,
  description text NOT NULL,
  amount decimal(10,2) NOT NULL,
  currency text DEFAULT 'EUR',
  expense_date date NOT NULL,
  payment_method text CHECK (payment_method IN ('cash', 'card', 'bank_transfer', 'paypal', 'other')),
  vendor text,
  receipt_url text,
  is_business_expense boolean DEFAULT true,
  is_tax_deductible boolean DEFAULT true,
  project_id uuid REFERENCES projects(id),
  notes text,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- Reviews Table
CREATE TABLE IF NOT EXISTS reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id),
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title text,
  review_text text NOT NULL,
  reviewer_name text NOT NULL,
  reviewer_email text,
  is_public boolean DEFAULT false,
  is_featured boolean DEFAULT false,
  platform text CHECK (platform IN ('google', 'facebook', 'website', 'email', 'other')),
  review_date date DEFAULT CURRENT_DATE,
  response_text text,
  response_date date,
  photos text[], -- URLs to photos shared by client
  created_at timestamptz DEFAULT now()
);

-- Social Posts Table
CREATE TABLE IF NOT EXISTS social_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text CHECK (platform IN ('instagram', 'facebook', 'twitter', 'linkedin', 'tiktok', 'pinterest')),
  post_type text CHECK (post_type IN ('photo', 'video', 'story', 'reel', 'carousel')),
  title text,
  caption text,
  hashtags text[],
  media_urls text[],
  scheduled_date timestamptz,
  published_date timestamptz,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'published', 'failed')),
  engagement_stats jsonb,
  project_id uuid REFERENCES projects(id),
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Backups Table
CREATE TABLE IF NOT EXISTS backups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  backup_type text CHECK (backup_type IN ('database', 'files', 'photos', 'full')),
  backup_location text NOT NULL,
  backup_size_mb integer,
  status text DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'failed')),
  started_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  error_message text,
  files_count integer,
  created_by uuid REFERENCES auth.users(id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_projects_client_email ON projects(client_email);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_shoot_date ON projects(shoot_date);
CREATE INDEX IF NOT EXISTS idx_projects_project_type ON projects(project_type);
CREATE INDEX IF NOT EXISTS idx_equipment_category ON equipment(category);
CREATE INDEX IF NOT EXISTS idx_equipment_condition ON equipment(condition);
CREATE INDEX IF NOT EXISTS idx_equipment_is_active ON equipment(is_active);
CREATE INDEX IF NOT EXISTS idx_locations_type ON locations(location_type);
CREATE INDEX IF NOT EXISTS idx_locations_city ON locations(city);
CREATE INDEX IF NOT EXISTS idx_locations_is_favorite ON locations(is_favorite);
CREATE INDEX IF NOT EXISTS idx_contracts_project_id ON contracts(project_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON contracts(status);
CREATE INDEX IF NOT EXISTS idx_contracts_contract_number ON contracts(contract_number);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_project_id ON expenses(project_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_public ON reviews(is_public);
CREATE INDEX IF NOT EXISTS idx_reviews_featured ON reviews(is_featured);
CREATE INDEX IF NOT EXISTS idx_social_posts_platform ON social_posts(platform);
CREATE INDEX IF NOT EXISTS idx_social_posts_scheduled ON social_posts(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_social_posts_status ON social_posts(status);
CREATE INDEX IF NOT EXISTS idx_backups_type ON backups(backup_type);
CREATE INDEX IF NOT EXISTS idx_backups_status ON backups(status);

-- Enable RLS on all new tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE backups ENABLE ROW LEVEL SECURITY;

-- Create admin-only policies for all new tables
CREATE POLICY "Admin users can manage projects"
  ON projects FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage equipment"
  ON equipment FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage locations"
  ON locations FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage contracts"
  ON contracts FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage expenses"
  ON expenses FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage reviews"
  ON reviews FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Public can read public reviews"
  ON reviews FOR SELECT TO public
  USING (is_public = true);

CREATE POLICY "Admin users can manage social posts"
  ON social_posts FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage backups"
  ON backups FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

-- Insert sample data
INSERT INTO equipment (name, category, brand, model, purchase_date, purchase_price, current_value) VALUES
('Canon EOS R5', 'camera', 'Canon', 'EOS R5', '2024-01-15', 3899.00, 3500.00),
('Canon RF 24-70mm f/2.8L', 'lens', 'Canon', 'RF 24-70mm f/2.8L IS USM', '2024-01-15', 2299.00, 2100.00),
('Godox AD600Pro', 'lighting', 'Godox', 'AD600Pro', '2024-02-01', 899.00, 800.00),
('Manfrotto Carbon Tripod', 'tripod', 'Manfrotto', 'MT055CXPRO4', '2024-01-20', 449.00, 400.00);

INSERT INTO locations (name, address, city, location_type, best_time, notes) VALUES
('Stadtpark Wien', 'Stadtpark, 1030 Wien', 'Wien', 'park', 'Golden hour (1 hour before sunset)', 'Beautiful for family portraits, good lighting'),
('Schönbrunn Palace Gardens', 'Schönbrunner Schloßstraße 47, 1130 Wien', 'Wien', 'outdoor', 'Morning or late afternoon', 'Historic backdrop, permits may be required for commercial shoots'),
('Studio New Age', 'Mariahilfer Str. 123, 1060 Wien', 'Wien', 'studio', 'Any time', 'Fully equipped studio with professional lighting'),
('Danube Island', 'Donauinsel, 1220 Wien', 'Wien', 'outdoor', 'Sunset', 'Great for engagement and couple shoots');

-- Insert sample projects
INSERT INTO projects (client_name, client_email, project_name, project_type, status, shoot_date, total_amount, deposit_amount) VALUES
('Sarah Mueller', 'sarah.mueller@email.com', 'Mueller Family Portrait', 'family', 'completed', '2024-06-15 10:00:00+02', 295.00, 100.00),
('Michael & Lisa Weber', 'michael.weber@email.com', 'Weber Wedding', 'wedding', 'editing', '2024-06-20 14:00:00+02', 1500.00, 500.00),
('Anna Wagner', 'anna.wagner@email.com', 'Wagner Newborn Session', 'newborn', 'delivered', '2024-06-10 11:00:00+02', 350.00, 150.00);

-- Insert sample reviews
INSERT INTO reviews (project_id, rating, title, review_text, reviewer_name, is_public, is_featured) VALUES
((SELECT id FROM projects WHERE client_name = 'Sarah Mueller'), 5, 'Amazing Family Photos!', 'Matt captured our family perfectly. The kids were comfortable and the photos turned out beautiful. Highly recommend!', 'Sarah M.', true, true),
((SELECT id FROM projects WHERE client_name = 'Michael & Lisa Weber'), 5, 'Professional Wedding Photography', 'Exceptional service from start to finish. The photos exceeded our expectations and captured every special moment.', 'Michael & Lisa', true, true),
((SELECT id FROM projects WHERE client_name = 'Anna Wagner'), 4, 'Great Newborn Session', 'Very patient with our newborn and created beautiful memories. The studio was warm and comfortable.', 'Anna W.', true, false);

-- Insert sample expenses
INSERT INTO expenses (category, description, amount, expense_date, payment_method, vendor, is_business_expense) VALUES
('equipment', 'Canon RF 85mm f/1.2L USM Lens', 2699.00, '2024-06-01', 'card', 'Foto Leistenschneider', true),
('marketing', 'Google Ads Campaign - June', 150.00, '2024-06-01', 'card', 'Google', true),
('software', 'Adobe Creative Cloud Subscription', 59.99, '2024-06-01', 'card', 'Adobe', true),
('travel', 'Fuel for wedding shoot in Salzburg', 45.00, '2024-06-20', 'card', 'OMV', true);