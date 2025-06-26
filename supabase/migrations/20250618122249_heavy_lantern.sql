/*
  # Analytics Database Schema

  1. New Tables for Analytics
    - `business_metrics` - Core business KPIs
    - `client_analytics` - Client-specific analytics
    - `marketing_analytics` - Marketing campaign performance
    - `website_analytics` - Website traffic and conversion data
    - `social_media_analytics` - Social media performance
    - `financial_analytics` - Financial reporting data

  2. Views for Reporting
    - `monthly_revenue_view` - Monthly revenue aggregation
    - `client_performance_view` - Client performance metrics
    - `marketing_roi_view` - Marketing ROI calculations
*/

-- Business Metrics Table
CREATE TABLE IF NOT EXISTS business_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name text NOT NULL,
  metric_value decimal(15,2) NOT NULL,
  metric_type text NOT NULL CHECK (metric_type IN ('revenue', 'bookings', 'leads', 'conversion_rate', 'client_satisfaction', 'expenses', 'profit')),
  period_type text NOT NULL CHECK (period_type IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
  period_start date NOT NULL,
  period_end date NOT NULL,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Client Analytics Table
CREATE TABLE IF NOT EXISTS client_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL,
  total_bookings integer DEFAULT 0,
  total_revenue decimal(10,2) DEFAULT 0,
  average_session_value decimal(10,2) DEFAULT 0,
  last_booking_date date,
  client_lifetime_value decimal(10,2) DEFAULT 0,
  referral_count integer DEFAULT 0,
  satisfaction_score decimal(3,2), -- 1.00 to 5.00
  acquisition_cost decimal(10,2),
  acquisition_channel text,
  first_booking_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Marketing Analytics Table
CREATE TABLE IF NOT EXISTS marketing_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_name text NOT NULL,
  campaign_type text NOT NULL CHECK (campaign_type IN ('social_media', 'email', 'google_ads', 'facebook_ads', 'referral', 'organic', 'print', 'radio')),
  impressions integer DEFAULT 0,
  clicks integer DEFAULT 0,
  conversions integer DEFAULT 0,
  leads_generated integer DEFAULT 0,
  cost decimal(10,2) DEFAULT 0,
  revenue decimal(10,2) DEFAULT 0,
  roi decimal(5,2), -- Return on Investment percentage
  ctr decimal(5,4), -- Click-through rate
  conversion_rate decimal(5,4), -- Conversion rate percentage
  cost_per_lead decimal(10,2),
  cost_per_acquisition decimal(10,2),
  period_start date NOT NULL,
  period_end date NOT NULL,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Website Analytics Table
CREATE TABLE IF NOT EXISTS website_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date date NOT NULL,
  page_path text NOT NULL,
  page_views integer DEFAULT 0,
  unique_visitors integer DEFAULT 0,
  bounce_rate decimal(5,4),
  avg_session_duration integer, -- in seconds
  conversions integer DEFAULT 0,
  conversion_rate decimal(5,4),
  traffic_source text, -- 'organic', 'direct', 'social', 'referral', 'paid'
  device_type text, -- 'desktop', 'mobile', 'tablet'
  created_at timestamptz DEFAULT now()
);

-- Social Media Analytics Table
CREATE TABLE IF NOT EXISTS social_media_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL CHECK (platform IN ('instagram', 'facebook', 'twitter', 'linkedin', 'tiktok', 'youtube')),
  post_id text,
  post_type text, -- 'photo', 'video', 'story', 'reel', 'carousel'
  post_date date NOT NULL,
  impressions integer DEFAULT 0,
  reach integer DEFAULT 0,
  likes integer DEFAULT 0,
  comments integer DEFAULT 0,
  shares integer DEFAULT 0,
  saves integer DEFAULT 0,
  clicks integer DEFAULT 0,
  engagement_rate decimal(5,4),
  follower_count integer,
  hashtags text[],
  created_at timestamptz DEFAULT now()
);

