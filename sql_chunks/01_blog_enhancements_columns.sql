-- BLOG ENHANCEMENT - CHUNK 1: Add Status Enum and New Columns
-- Copy and paste this into your Supabase SQL Editor

-- Create the enhanced status enum
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

-- Verify the changes
SELECT 'Blog posts table enhanced successfully!' as status;
