-- BLOG ENHANCEMENT - CHUNK 4: Functions and Sample Data
-- Run this AFTER Chunk 3 completes successfully

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

-- Verify the changes
SELECT 'Blog functions and triggers created successfully!' as status;
