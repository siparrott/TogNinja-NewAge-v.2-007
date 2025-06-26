/*
  # Fix Blog Posts Schema

  1. Schema Updates
    - Ensure blog_posts table has all required fields for rich editing
    - Add content_html field if missing
    - Add SEO fields if missing
    - Add proper foreign key relationship to auth.users

  2. Security
    - Maintain existing RLS policies
*/

-- Check if content_html column exists and add it if not
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'blog_posts' AND column_name = 'content_html'
  ) THEN
    ALTER TABLE blog_posts ADD COLUMN content_html TEXT;
  END IF;
END $$;

-- Check if content column exists and rename it to content_html if needed
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'blog_posts' AND column_name = 'content'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'blog_posts' AND column_name = 'content_html'
  ) THEN
    ALTER TABLE blog_posts RENAME COLUMN content TO content_html;
  END IF;
END $$;

-- Add SEO fields if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'blog_posts' AND column_name = 'seo_title'
  ) THEN
    ALTER TABLE blog_posts ADD COLUMN seo_title TEXT;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'blog_posts' AND column_name = 'meta_description'
  ) THEN
    ALTER TABLE blog_posts ADD COLUMN meta_description TEXT;
  END IF;
END $$;

-- Add image_url field if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'blog_posts' AND column_name = 'image_url'
  ) THEN
    ALTER TABLE blog_posts ADD COLUMN image_url TEXT;
  END IF;
END $$;

-- Add tags field if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'blog_posts' AND column_name = 'tags'
  ) THEN
    ALTER TABLE blog_posts ADD COLUMN tags TEXT[];
  END IF;
END $$;

-- Create blog_tags table if it doesn't exist
CREATE TABLE IF NOT EXISTS blog_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ensure foreign key relationship exists between blog_posts and auth.users
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'blog_posts_author_id_fkey'
  ) THEN
    -- Check if author_id column exists
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'blog_posts' AND column_name = 'author_id'
    ) THEN
      -- Add foreign key constraint
      ALTER TABLE blog_posts 
      ADD CONSTRAINT blog_posts_author_id_fkey 
      FOREIGN KEY (author_id) REFERENCES auth.users(id);
    END IF;
  END IF;
END $$;

-- Enable RLS on blog_tags
ALTER TABLE blog_tags ENABLE ROW LEVEL SECURITY;

-- Add RLS policies for blog_tags
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'blog_tags' AND policyname = 'Admin users can manage tags'
  ) THEN
    CREATE POLICY "Admin users can manage tags" ON blog_tags
    USING (EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid() AND admin_users.is_admin = true
    ))
    WITH CHECK (EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid() AND admin_users.is_admin = true
    ));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'blog_tags' AND policyname = 'Public can read tags'
  ) THEN
    CREATE POLICY "Public can read tags" ON blog_tags
    FOR SELECT
    USING (true);
  END IF;
END $$;