/*
  # Upgrade Existing Blog to WordPress-Style Features
  
  This migration enhances your existing blog_posts table with advanced features
  without losing any existing data:
  
  1. Enhanced Blog Features:
    - Better status management (DRAFT/PUBLISHED/SCHEDULED)
    - SEO optimization fields
    - View counter and analytics
    - Featured posts
    - Scheduling functionality
    
  2. New Tables:
    - blog_tags for categorization
    - blog_post_tags for many-to-many relationships
    - blog_comments for WordPress-style commenting
    
  3. Advanced Functions:
    - Auto-slug generation
    - View tracking
    - Published date management
*/

-- First, create the enhanced status enum
DO $$ BEGIN
  CREATE TYPE blog_post_status AS ENUM ('DRAFT', 'PUBLISHED', 'SCHEDULED');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Add new columns to existing blog_posts table
DO $$
BEGIN
  -- Add status column (convert existing published boolean)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'status') THEN
    ALTER TABLE blog_posts ADD COLUMN status blog_post_status;
    -- Convert existing published boolean to status enum
    UPDATE blog_posts SET status = CASE WHEN published THEN 'PUBLISHED'::blog_post_status ELSE 'DRAFT'::blog_post_status END;
    ALTER TABLE blog_posts ALTER COLUMN status SET DEFAULT 'DRAFT';
    ALTER TABLE blog_posts ALTER COLUMN status SET NOT NULL;
  END IF;

  -- Add content_html column (rename existing content if needed)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'content_html') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'content') THEN
      ALTER TABLE blog_posts RENAME COLUMN content TO content_html;
    ELSE
      ALTER TABLE blog_posts ADD COLUMN content_html text NOT NULL DEFAULT '';
    END IF;
  END IF;

  -- Add SEO fields
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'seo_title') THEN
    ALTER TABLE blog_posts ADD COLUMN seo_title text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'meta_description') THEN
    ALTER TABLE blog_posts ADD COLUMN meta_description text;
  END IF;

  -- Add scheduling and analytics fields
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'scheduled_for') THEN
    ALTER TABLE blog_posts ADD COLUMN scheduled_for timestamptz;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'view_count') THEN
    ALTER TABLE blog_posts ADD COLUMN view_count integer DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'featured') THEN
    ALTER TABLE blog_posts ADD COLUMN featured boolean DEFAULT false;
  END IF;

  -- Rename image_url to cover_image for consistency
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'image_url') 
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'cover_image') THEN
    ALTER TABLE blog_posts RENAME COLUMN image_url TO cover_image;
  ELSIF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'blog_posts' AND column_name = 'cover_image') THEN
    ALTER TABLE blog_posts ADD COLUMN cover_image text;
  END IF;

END $$;

-- Create Blog Tags Table
CREATE TABLE IF NOT EXISTS blog_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  slug text NOT NULL UNIQUE,
  description text,
  color text DEFAULT '#3B82F6',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create Blog Post Tags Junction Table
CREATE TABLE IF NOT EXISTS blog_post_tags (
  post_id uuid REFERENCES blog_posts(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES blog_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)
);

-- Create Blog Comments Table
CREATE TABLE IF NOT EXISTS blog_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES blog_posts(id) ON DELETE CASCADE,
  author_name text NOT NULL,
  author_email text NOT NULL,
  author_website text,
  content text NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'spam', 'trash')),
  parent_id uuid REFERENCES blog_comments(id),
  ip_address inet,
  user_agent text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on new tables
ALTER TABLE blog_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_post_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_comments ENABLE ROW LEVEL SECURITY;

-- Create improved indexes
CREATE INDEX IF NOT EXISTS idx_blog_posts_status ON blog_posts(status);
CREATE INDEX IF NOT EXISTS idx_blog_posts_featured ON blog_posts(featured) WHERE featured = true;
CREATE INDEX IF NOT EXISTS idx_blog_posts_scheduled ON blog_posts(scheduled_for) WHERE status = 'SCHEDULED';
CREATE INDEX IF NOT EXISTS idx_blog_posts_view_count ON blog_posts(view_count DESC);

CREATE INDEX IF NOT EXISTS idx_blog_tags_slug ON blog_tags(slug);
CREATE INDEX IF NOT EXISTS idx_blog_post_tags_post ON blog_post_tags(post_id);
CREATE INDEX IF NOT EXISTS idx_blog_post_tags_tag ON blog_post_tags(tag_id);

CREATE INDEX IF NOT EXISTS idx_blog_comments_post ON blog_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_blog_comments_status ON blog_comments(status);
CREATE INDEX IF NOT EXISTS idx_blog_comments_parent ON blog_comments(parent_id);

-- Update existing policies
DROP POLICY IF EXISTS "Public can read published posts" ON blog_posts;
DROP POLICY IF EXISTS "Admin users can manage all posts" ON blog_posts;

-- Create enhanced policies for blog_posts
CREATE POLICY "Public can read published blog posts"
  ON blog_posts FOR SELECT TO public
  USING (status = 'PUBLISHED' AND (published_at IS NULL OR published_at <= now()));

CREATE POLICY "Admin users can manage blog posts"
  ON blog_posts FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create policies for blog_tags
CREATE POLICY "Public can read blog tags"
  ON blog_tags FOR SELECT TO public
  USING (true);

CREATE POLICY "Admin users can manage blog tags"
  ON blog_tags FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create policies for blog_post_tags
CREATE POLICY "Public can read blog post tags"
  ON blog_post_tags FOR SELECT TO public
  USING (EXISTS (
    SELECT 1 FROM blog_posts
    WHERE blog_posts.id = post_id
    AND blog_posts.status = 'PUBLISHED'
    AND (blog_posts.published_at IS NULL OR blog_posts.published_at <= now())
  ));

