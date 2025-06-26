/*
  # Upgrade Existing Galleries to Professional Features
  
  This migration enhances your existing galleries and photos tables with advanced features
  without losing any existing data:
  
  1. Enhanced Gallery Features:
    - Password protection for private galleries
    - Slug-based URLs for SEO
    - Cover images and better organization
    - Download management and watermarking
    - Client-specific galleries with email integration
    - Featured galleries and sorting
    
  2. Enhanced Photo Management:
    - Multiple image sizes (original, display, thumbnail)
    - EXIF data storage
    - View/download tracking
    - Better metadata and ordering
    
  3. Analytics & Visitor Management:
    - Gallery visitor tracking
    - Image interaction analytics
    - Download statistics
    - Access control with tokens
*/

-- Add enhanced columns to existing galleries table
DO $$
BEGIN
  -- Add slug column for SEO-friendly URLs
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'slug') THEN
    ALTER TABLE galleries ADD COLUMN slug text;
    -- Generate slugs for existing galleries
    UPDATE galleries SET slug = lower(regexp_replace(regexp_replace(title, '[^a-zA-Z0-9\s]', '', 'g'), '\s+', '-', 'g')) WHERE slug IS NULL;
    -- Make slug unique and not null
    CREATE UNIQUE INDEX CONCURRENTLY idx_galleries_slug_unique ON galleries(slug);
    ALTER TABLE galleries ALTER COLUMN slug SET NOT NULL;
  END IF;

  -- Add cover image
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'cover_image') THEN
    ALTER TABLE galleries ADD COLUMN cover_image text;
  END IF;

  -- Add password protection
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'password_hash') THEN
    ALTER TABLE galleries ADD COLUMN password_hash text; -- null means public gallery
  END IF;

  -- Add download management
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'download_enabled') THEN
    ALTER TABLE galleries ADD COLUMN download_enabled boolean DEFAULT true;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'watermark_enabled') THEN
    ALTER TABLE galleries ADD COLUMN watermark_enabled boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'max_downloads_per_visitor') THEN
    ALTER TABLE galleries ADD COLUMN max_downloads_per_visitor integer DEFAULT null; -- null means unlimited
  END IF;

  -- Add client email for better client management
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'client_email') THEN
    ALTER TABLE galleries ADD COLUMN client_email text;
  END IF;

  -- Add featured and sorting
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'is_featured') THEN
    ALTER TABLE galleries ADD COLUMN is_featured boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'sort_order') THEN
    ALTER TABLE galleries ADD COLUMN sort_order integer DEFAULT 0;
  END IF;

  -- Add updated_at timestamp
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'updated_at') THEN
    ALTER TABLE galleries ADD COLUMN updated_at timestamptz DEFAULT now();
  END IF;

  -- Rename client_id to created_by for consistency
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'client_id') 
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'created_by') THEN
    ALTER TABLE galleries RENAME COLUMN client_id TO created_by;
  ELSIF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'galleries' AND column_name = 'created_by') THEN
    ALTER TABLE galleries ADD COLUMN created_by uuid REFERENCES auth.users(id) NOT NULL DEFAULT auth.uid();
  END IF;

END $$;

