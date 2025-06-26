/*
  # Enhanced Gallery Module - Professional Features
  
  This migration restores advanced gallery features that were developed but lost:
  
  1. Professional Gallery System:
    - Password-protected private galleries
    - Multiple image sizes (original, display, thumbnail)
    - Visitor tracking and analytics
    - Download management
    - Image interaction tracking
    
  2. Advanced Features:
    - Gallery visitor management with access tokens
    - Image action tracking (view, favorite, download)
    - Daily statistics aggregation
    - Image metadata and ordering
    - Gallery sharing and access control
    
  3. Analytics & Insights:
    - Visitor analytics
    - Image popularity tracking
    - Download statistics
    - Daily aggregated reports
*/

-- Enhanced Galleries Table
CREATE TABLE IF NOT EXISTS galleries_enhanced (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  description text,
  cover_image text,
  password_hash text, -- null means public gallery
  download_enabled boolean DEFAULT true,
  watermark_enabled boolean DEFAULT false,
  max_downloads_per_visitor integer DEFAULT null, -- null means unlimited
  expires_at timestamptz DEFAULT null, -- null means never expires
  created_by uuid REFERENCES auth.users(id) NOT NULL,
  client_email text, -- for client-specific galleries
  is_featured boolean DEFAULT false,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enhanced Gallery Images Table
CREATE TABLE IF NOT EXISTS gallery_images_enhanced (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries_enhanced(id) ON DELETE CASCADE NOT NULL,
  original_url text NOT NULL,
  display_url text NOT NULL, -- 1920px long edge
  thumb_url text NOT NULL, -- 400px long edge
  filename text NOT NULL,
  title text,
  description text,
  alt_text text,
  size_bytes bigint NOT NULL,
  width integer,
  height integer,
  content_type text NOT NULL,
  camera_make text,
  camera_model text,
  lens_model text,
  focal_length text,
  aperture text,
  shutter_speed text,
  iso integer,
  captured_at timestamptz,
  order_index integer DEFAULT 0,
  is_featured boolean DEFAULT false,
  download_count integer DEFAULT 0,
  view_count integer DEFAULT 0,
  favorite_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Gallery Visitors Table
CREATE TABLE IF NOT EXISTS gallery_visitors_enhanced (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries_enhanced(id) ON DELETE CASCADE NOT NULL,
  name text,
  email text NOT NULL,
  phone text,
  access_token uuid DEFAULT gen_random_uuid() NOT NULL UNIQUE,
  password_attempts integer DEFAULT 0,
  last_access timestamptz,
  total_visits integer DEFAULT 0,
  total_downloads integer DEFAULT 0,
  is_blocked boolean DEFAULT false,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Image Actions Table (for detailed analytics)
CREATE TABLE IF NOT EXISTS image_actions_enhanced (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_id uuid REFERENCES gallery_visitors_enhanced(id) ON DELETE CASCADE,
  gallery_id uuid REFERENCES galleries_enhanced(id) ON DELETE CASCADE NOT NULL,
  image_id uuid REFERENCES gallery_images_enhanced(id) ON DELETE CASCADE NOT NULL,
  action text NOT NULL CHECK (action IN ('VIEW', 'FAVORITE', 'UNFAVORITE', 'DOWNLOAD', 'SHARE')),
  ip_address inet,
  user_agent text,
  session_id text,
  created_at timestamptz DEFAULT now()
);

-- Gallery Daily Stats Table (for aggregated analytics)
CREATE TABLE IF NOT EXISTS gallery_daily_stats_enhanced (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries_enhanced(id) ON DELETE CASCADE NOT NULL,
  date date NOT NULL,
  unique_visitors integer DEFAULT 0,
  total_visits integer DEFAULT 0,
  total_views integer DEFAULT 0,
  total_favorites integer DEFAULT 0,
  total_downloads integer DEFAULT 0,
  average_session_duration interval DEFAULT '0 minutes',
  top_image_id uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(gallery_id, date)
);

-- Gallery Collections Table (for organizing galleries)
CREATE TABLE IF NOT EXISTS gallery_collections_enhanced (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  description text,
  cover_image text,
  is_public boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  created_by uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Junction table for galleries and collections
CREATE TABLE IF NOT EXISTS gallery_collection_items_enhanced (
  collection_id uuid REFERENCES gallery_collections_enhanced(id) ON DELETE CASCADE,
  gallery_id uuid REFERENCES galleries_enhanced(id) ON DELETE CASCADE,
  sort_order integer DEFAULT 0,
  added_at timestamptz DEFAULT now(),
  PRIMARY KEY (collection_id, gallery_id)
);

-- Enable RLS on all tables
ALTER TABLE galleries_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_images_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_visitors_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE image_actions_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_daily_stats_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_collections_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_collection_items_enhanced ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_galleries_enhanced_created_by ON galleries_enhanced(created_by);
CREATE INDEX IF NOT EXISTS idx_galleries_enhanced_slug ON galleries_enhanced(slug);
CREATE INDEX IF NOT EXISTS idx_galleries_enhanced_client_email ON galleries_enhanced(client_email);
CREATE INDEX IF NOT EXISTS idx_galleries_enhanced_featured ON galleries_enhanced(is_featured) WHERE is_featured = true;

CREATE INDEX IF NOT EXISTS idx_gallery_images_enhanced_gallery_id ON gallery_images_enhanced(gallery_id);
CREATE INDEX IF NOT EXISTS idx_gallery_images_enhanced_order ON gallery_images_enhanced(gallery_id, order_index);
CREATE INDEX IF NOT EXISTS idx_gallery_images_enhanced_featured ON gallery_images_enhanced(is_featured) WHERE is_featured = true;

CREATE INDEX IF NOT EXISTS idx_gallery_visitors_enhanced_gallery_id ON gallery_visitors_enhanced(gallery_id);
CREATE INDEX IF NOT EXISTS idx_gallery_visitors_enhanced_email ON gallery_visitors_enhanced(email);
CREATE INDEX IF NOT EXISTS idx_gallery_visitors_enhanced_access_token ON gallery_visitors_enhanced(access_token);

CREATE INDEX IF NOT EXISTS idx_image_actions_enhanced_visitor_id ON image_actions_enhanced(visitor_id);
CREATE INDEX IF NOT EXISTS idx_image_actions_enhanced_gallery_id ON image_actions_enhanced(gallery_id);
CREATE INDEX IF NOT EXISTS idx_image_actions_enhanced_image_id ON image_actions_enhanced(image_id);
CREATE INDEX IF NOT EXISTS idx_image_actions_enhanced_action ON image_actions_enhanced(action);
CREATE INDEX IF NOT EXISTS idx_image_actions_enhanced_created_at ON image_actions_enhanced(created_at);

CREATE INDEX IF NOT EXISTS idx_gallery_daily_stats_enhanced_gallery_date ON gallery_daily_stats_enhanced(gallery_id, date);

-- Create admin policies for galleries_enhanced
CREATE POLICY "Admin users can manage galleries"
  ON galleries_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Public can view public galleries
CREATE POLICY "Public can view public galleries"
  ON galleries_enhanced FOR SELECT TO public
  USING (password_hash IS NULL AND (expires_at IS NULL OR expires_at > now()));

-- Create admin policies for gallery_images_enhanced
CREATE POLICY "Admin users can manage gallery images"
  ON gallery_images_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Visitors can view images from galleries they have access to
CREATE POLICY "Visitors can view gallery images"
  ON gallery_images_enhanced FOR SELECT TO public
  USING (EXISTS (
    SELECT 1 FROM galleries_enhanced g
    WHERE g.id = gallery_id 
    AND (g.password_hash IS NULL OR EXISTS (
      SELECT 1 FROM gallery_visitors_enhanced gv
      WHERE gv.gallery_id = g.id
    ))
    AND (g.expires_at IS NULL OR g.expires_at > now())
  ));

-- Create policies for other tables
CREATE POLICY "Admin users can manage gallery visitors"
  ON gallery_visitors_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

CREATE POLICY "Admin users can manage image actions"
  ON image_actions_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

CREATE POLICY "Public can insert image actions"
  ON image_actions_enhanced FOR INSERT TO public
  WITH CHECK (true);

CREATE POLICY "Admin users can manage gallery stats"
  ON gallery_daily_stats_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

CREATE POLICY "Admin users can manage collections"
  ON gallery_collections_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

CREATE POLICY "Public can view public collections"
  ON gallery_collections_enhanced FOR SELECT TO public
  USING (is_public = true);

CREATE POLICY "Admin users can manage collection items"
  ON gallery_collection_items_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create trigger functions for enhanced galleries

-- Function to generate unique gallery slug
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
  base_slug := lower(regexp_replace(title_input, '[^a-zA-Z0-9\s]', '', 'g'));
  base_slug := regexp_replace(base_slug, '\s+', '-', 'g');
  base_slug := trim(base_slug, '-');
  
  final_slug := base_slug;
  
  LOOP
    SELECT EXISTS (
      SELECT 1 FROM galleries_enhanced WHERE slug = final_slug
    ) INTO slug_exists;
    
    EXIT WHEN NOT slug_exists;
    
    counter := counter + 1;
    final_slug := base_slug || '-' || counter::text;
  END LOOP;
  
  RETURN final_slug;
END;
$$;

-- Gallery trigger function
CREATE OR REPLACE FUNCTION galleries_enhanced_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := generate_unique_gallery_slug(NEW.title);
  END IF;
  
  NEW.updated_at := now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for galleries
DROP TRIGGER IF EXISTS galleries_enhanced_trigger ON galleries_enhanced;
CREATE TRIGGER galleries_enhanced_trigger
BEFORE INSERT OR UPDATE ON galleries_enhanced
FOR EACH ROW
EXECUTE FUNCTION galleries_enhanced_trigger_function();

-- Function to update image statistics
CREATE OR REPLACE FUNCTION update_image_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update image counters based on action
  IF NEW.action = 'VIEW' THEN
    UPDATE gallery_images_enhanced 
    SET view_count = view_count + 1
    WHERE id = NEW.image_id;
  ELSIF NEW.action = 'FAVORITE' THEN
    UPDATE gallery_images_enhanced 
    SET favorite_count = favorite_count + 1
    WHERE id = NEW.image_id;
  ELSIF NEW.action = 'UNFAVORITE' THEN
    UPDATE gallery_images_enhanced 
    SET favorite_count = GREATEST(favorite_count - 1, 0)
    WHERE id = NEW.image_id;
  ELSIF NEW.action = 'DOWNLOAD' THEN
    UPDATE gallery_images_enhanced 
    SET download_count = download_count + 1
    WHERE id = NEW.image_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for image actions
DROP TRIGGER IF EXISTS image_actions_stats_trigger ON image_actions_enhanced;
CREATE TRIGGER image_actions_stats_trigger
AFTER INSERT ON image_actions_enhanced
FOR EACH ROW
EXECUTE FUNCTION update_image_stats();

-- Function to track gallery access
CREATE OR REPLACE FUNCTION track_gallery_access(
  p_gallery_id uuid,
  p_visitor_email text DEFAULT NULL,
  p_visitor_name text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_visitor_id uuid;
BEGIN
  -- If email provided, update or create visitor record
  IF p_visitor_email IS NOT NULL THEN
    INSERT INTO gallery_visitors_enhanced (gallery_id, email, name, last_access, total_visits)
    VALUES (p_gallery_id, p_visitor_email, p_visitor_name, now(), 1)
    ON CONFLICT (gallery_id, email) 
    DO UPDATE SET 
      last_access = now(),
      total_visits = gallery_visitors_enhanced.total_visits + 1,
      name = COALESCE(EXCLUDED.name, gallery_visitors_enhanced.name)
    RETURNING id INTO v_visitor_id;
  END IF;
  
  RETURN v_visitor_id;
END;
$$;

-- Function to record image action
CREATE OR REPLACE FUNCTION record_image_action(
  p_gallery_id uuid,
  p_image_id uuid,
  p_action text,
  p_visitor_id uuid DEFAULT NULL,
  p_ip_address inet DEFAULT NULL,
  p_user_agent text DEFAULT NULL,
  p_session_id text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO image_actions_enhanced (
    visitor_id, gallery_id, image_id, action, 
    ip_address, user_agent, session_id
  )
  VALUES (
    p_visitor_id, p_gallery_id, p_image_id, p_action,
    p_ip_address, p_user_agent, p_session_id
  );
END;
$$;

-- Create view for gallery analytics
CREATE OR REPLACE VIEW gallery_analytics_enhanced AS
SELECT 
  g.id,
  g.title,
  g.slug,
  g.created_at,
  COUNT(DISTINCT gv.id) as total_visitors,
  COUNT(DISTINCT ia.visitor_id) as unique_visitors_with_actions,
  COUNT(gi.id) as total_images,
  COALESCE(SUM(gi.view_count), 0) as total_views,
  COALESCE(SUM(gi.favorite_count), 0) as total_favorites,
  COALESCE(SUM(gi.download_count), 0) as total_downloads,
  MAX(gv.last_access) as last_visitor_access
FROM galleries_enhanced g
LEFT JOIN gallery_visitors_enhanced gv ON g.id = gv.gallery_id
LEFT JOIN gallery_images_enhanced gi ON g.id = gi.gallery_id
LEFT JOIN image_actions_enhanced ia ON g.id = ia.gallery_id
GROUP BY g.id, g.title, g.slug, g.created_at;
