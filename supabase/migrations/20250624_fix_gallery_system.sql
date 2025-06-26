/*
  # Fix Gallery System and Enable Enhanced Features
  
  This migration fixes the gallery system to work with both basic and enhanced features:
  1. Updates existing basic galleries table
  2. Ensures proper RLS policies
  3. Creates missing columns for enhanced features
  4. Sets up proper storage buckets and policies
*/

-- Add missing columns to basic galleries table
ALTER TABLE galleries 
ADD COLUMN IF NOT EXISTS slug text,
ADD COLUMN IF NOT EXISTS description text,
ADD COLUMN IF NOT EXISTS cover_image text,
ADD COLUMN IF NOT EXISTS password_hash text,
ADD COLUMN IF NOT EXISTS download_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS watermark_enabled boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS expires_at timestamptz,
ADD COLUMN IF NOT EXISTS client_email text,
ADD COLUMN IF NOT EXISTS is_featured boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS sort_order integer DEFAULT 0;

-- Generate slugs for existing galleries without them
UPDATE galleries 
SET slug = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(title, '[^\w\s]', '', 'g'), '\s+', '-', 'g'))
WHERE slug IS NULL;

-- Make slug unique
ALTER TABLE galleries ADD CONSTRAINT galleries_slug_unique UNIQUE (slug);

-- Create gallery_images table if it doesn't exist
CREATE TABLE IF NOT EXISTS gallery_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries(id) ON DELETE CASCADE NOT NULL,
  original_url text NOT NULL,
  display_url text NOT NULL,
  thumb_url text NOT NULL,
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
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS on gallery_images
ALTER TABLE gallery_images ENABLE ROW LEVEL SECURITY;

-- Create gallery_images policies
CREATE POLICY "Gallery images policy" 
  ON gallery_images FOR ALL 
  TO authenticated 
  USING (
    EXISTS (
      SELECT 1 FROM galleries 
      WHERE galleries.id = gallery_images.gallery_id 
      AND galleries.client_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM galleries 
      WHERE galleries.id = gallery_images.gallery_id 
      AND galleries.client_id = auth.uid()
    )
  );

-- Create gallery_visitors table if it doesn't exist
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

-- Enable RLS on gallery_visitors
ALTER TABLE gallery_visitors ENABLE ROW LEVEL SECURITY;

-- Create gallery_visitors policies
CREATE POLICY "Gallery visitors policy" 
  ON gallery_visitors FOR ALL 
  TO authenticated 
  USING (
    EXISTS (
      SELECT 1 FROM galleries 
      WHERE galleries.id = gallery_visitors.gallery_id 
      AND galleries.client_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM galleries 
      WHERE galleries.id = gallery_visitors.gallery_id 
      AND galleries.client_id = auth.uid()
    )
  );

-- Create storage bucket for gallery images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('gallery-images', 'gallery-images', false)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for gallery images
DROP POLICY IF EXISTS "Gallery images upload policy" ON storage.objects;
DROP POLICY IF EXISTS "Gallery images view policy" ON storage.objects;
DROP POLICY IF EXISTS "Gallery images update policy" ON storage.objects;
DROP POLICY IF EXISTS "Gallery images delete policy" ON storage.objects;

CREATE POLICY "Gallery images upload policy" 
  ON storage.objects FOR INSERT 
  TO authenticated 
  WITH CHECK (bucket_id = 'gallery-images');

CREATE POLICY "Gallery images view policy" 
  ON storage.objects FOR SELECT 
  TO authenticated 
  USING (bucket_id = 'gallery-images');

CREATE POLICY "Gallery images update policy" 
  ON storage.objects FOR UPDATE 
  TO authenticated 
  USING (bucket_id = 'gallery-images');

CREATE POLICY "Gallery images delete policy" 
  ON storage.objects FOR DELETE 
  TO authenticated 
  USING (bucket_id = 'gallery-images');

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_galleries_slug ON galleries(slug);
CREATE INDEX IF NOT EXISTS idx_galleries_is_featured ON galleries(is_featured);
CREATE INDEX IF NOT EXISTS idx_galleries_sort_order ON galleries(sort_order);
CREATE INDEX IF NOT EXISTS idx_gallery_images_gallery_id ON gallery_images(gallery_id);
CREATE INDEX IF NOT EXISTS idx_gallery_images_order_index ON gallery_images(order_index);
CREATE INDEX IF NOT EXISTS idx_gallery_visitors_gallery_id ON gallery_visitors(gallery_id);
CREATE INDEX IF NOT EXISTS idx_gallery_visitors_access_token ON gallery_visitors(access_token);

-- Update function for galleries updated_at
CREATE OR REPLACE FUNCTION update_galleries_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for galleries
DROP TRIGGER IF EXISTS trigger_update_galleries_updated_at ON galleries;
CREATE TRIGGER trigger_update_galleries_updated_at
  BEFORE UPDATE ON galleries
  FOR EACH ROW
  EXECUTE FUNCTION update_galleries_updated_at();

-- Update function for gallery_images updated_at
CREATE OR REPLACE FUNCTION update_gallery_images_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for gallery_images
DROP TRIGGER IF EXISTS trigger_update_gallery_images_updated_at ON gallery_images;
CREATE TRIGGER trigger_update_gallery_images_updated_at
  BEFORE UPDATE ON gallery_images
  FOR EACH ROW
  EXECUTE FUNCTION update_gallery_images_updated_at();