CREATE POLICY "Admin users can manage blog post tags"
  ON blog_post_tags FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create policies for blog_comments
CREATE POLICY "Public can read approved comments"
  ON blog_comments FOR SELECT TO public
  USING (status = 'approved');

CREATE POLICY "Public can insert comments"
  ON blog_comments FOR INSERT TO public
  WITH CHECK (status = 'pending');

CREATE POLICY "Admin users can manage comments"
  ON blog_comments FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Enhanced slug generation function
CREATE OR REPLACE FUNCTION generate_unique_slug(title_input text, table_name text DEFAULT 'blog_posts')
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  base_slug text;
  final_slug text;
  counter integer := 0;
  slug_exists boolean;
  query_text text;
BEGIN
  -- Convert title to URL-friendly slug
  base_slug := lower(regexp_replace(title_input, '[^a-zA-Z0-9\s]', '', 'g'));
  base_slug := regexp_replace(base_slug, '\s+', '-', 'g');
  base_slug := trim(base_slug, '-');
  
  -- Ensure slug isn't empty
  IF base_slug = '' THEN
    base_slug := 'untitled';
  END IF;
  
  final_slug := base_slug;
  
  -- Check for uniqueness
  LOOP
    query_text := format('SELECT EXISTS (SELECT 1 FROM %I WHERE slug = $1)', table_name);
    EXECUTE query_text USING final_slug INTO slug_exists;
    
    EXIT WHEN NOT slug_exists;
    
    counter := counter + 1;
    final_slug := base_slug || '-' || counter::text;
  END LOOP;
  
  RETURN final_slug;
END;
$$;

-- Enhanced blog posts trigger function
CREATE OR REPLACE FUNCTION blog_posts_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate slug if not provided
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := generate_unique_slug(NEW.title, 'blog_posts');
  END IF;
  
  -- Set updated_at
  NEW.updated_at := now();
  
  -- Handle status transitions
  IF NEW.status = 'PUBLISHED' AND (OLD.status IS NULL OR OLD.status != 'PUBLISHED') AND NEW.published_at IS NULL THEN
    NEW.published_at := now();
  END IF;
  
  -- Handle scheduled posts
  IF NEW.status = 'SCHEDULED' AND NEW.scheduled_for IS NOT NULL AND NEW.scheduled_for <= now() THEN
    NEW.status := 'PUBLISHED';
    NEW.published_at := now();
  END IF;
  
  -- Ensure published is kept in sync with status for backward compatibility
  NEW.published := (NEW.status = 'PUBLISHED');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create/update trigger for blog posts
DROP TRIGGER IF EXISTS blog_posts_trigger ON blog_posts;
CREATE TRIGGER blog_posts_trigger
BEFORE INSERT OR UPDATE ON blog_posts
FOR EACH ROW
EXECUTE FUNCTION blog_posts_trigger_function();

-- Blog tags trigger function
CREATE OR REPLACE FUNCTION blog_tags_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := generate_unique_slug(NEW.name, 'blog_tags');
  END IF;
  
  NEW.updated_at := now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for blog tags
DROP TRIGGER IF EXISTS blog_tags_trigger ON blog_tags;
CREATE TRIGGER blog_tags_trigger
BEFORE INSERT OR UPDATE ON blog_tags
FOR EACH ROW
EXECUTE FUNCTION blog_tags_trigger_function();

-- Insert enhanced sample tags
INSERT INTO blog_tags (name, description, color) VALUES
('Photography Tips', 'Professional photography advice and techniques', '#3B82F6'),
('Family Sessions', 'Family portrait photography', '#10B981'),
('Wedding Photography', 'Wedding day photography insights', '#F59E0B'),
('Newborn Photography', 'Newborn and baby photography', '#EC4899'),
('Business Portraits', 'Corporate and business photography', '#6366F1'),
('Behind the Scenes', 'Studio insights and processes', '#8B5CF6'),
('Photo Editing', 'Post-processing tips and techniques', '#06B6D4'),
('Client Stories', 'Featured client experiences', '#84CC16'),
('Equipment Reviews', 'Camera gear and equipment', '#EF4444'),
('Studio News', 'Updates and announcements', '#F97316')
ON CONFLICT (name) DO NOTHING;

-- Function to increment view count
CREATE OR REPLACE FUNCTION increment_post_views(post_slug text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE blog_posts 
  SET view_count = view_count + 1,
      updated_at = now()
  WHERE slug = post_slug AND status = 'PUBLISHED';
END;
$$;

-- Create enhanced view for posts with tags
CREATE OR REPLACE VIEW blog_posts_with_tags AS
SELECT 
  p.*,
  COALESCE(
    json_agg(
      json_build_object(
        'id', t.id,
        'name', t.name,
        'slug', t.slug,
        'color', t.color
      ) ORDER BY t.name
    ) FILTER (WHERE t.id IS NOT NULL),
    '[]'::json
  ) as tags
FROM blog_posts p
LEFT JOIN blog_post_tags pt ON p.id = pt.post_id
LEFT JOIN blog_tags t ON pt.tag_id = t.id
GROUP BY p.id, p.title, p.slug, p.content_html, p.excerpt, p.cover_image, 
         p.status, p.published, p.seo_title, p.meta_description, p.author_id, 
         p.created_at, p.updated_at, p.published_at, p.scheduled_for, 
         p.view_count, p.featured;

-- Update any existing published posts to have the correct status
UPDATE blog_posts 
SET status = 'PUBLISHED', published_at = COALESCE(published_at, created_at)
WHERE published = true AND status IS NULL;

UPDATE blog_posts 
SET status = 'DRAFT'
WHERE (published = false OR published IS NULL) AND status IS NULL;