-- Enhance existing photos table
DO $$
BEGIN
  -- Add multiple image size URLs
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'original_url') THEN
    -- Rename existing url to original_url
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'url') THEN
      ALTER TABLE photos RENAME COLUMN url TO original_url;
    ELSE
      ALTER TABLE photos ADD COLUMN original_url text NOT NULL DEFAULT '';
    END IF;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'display_url') THEN
    ALTER TABLE photos ADD COLUMN display_url text; -- 1920px long edge
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'thumb_url') THEN
    ALTER TABLE photos ADD COLUMN thumb_url text; -- 400px long edge
  END IF;

  -- Add filename and metadata
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'filename') THEN
    ALTER TABLE photos ADD COLUMN filename text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'alt_text') THEN
    ALTER TABLE photos ADD COLUMN alt_text text;
  END IF;

  -- Add file information
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'size_bytes') THEN
    ALTER TABLE photos ADD COLUMN size_bytes bigint DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'width') THEN
    ALTER TABLE photos ADD COLUMN width integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'height') THEN
    ALTER TABLE photos ADD COLUMN height integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'content_type') THEN
    ALTER TABLE photos ADD COLUMN content_type text DEFAULT 'image/jpeg';
  END IF;

  -- Add EXIF data fields
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'camera_make') THEN
    ALTER TABLE photos ADD COLUMN camera_make text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'camera_model') THEN
    ALTER TABLE photos ADD COLUMN camera_model text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'lens_model') THEN
    ALTER TABLE photos ADD COLUMN lens_model text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'focal_length') THEN
    ALTER TABLE photos ADD COLUMN focal_length text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'aperture') THEN
    ALTER TABLE photos ADD COLUMN aperture text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'shutter_speed') THEN
    ALTER TABLE photos ADD COLUMN shutter_speed text;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'iso') THEN
    ALTER TABLE photos ADD COLUMN iso integer;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'captured_at') THEN
    ALTER TABLE photos ADD COLUMN captured_at timestamptz;
  END IF;

  -- Add ordering and features
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'order_index') THEN
    ALTER TABLE photos ADD COLUMN order_index integer DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'is_featured') THEN
    ALTER TABLE photos ADD COLUMN is_featured boolean DEFAULT false;
  END IF;

  -- Add analytics counters
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'download_count') THEN
    ALTER TABLE photos ADD COLUMN download_count integer DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'view_count') THEN
    ALTER TABLE photos ADD COLUMN view_count integer DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'favorite_count') THEN
    ALTER TABLE photos ADD COLUMN favorite_count integer DEFAULT 0;
  END IF;

END $$;

-- Create new tables for enhanced functionality

-- Gallery Visitors Table
CREATE TABLE IF NOT EXISTS gallery_visitors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries(id) ON DELETE CASCADE NOT NULL,
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
CREATE TABLE IF NOT EXISTS image_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_id uuid REFERENCES gallery_visitors(id) ON DELETE CASCADE,
  gallery_id uuid REFERENCES galleries(id) ON DELETE CASCADE NOT NULL,
  photo_id uuid REFERENCES photos(id) ON DELETE CASCADE NOT NULL,
  action text NOT NULL CHECK (action IN ('VIEW', 'FAVORITE', 'UNFAVORITE', 'DOWNLOAD', 'SHARE')),
  ip_address inet,
  user_agent text,
  session_id text,
  created_at timestamptz DEFAULT now()
);

-- Gallery Daily Stats Table
CREATE TABLE IF NOT EXISTS gallery_daily_stats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries(id) ON DELETE CASCADE NOT NULL,
  date date NOT NULL,
  unique_visitors integer DEFAULT 0,
  total_visits integer DEFAULT 0,
  total_views integer DEFAULT 0,
  total_favorites integer DEFAULT 0,
  total_downloads integer DEFAULT 0,
  average_session_duration interval DEFAULT '0 minutes',
  top_photo_id uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(gallery_id, date)
);

