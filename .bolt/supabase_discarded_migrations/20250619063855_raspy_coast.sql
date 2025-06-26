/*
  # Create blog tables

  1. New Tables
    - `blog_posts` - Stores blog post content and metadata
    - `blog_tags` - Stores blog post tags/categories
  
  2. Security
    - Enable RLS on all tables
    - Add policies for admin access and public read access
*/

-- Create blog_tags table
CREATE TABLE IF NOT EXISTS blog_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create blog_posts table
CREATE TABLE IF NOT EXISTS blog_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  excerpt text,
  content_html text NOT NULL,
  cover_image text,
  tags text[],
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PUBLISHED', 'SCHEDULED')),
  seo_title text,
  meta_description text,
  author_id uuid NOT NULL REFERENCES auth.users(id),
  published_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE blog_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

-- Create policies for blog_tags
CREATE POLICY "Admin users can manage tags"
  ON blog_tags
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid()
      AND is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid()
      AND is_admin = true
    )
  );

CREATE POLICY "Public can read tags"
  ON blog_tags
  FOR SELECT
  TO public
  USING (true);

-- Create policies for blog_posts
CREATE POLICY "Admin users can manage all posts"
  ON blog_posts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid()
      AND is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE user_id = auth.uid()
      AND is_admin = true
    )
  );

CREATE POLICY "Public can read published posts"
  ON blog_posts
  FOR SELECT
  TO public
  USING (status = 'PUBLISHED');

-- Create some initial tags
INSERT INTO blog_tags (name, slug) VALUES
  ('Family', 'family'),
  ('Newborn', 'newborn'),
  ('Wedding', 'wedding'),
  ('Business', 'business'),
  ('Event', 'event'),
  ('Tips', 'tips'),
  ('Behind the Scenes', 'behind-the-scenes')
ON CONFLICT (slug) DO NOTHING;