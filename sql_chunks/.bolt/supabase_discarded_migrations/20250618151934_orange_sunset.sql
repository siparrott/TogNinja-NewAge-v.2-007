/*
  # Galleries Module Schema

  1. New Tables
    - `galleries` - Main gallery information
    - `gallery_images` - Images within galleries
    - `gallery_visitors` - Visitors who access galleries
    - `image_actions` - Track visitor interactions with images

  2. Security
    - Enable RLS on all tables
    - Admin-only access for management
    - Public access for viewing with proper authentication
*/

-- Galleries Table
CREATE TABLE IF NOT EXISTS galleries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  cover_image text,
  password_hash text, -- null means public gallery
  download_enabled boolean DEFAULT true,
  created_by uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Gallery Images Table
CREATE TABLE IF NOT EXISTS gallery_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries(id) ON DELETE CASCADE NOT NULL,
  original_url text NOT NULL,
  display_url text NOT NULL, -- 1920px long edge
  thumb_url text NOT NULL, -- 400px long edge
  filename text NOT NULL,
  size_bytes bigint NOT NULL,
  content_type text NOT NULL,
  captured_at timestamptz,
  order_index integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Gallery Visitors Table
CREATE TABLE IF NOT EXISTS gallery_visitors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries(id) ON DELETE CASCADE NOT NULL,
  email text NOT NULL,
  access_token uuid DEFAULT gen_random_uuid() NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Image Actions Table
CREATE TABLE IF NOT EXISTS image_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_id uuid REFERENCES gallery_visitors(id) ON DELETE CASCADE NOT NULL,
  image_id uuid REFERENCES gallery_images(id) ON DELETE CASCADE NOT NULL,
  action text NOT NULL CHECK (action IN ('VIEW', 'FAVORITE', 'DOWNLOAD')),
  created_at timestamptz DEFAULT now()
);

-- Gallery Daily Stats Table (for aggregated analytics)
CREATE TABLE IF NOT EXISTS gallery_daily_stats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries(id) ON DELETE CASCADE NOT NULL,
  date date NOT NULL,
  unique_visitors integer DEFAULT 0,
  total_views integer DEFAULT 0,
  total_favorites integer DEFAULT 0,
  total_downloads integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE galleries ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE image_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_daily_stats ENABLE ROW LEVEL SECURITY;

-- Create admin-only policies for galleries
CREATE POLICY "Admin users can manage galleries"
  ON galleries FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create admin-only policies for gallery_images
CREATE POLICY "Admin users can manage gallery_images"
  ON gallery_images FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create admin-only policies for gallery_visitors
CREATE POLICY "Admin users can manage gallery_visitors"
  ON gallery_visitors FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create admin-only policies for image_actions
CREATE POLICY "Admin users can manage image_actions"
  ON image_actions FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create admin-only policies for gallery_daily_stats
CREATE POLICY "Admin users can manage gallery_daily_stats"
  ON gallery_daily_stats FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_galleries_created_by ON galleries(created_by);
CREATE INDEX IF NOT EXISTS idx_galleries_slug ON galleries(slug);
CREATE INDEX IF NOT EXISTS idx_gallery_images_gallery_id ON gallery_images(gallery_id);
CREATE INDEX IF NOT EXISTS idx_gallery_images_order_index ON gallery_images(order_index);
CREATE INDEX IF NOT EXISTS idx_gallery_visitors_gallery_id ON gallery_visitors(gallery_id);
CREATE INDEX IF NOT EXISTS idx_gallery_visitors_access_token ON gallery_visitors(access_token);
CREATE INDEX IF NOT EXISTS idx_image_actions_visitor_id ON image_actions(visitor_id);
CREATE INDEX IF NOT EXISTS idx_image_actions_image_id ON image_actions(image_id);
CREATE INDEX IF NOT EXISTS idx_image_actions_action ON image_actions(action);
CREATE INDEX IF NOT EXISTS idx_gallery_daily_stats_gallery_id_date ON gallery_daily_stats(gallery_id, date);

-- Create function to generate unique slugs for galleries
CREATE OR REPLACE FUNCTION generate_unique_gallery_slug(title_input text)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  base_slug text;
  final_slug text;
  counter integer := 0;
  slug_exists boolean;
BEGIN
  -- Convert title to lowercase and replace spaces with hyphens
  base_slug := lower(regexp_replace(title_input, '[^a-zA-Z0-9\s]', '', 'g'));
  base_slug := regexp_replace(base_slug, '\s+', '-', 'g');
  
  -- Initial slug
  final_slug := base_slug;
  
  -- Check if slug exists
  LOOP
    SELECT EXISTS (
      SELECT 1 FROM galleries WHERE slug = final_slug
    ) INTO slug_exists;
    
    EXIT WHEN NOT slug_exists;
    
    -- Increment counter and append to slug
    counter := counter + 1;
    final_slug := base_slug || '-' || counter::text;
  END LOOP;
  
  RETURN final_slug;
END;
$$;

-- Create trigger to automatically generate slug on insert if not provided
CREATE OR REPLACE FUNCTION galleries_before_insert_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate slug if not provided
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := generate_unique_gallery_slug(NEW.title);
  END IF;
  
  -- Set updated_at timestamp
  NEW.updated_at := now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER galleries_before_insert_update_trigger
BEFORE INSERT OR UPDATE ON galleries
FOR EACH ROW
EXECUTE FUNCTION galleries_before_insert_update();

-- Create function to aggregate daily stats (to be called by a scheduled job)
CREATE OR REPLACE FUNCTION aggregate_gallery_stats(target_date date DEFAULT CURRENT_DATE - INTERVAL '1 day')
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- Delete existing stats for the target date to avoid duplicates
  DELETE FROM gallery_daily_stats WHERE date = target_date;
  
  -- Insert aggregated stats
  INSERT INTO gallery_daily_stats (
    gallery_id,
    date,
    unique_visitors,
    total_views,
    total_favorites,
    total_downloads
  )
  SELECT
    g.id AS gallery_id,
    target_date AS date,
    COUNT(DISTINCT ia.visitor_id) AS unique_visitors,
    COUNT(CASE WHEN ia.action = 'VIEW' THEN 1 END) AS total_views,
    COUNT(CASE WHEN ia.action = 'FAVORITE' THEN 1 END) AS total_favorites,
    COUNT(CASE WHEN ia.action = 'DOWNLOAD' THEN 1 END) AS total_downloads
  FROM
    galleries g
    LEFT JOIN gallery_images gi ON g.id = gi.gallery_id
    LEFT JOIN image_actions ia ON gi.id = ia.image_id
  WHERE
    DATE(ia.created_at) = target_date
  GROUP BY
    g.id;
    
  RETURN;
END;
$$;