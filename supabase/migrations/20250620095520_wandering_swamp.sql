/*
  # Fix Gallery Images Table and Access Logs

  1. New Tables
    - Ensures `gallery_images` table exists with proper structure
    - Adds foreign key constraint if needed
  2. Security
    - Enables RLS on the table
    - Adds policy for admin users conditionally
  3. Performance
    - Creates indexes for faster lookups
*/

-- First create the gallery_images table if it doesn't exist
CREATE TABLE IF NOT EXISTS gallery_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid NOT NULL,
  original_url text NOT NULL,
  display_url text NOT NULL,
  thumb_url text NOT NULL,
  filename text NOT NULL,
  size_bytes bigint NOT NULL,
  content_type text NOT NULL,
  captured_at timestamptz,
  order_index integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  uploaded_at timestamptz DEFAULT now(),
  shared_to_togninja boolean DEFAULT false
);

-- Add foreign key if the galleries table exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'galleries'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE constraint_name = 'gallery_images_gallery_id_fkey'
    ) THEN
      ALTER TABLE gallery_images
        ADD CONSTRAINT gallery_images_gallery_id_fkey
        FOREIGN KEY (gallery_id) REFERENCES galleries(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

-- Enable RLS on the table
ALTER TABLE gallery_images ENABLE ROW LEVEL SECURITY;

-- Create policy for admin users only if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'gallery_images' 
    AND policyname = 'Admin users can manage gallery images'
  ) THEN
    CREATE POLICY "Admin users can manage gallery images"
      ON gallery_images
      FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM admin_users
          WHERE admin_users.user_id = auth.uid()
          AND admin_users.is_admin = true
        )
      );
  END IF;
END $$;

-- Create index on gallery_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_gallery_images_gallery_id
  ON gallery_images(gallery_id);

-- Create index on order_index for sorted queries
CREATE INDEX IF NOT EXISTS idx_gallery_images_order_index
  ON gallery_images(gallery_id, order_index);