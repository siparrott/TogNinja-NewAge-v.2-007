/*
  # Add uploaded_at and shared_to_togninja columns to gallery_images

  Adds timestamp for upload tracking and a flag for TogNinja sharing.
*/

-- uploaded_at column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'gallery_images'
      AND column_name = 'uploaded_at'
  ) THEN
    ALTER TABLE gallery_images
      ADD COLUMN uploaded_at timestamptz DEFAULT now();
  END IF;
END $$;

-- shared_to_togninja column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'gallery_images'
      AND column_name = 'shared_to_togninja'
  ) THEN
    ALTER TABLE gallery_images
      ADD COLUMN shared_to_togninja boolean DEFAULT false;
  END IF;
END $$;
