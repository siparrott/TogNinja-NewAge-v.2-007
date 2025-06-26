/*
  # Enhanced Blog Module - WordPress-Style Features
  
  This migration restores advanced blog features that were developed but lost:
  
  1. Enhanced Blog Schema:
    - Rich content support with HTML
    - SEO optimization (meta titles, descriptions)
    - Post scheduling functionality
    - Tag system for categorization
    - Slug auto-generation
    - Cover image support
    
  2. WordPress-Style Features:
    - Draft/Published/Scheduled status
    - Author management
    - Tag management with many-to-many relationships
    - SEO-friendly URLs with slugs
    - Published date handling
    
  3. Security:
    - Admin-only write access
    - Public read access for published posts
    - Proper RLS policies
*/

-- Create enum for blog post status if it doesn't exist
DO $$ BEGIN
  CREATE TYPE blog_post_status AS ENUM ('DRAFT', 'PUBLISHED', 'SCHEDULED');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Enhanced Blog Posts Table
CREATE TABLE IF NOT EXISTS blog_posts_enhanced (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  excerpt text,
  content_html text NOT NULL,
  cover_image text,
  status blog_post_status DEFAULT 'DRAFT',
  seo_title text,
  meta_description text,
  author_id uuid REFERENCES auth.users(id) NOT NULL,
  published_at timestamptz,
  scheduled_for timestamptz,
  view_count integer DEFAULT 0,
  featured boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Blog Tags Table
CREATE TABLE IF NOT EXISTS blog_tags_enhanced (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  slug text NOT NULL UNIQUE,
  description text,
  color text DEFAULT '#3B82F6', -- Tailwind blue-500
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Blog Post Tags Junction Table
CREATE TABLE IF NOT EXISTS blog_post_tags_enhanced (
  post_id uuid REFERENCES blog_posts_enhanced(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES blog_tags_enhanced(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)
);

-- Blog Comments Table (WordPress-style commenting)
CREATE TABLE IF NOT EXISTS blog_comments_enhanced (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES blog_posts_enhanced(id) ON DELETE CASCADE,
  author_name text NOT NULL,
  author_email text NOT NULL,
  content text NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'spam', 'trash')),
  parent_id uuid REFERENCES blog_comments_enhanced(id),
  created_at timestamptz DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_blog_posts_enhanced_status ON blog_posts_enhanced(status);
CREATE INDEX IF NOT EXISTS idx_blog_posts_enhanced_author ON blog_posts_enhanced(author_id);
CREATE INDEX IF NOT EXISTS idx_blog_posts_enhanced_published_at ON blog_posts_enhanced(published_at);
CREATE INDEX IF NOT EXISTS idx_blog_posts_enhanced_slug ON blog_posts_enhanced(slug);
CREATE INDEX IF NOT EXISTS idx_blog_posts_enhanced_featured ON blog_posts_enhanced(featured) WHERE featured = true;
CREATE INDEX IF NOT EXISTS idx_blog_comments_enhanced_post ON blog_comments_enhanced(post_id);
CREATE INDEX IF NOT EXISTS idx_blog_comments_enhanced_status ON blog_comments_enhanced(status);

-- Enable RLS on all tables
ALTER TABLE blog_posts_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_tags_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_post_tags_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_comments_enhanced ENABLE ROW LEVEL SECURITY;

-- Create policies for blog_posts_enhanced
CREATE POLICY "Public can read published blog posts"
  ON blog_posts_enhanced FOR SELECT TO public
  USING (status = 'PUBLISHED' AND (published_at IS NULL OR published_at <= now()));

CREATE POLICY "Admin users can manage blog posts"
  ON blog_posts_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create policies for blog_tags_enhanced
CREATE POLICY "Public can read blog tags"
  ON blog_tags_enhanced FOR SELECT TO public
  USING (true);

CREATE POLICY "Admin users can manage blog tags"
  ON blog_tags_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create policies for blog_post_tags_enhanced
CREATE POLICY "Public can read blog post tags"
  ON blog_post_tags_enhanced FOR SELECT TO public
  USING (EXISTS (
    SELECT 1 FROM blog_posts_enhanced
    WHERE blog_posts_enhanced.id = post_id
    AND blog_posts_enhanced.status = 'PUBLISHED'
    AND (blog_posts_enhanced.published_at IS NULL OR blog_posts_enhanced.published_at <= now())
  ));

CREATE POLICY "Admin users can manage blog post tags"
  ON blog_post_tags_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create policies for blog_comments_enhanced
CREATE POLICY "Public can read approved comments"
  ON blog_comments_enhanced FOR SELECT TO public
  USING (status = 'approved');

CREATE POLICY "Public can insert comments"
  ON blog_comments_enhanced FOR INSERT TO public
  WITH CHECK (status = 'pending');

CREATE POLICY "Admin users can manage comments"
  ON blog_comments_enhanced FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create function to generate unique slug from title
CREATE OR REPLACE FUNCTION generate_unique_blog_slug(title_input text, table_name text DEFAULT 'blog_posts_enhanced')
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
  -- Convert title to lowercase and replace spaces with hyphens
  base_slug := lower(regexp_replace(title_input, '[^a-zA-Z0-9\s]', '', 'g'));
  base_slug := regexp_replace(base_slug, '\s+', '-', 'g');
  base_slug := trim(base_slug, '-');
  
  -- Initial slug
  final_slug := base_slug;
  
  -- Check if slug exists
  LOOP
    query_text := format('SELECT EXISTS (SELECT 1 FROM %I WHERE slug = $1)', table_name);
    EXECUTE query_text USING final_slug INTO slug_exists;
    
    EXIT WHEN NOT slug_exists;
    
    -- Increment counter and append to slug
    counter := counter + 1;
    final_slug := base_slug || '-' || counter::text;
  END LOOP;
  
  RETURN final_slug;
END;
$$;

-- Create function to update blog post timestamps and slugs
CREATE OR REPLACE FUNCTION blog_posts_enhanced_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate slug if not provided or empty
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := generate_unique_blog_slug(NEW.title);
  END IF;
  
  -- Set updated_at timestamp
  NEW.updated_at := now();
  
  -- Handle published_at timestamp
  IF NEW.status = 'PUBLISHED' AND OLD.status != 'PUBLISHED' AND NEW.published_at IS NULL THEN
    NEW.published_at := now();
  END IF;
  
  -- Handle scheduled posts
  IF NEW.status = 'SCHEDULED' AND NEW.scheduled_for IS NOT NULL AND NEW.scheduled_for <= now() THEN
    NEW.status := 'PUBLISHED';
    NEW.published_at := now();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for blog posts
DROP TRIGGER IF EXISTS blog_posts_enhanced_trigger ON blog_posts_enhanced;
CREATE TRIGGER blog_posts_enhanced_trigger
BEFORE INSERT OR UPDATE ON blog_posts_enhanced
FOR EACH ROW
EXECUTE FUNCTION blog_posts_enhanced_trigger_function();

-- Create function to update tag slugs
CREATE OR REPLACE FUNCTION blog_tags_enhanced_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate slug if not provided
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := generate_unique_blog_slug(NEW.name, 'blog_tags_enhanced');
  END IF;
  
  NEW.updated_at := now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for blog tags
DROP TRIGGER IF EXISTS blog_tags_enhanced_trigger ON blog_tags_enhanced;
CREATE TRIGGER blog_tags_enhanced_trigger
BEFORE INSERT OR UPDATE ON blog_tags_enhanced
FOR EACH ROW
EXECUTE FUNCTION blog_tags_enhanced_trigger_function();

-- Insert enhanced sample tags
INSERT INTO blog_tags_enhanced (name, slug, description, color) VALUES
('Photography Tips', 'photography-tips', 'Professional photography advice and techniques', '#3B82F6'),
('Family Photography', 'family-photography', 'Family portrait sessions and tips', '#10B981'),
('Wedding Photography', 'wedding-photography', 'Wedding day photography insights', '#F59E0B'),
('Newborn Photography', 'newborn-photography', 'Newborn and baby photography', '#EC4899'),
('Business Photography', 'business-photography', 'Corporate and business portraits', '#6366F1'),
('Behind the Scenes', 'behind-the-scenes', 'Behind the camera insights', '#8B5CF6'),
('Photography Gear', 'photography-gear', 'Camera equipment and gear reviews', '#EF4444'),
('Editing Tips', 'editing-tips', 'Photo editing and post-processing', '#06B6D4'),
('Client Stories', 'client-stories', 'Client testimonials and success stories', '#84CC16'),
('Studio Updates', 'studio-updates', 'News and updates from our studio', '#F97316')
ON CONFLICT (slug) DO NOTHING;

-- Create view for published posts with tag information
CREATE OR REPLACE VIEW published_blog_posts_with_tags AS
SELECT 
  p.*,
  COALESCE(
    json_agg(
      json_build_object(
        'id', t.id,
        'name', t.name,
        'slug', t.slug,
        'color', t.color
      )
    ) FILTER (WHERE t.id IS NOT NULL),
    '[]'::json
  ) as tags
FROM blog_posts_enhanced p
LEFT JOIN blog_post_tags_enhanced pt ON p.id = pt.post_id
LEFT JOIN blog_tags_enhanced t ON pt.tag_id = t.id
WHERE p.status = 'PUBLISHED' 
  AND (p.published_at IS NULL OR p.published_at <= now())
GROUP BY p.id, p.title, p.slug, p.excerpt, p.content_html, p.cover_image, 
         p.status, p.seo_title, p.meta_description, p.author_id, p.published_at, 
         p.scheduled_for, p.view_count, p.featured, p.created_at, p.updated_at;

-- Function to increment view count
CREATE OR REPLACE FUNCTION increment_blog_post_views(post_slug text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE blog_posts_enhanced 
  SET view_count = view_count + 1,
      updated_at = now()
  WHERE slug = post_slug AND status = 'PUBLISHED';
END;
$$;