-- Gallery Collections Table
CREATE TABLE IF NOT EXISTS gallery_collections (
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
CREATE TABLE IF NOT EXISTS gallery_collection_items (
  collection_id uuid REFERENCES gallery_collections(id) ON DELETE CASCADE,
  gallery_id uuid REFERENCES galleries(id) ON DELETE CASCADE,
  sort_order integer DEFAULT 0,
  added_at timestamptz DEFAULT now(),
  PRIMARY KEY (collection_id, gallery_id)
);

-- Enable RLS on new tables
ALTER TABLE gallery_visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE image_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE gallery_collection_items ENABLE ROW LEVEL SECURITY;

-- Create enhanced indexes
CREATE INDEX IF NOT EXISTS idx_galleries_created_by ON galleries(created_by);
CREATE INDEX IF NOT EXISTS idx_galleries_client_email ON galleries(client_email);
CREATE INDEX IF NOT EXISTS idx_galleries_featured ON galleries(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_galleries_sort_order ON galleries(sort_order);

CREATE INDEX IF NOT EXISTS idx_photos_gallery_order ON photos(gallery_id, order_index);
CREATE INDEX IF NOT EXISTS idx_photos_featured ON photos(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_photos_filename ON photos(filename);

CREATE INDEX IF NOT EXISTS idx_gallery_visitors_gallery_id ON gallery_visitors(gallery_id);
CREATE INDEX IF NOT EXISTS idx_gallery_visitors_email ON gallery_visitors(email);
CREATE INDEX IF NOT EXISTS idx_gallery_visitors_access_token ON gallery_visitors(access_token);

CREATE INDEX IF NOT EXISTS idx_image_actions_visitor_id ON image_actions(visitor_id);
CREATE INDEX IF NOT EXISTS idx_image_actions_gallery_id ON image_actions(gallery_id);
CREATE INDEX IF NOT EXISTS idx_image_actions_photo_id ON image_actions(photo_id);
CREATE INDEX IF NOT EXISTS idx_image_actions_action ON image_actions(action);
CREATE INDEX IF NOT EXISTS idx_image_actions_created_at ON image_actions(created_at);

-- Update existing policies
DROP POLICY IF EXISTS "Users can view own galleries" ON galleries;
DROP POLICY IF EXISTS "Users can view photos from their galleries" ON photos;

-- Create enhanced policies for galleries
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

-- Public can view public galleries
CREATE POLICY "Public can view public galleries"
  ON galleries FOR SELECT TO public
  USING (password_hash IS NULL AND (expires_at IS NULL OR expires_at > now()));

-- Gallery owners can view their galleries
CREATE POLICY "Gallery owners can view their galleries"
  ON galleries FOR SELECT TO authenticated
  USING (created_by = auth.uid());

-- Create enhanced policies for photos
CREATE POLICY "Admin users can manage photos"
  ON photos FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Visitors can view photos from accessible galleries
CREATE POLICY "Visitors can view gallery photos"
  ON photos FOR SELECT TO public
  USING (EXISTS (
    SELECT 1 FROM galleries g
    WHERE g.id = gallery_id 
    AND (g.password_hash IS NULL OR EXISTS (
      SELECT 1 FROM gallery_visitors gv
      WHERE gv.gallery_id = g.id
    ))
    AND (g.expires_at IS NULL OR g.expires_at > now())
  ));

-- Photo owners can view their photos
CREATE POLICY "Photo owners can view their photos"
  ON photos FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM galleries g
    WHERE g.id = gallery_id AND g.created_by = auth.uid()
  ));

-- Create policies for new tables
CREATE POLICY "Admin users can manage gallery visitors"
  ON gallery_visitors FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

CREATE POLICY "Admin users can manage image actions"
  ON image_actions FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

CREATE POLICY "Public can insert image actions"
  ON image_actions FOR INSERT TO public
  WITH CHECK (true);

CREATE POLICY "Admin users can manage gallery stats"
  ON gallery_daily_stats FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

CREATE POLICY "Admin users can manage collections"
  ON gallery_collections FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

CREATE POLICY "Public can view public collections"
  ON gallery_collections FOR SELECT TO public
  USING (is_public = true);

-- Create enhanced functions

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
  base_slug := lower(regexp_replace(regexp_replace(title_input, '[^a-zA-Z0-9\s]', '', 'g'), '\s+', '-', 'g'));
  base_slug := trim(base_slug, '-');
  
  IF base_slug = '' THEN
    base_slug := 'gallery';
  END IF;
  
  final_slug := base_slug;
  
  LOOP
    SELECT EXISTS (
      SELECT 1 FROM galleries WHERE slug = final_slug
    ) INTO slug_exists;
    
    EXIT WHEN NOT slug_exists;
    
    counter := counter + 1;
    final_slug := base_slug || '-' || counter::text;
  END LOOP;
  
  RETURN final_slug;
END;
$$;

-- Gallery trigger function
CREATE OR REPLACE FUNCTION galleries_trigger_function()
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
DROP TRIGGER IF EXISTS galleries_trigger ON galleries;
CREATE TRIGGER galleries_trigger
BEFORE INSERT OR UPDATE ON galleries
FOR EACH ROW
EXECUTE FUNCTION galleries_trigger_function();

-- Function to update photo statistics
CREATE OR REPLACE FUNCTION update_photo_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update photo counters based on action
  IF NEW.action = 'VIEW' THEN
    UPDATE photos 
    SET view_count = view_count + 1
    WHERE id = NEW.photo_id;
  ELSIF NEW.action = 'FAVORITE' THEN
    UPDATE photos 
    SET favorite_count = favorite_count + 1
    WHERE id = NEW.photo_id;
  ELSIF NEW.action = 'UNFAVORITE' THEN
    UPDATE photos 
    SET favorite_count = GREATEST(favorite_count - 1, 0)
    WHERE id = NEW.photo_id;
  ELSIF NEW.action = 'DOWNLOAD' THEN
    UPDATE photos 
    SET download_count = download_count + 1
    WHERE id = NEW.photo_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for image actions
DROP TRIGGER IF EXISTS image_actions_stats_trigger ON image_actions;
CREATE TRIGGER image_actions_stats_trigger
AFTER INSERT ON image_actions
FOR EACH ROW
EXECUTE FUNCTION update_photo_stats();

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
  IF p_visitor_email IS NOT NULL THEN
    INSERT INTO gallery_visitors (gallery_id, email, name, last_access, total_visits)
    VALUES (p_gallery_id, p_visitor_email, p_visitor_name, now(), 1)
    ON CONFLICT (gallery_id, email) 
    DO UPDATE SET 
      last_access = now(),
      total_visits = gallery_visitors.total_visits + 1,
      name = COALESCE(EXCLUDED.name, gallery_visitors.name)
    RETURNING id INTO v_visitor_id;
  END IF;
  
  RETURN v_visitor_id;
END;
$$;

-- Function to record image action
CREATE OR REPLACE FUNCTION record_image_action(
  p_gallery_id uuid,
  p_photo_id uuid,
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
  INSERT INTO image_actions (
    visitor_id, gallery_id, photo_id, action, 
    ip_address, user_agent, session_id
  )
  VALUES (
    p_visitor_id, p_gallery_id, p_photo_id, p_action,
    p_ip_address, p_user_agent, p_session_id
  );
END;
$$;

-- Create enhanced views
CREATE OR REPLACE VIEW gallery_analytics AS
SELECT 
  g.id,
  g.title,
  g.slug,
  g.created_at,
  COUNT(DISTINCT gv.id) as total_visitors,
  COUNT(DISTINCT ia.visitor_id) as unique_visitors_with_actions,
  COUNT(p.id) as total_photos,
  COALESCE(SUM(p.view_count), 0) as total_views,
  COALESCE(SUM(p.favorite_count), 0) as total_favorites,
  COALESCE(SUM(p.download_count), 0) as total_downloads,
  MAX(gv.last_access) as last_visitor_access
FROM galleries g
LEFT JOIN gallery_visitors gv ON g.id = gv.gallery_id
LEFT JOIN photos p ON g.id = p.gallery_id
LEFT JOIN image_actions ia ON g.id = ia.gallery_id
GROUP BY g.id, g.title, g.slug, g.created_at;

-- Generate slugs for existing galleries that don't have them
UPDATE galleries SET slug = generate_unique_gallery_slug(title) WHERE slug IS NULL OR slug = '';

-- Update display_url and thumb_url for existing photos that don't have them
UPDATE photos 
SET 
  display_url = original_url,
  thumb_url = original_url
WHERE display_url IS NULL OR thumb_url IS NULL;

-- Set default filenames for existing photos
UPDATE photos 
SET filename = 'photo-' || id::text || '.jpg'
WHERE filename IS NULL OR filename = '';
