-- Create enum for blog post status if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'blog_post_status') THEN
    CREATE TYPE blog_post_status AS ENUM ('DRAFT', 'PUBLISHED', 'SCHEDULED');
  END IF;
END$$;

-- Blog Posts Table
CREATE TABLE IF NOT EXISTS blog_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  excerpt text,
  content_html text NOT NULL,
  cover_image text,
  tags text[],
  status blog_post_status DEFAULT 'DRAFT',
  seo_title text,
  meta_description text,
  author_id uuid REFERENCES auth.users(id) NOT NULL,
  published_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Blog Tags Table
CREATE TABLE IF NOT EXISTS blog_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  slug text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Blog Post Tags Junction Table
CREATE TABLE IF NOT EXISTS blog_post_tags (
  post_id uuid REFERENCES blog_posts(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES blog_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_blog_posts_author ON blog_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_blog_posts_published_at ON blog_posts(published_at);
CREATE INDEX IF NOT EXISTS idx_blog_posts_slug ON blog_posts(slug);

-- Enable RLS on all tables
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_post_tags ENABLE ROW LEVEL SECURITY;

-- Create policies for blog_posts
CREATE POLICY "Public can read published blog posts"
  ON blog_posts FOR SELECT TO public
  USING ((status)::text = 'PUBLISHED' AND (published_at IS NULL OR published_at <= now()));

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
    AND (blog_posts.status)::text = 'PUBLISHED'
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

-- Create function to generate slug from title
CREATE OR REPLACE FUNCTION generate_unique_slug(title_input text)
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
      SELECT 1 FROM blog_posts WHERE slug = final_slug
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
CREATE OR REPLACE FUNCTION blog_posts_before_insert_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate slug if not provided
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := generate_unique_slug(NEW.title);
  END IF;
  
  -- Set updated_at timestamp
  NEW.updated_at := now();
  
  -- Set published_at if status is changing to PUBLISHED and published_at is null
  IF (NEW.status)::text = 'PUBLISHED' AND NEW.published_at IS NULL THEN
    NEW.published_at := now();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if it exists to avoid errors
DROP TRIGGER IF EXISTS blog_posts_before_insert_update_trigger ON blog_posts;

-- Create trigger
CREATE TRIGGER blog_posts_before_insert_update_trigger
BEFORE INSERT OR UPDATE ON blog_posts
FOR EACH ROW
EXECUTE FUNCTION blog_posts_before_insert_update();

-- Insert some sample tags
INSERT INTO blog_tags (name, slug) VALUES
('Photography', 'photography'),
('Family', 'family'),
('Wedding', 'wedding'),
('Newborn', 'newborn'),
('Business', 'business'),
('Tips', 'tips'),
('Behind the Scenes', 'behind-the-scenes')
ON CONFLICT (slug) DO NOTHING;