-- Financial Analytics Table
CREATE TABLE IF NOT EXISTS financial_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  period_start date NOT NULL,
  period_end date NOT NULL,
  period_type text NOT NULL CHECK (period_type IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
  gross_revenue decimal(10,2) DEFAULT 0,
  net_revenue decimal(10,2) DEFAULT 0,
  total_expenses decimal(10,2) DEFAULT 0,
  equipment_expenses decimal(10,2) DEFAULT 0,
  marketing_expenses decimal(10,2) DEFAULT 0,
  travel_expenses decimal(10,2) DEFAULT 0,
  software_expenses decimal(10,2) DEFAULT 0,
  other_expenses decimal(10,2) DEFAULT 0,
  gross_profit decimal(10,2) DEFAULT 0,
  net_profit decimal(10,2) DEFAULT 0,
  profit_margin decimal(5,4),
  tax_amount decimal(10,2) DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_business_metrics_type_period ON business_metrics(metric_type, period_type, period_start);
CREATE INDEX IF NOT EXISTS idx_client_analytics_client_id ON client_analytics(client_id);
CREATE INDEX IF NOT EXISTS idx_marketing_analytics_campaign_type ON marketing_analytics(campaign_type, period_start);
CREATE INDEX IF NOT EXISTS idx_website_analytics_date_path ON website_analytics(date, page_path);
CREATE INDEX IF NOT EXISTS idx_social_media_analytics_platform_date ON social_media_analytics(platform, post_date);
CREATE INDEX IF NOT EXISTS idx_financial_analytics_period ON financial_analytics(period_type, period_start);

-- Enable RLS on all analytics tables
ALTER TABLE business_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE website_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_media_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_analytics ENABLE ROW LEVEL SECURITY;

-- Create admin-only policies for analytics tables
CREATE POLICY "Admin users can manage business metrics"
  ON business_metrics FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage client analytics"
  ON client_analytics FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage marketing analytics"
  ON marketing_analytics FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage website analytics"
  ON website_analytics FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage social media analytics"
  ON social_media_analytics FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

CREATE POLICY "Admin users can manage financial analytics"
  ON financial_analytics FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true))
  WITH CHECK (EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND is_admin = true));

-- Create useful views for reporting
CREATE OR REPLACE VIEW monthly_revenue_view AS
SELECT 
  DATE_TRUNC('month', period_start) as month,
  SUM(metric_value) as total_revenue,
  COUNT(*) as data_points,
  AVG(metric_value) as avg_daily_revenue
FROM business_metrics 
WHERE metric_type = 'revenue' AND period_type = 'daily'
GROUP BY DATE_TRUNC('month', period_start)
ORDER BY month DESC;

CREATE OR REPLACE VIEW client_performance_view AS
SELECT 
  ca.*,
  CASE 
    WHEN ca.client_lifetime_value > 1000 THEN 'high_value'
    WHEN ca.client_lifetime_value > 500 THEN 'medium_value'
    ELSE 'low_value'
  END as value_segment,
  CASE 
    WHEN ca.last_booking_date > CURRENT_DATE - INTERVAL '30 days' THEN 'active'
    WHEN ca.last_booking_date > CURRENT_DATE - INTERVAL '90 days' THEN 'recent'
    WHEN ca.last_booking_date > CURRENT_DATE - INTERVAL '365 days' THEN 'dormant'
    ELSE 'inactive'
  END as activity_status
FROM client_analytics ca;

CREATE OR REPLACE VIEW marketing_roi_view AS
SELECT 
  campaign_type,
  SUM(cost) as total_cost,
  SUM(revenue) as total_revenue,
  SUM(conversions) as total_conversions,
  SUM(leads_generated) as total_leads,
  CASE 
    WHEN SUM(cost) > 0 THEN (SUM(revenue) - SUM(cost)) / SUM(cost) * 100
    ELSE 0 
  END as roi_percentage,
  CASE 
    WHEN SUM(leads_generated) > 0 THEN SUM(cost) / SUM(leads_generated)
    ELSE 0 
  END as avg_cost_per_lead
FROM marketing_analytics
GROUP BY campaign_type
ORDER BY roi_percentage DESC;

-- Insert sample analytics data
INSERT INTO business_metrics (metric_name, metric_value, metric_type, period_type, period_start, period_end) VALUES
('daily_revenue', 450.00, 'revenue', 'daily', '2025-01-25', '2025-01-25'),
('daily_bookings', 3, 'bookings', 'daily', '2025-01-25', '2025-01-25'),
('monthly_revenue', 12500.00, 'revenue', 'monthly', '2025-01-01', '2025-01-31'),
('conversion_rate', 15.5, 'conversion_rate', 'monthly', '2025-01-01', '2025-01-31');

INSERT INTO marketing_analytics (campaign_name, campaign_type, impressions, clicks, conversions, cost, revenue, period_start, period_end) VALUES
('Instagram Family Photos', 'social_media', 5000, 250, 12, 150.00, 2400.00, '2025-01-01', '2025-01-31'),
('Google Ads Wedding', 'google_ads', 8000, 400, 8, 300.00, 4000.00, '2025-01-01', '2025-01-31'),
('Facebook Business Portraits', 'facebook_ads', 3000, 180, 6, 120.00, 900.00, '2025-01-01', '2025-01-31');