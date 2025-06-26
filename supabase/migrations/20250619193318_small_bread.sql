-- Create gallery_access_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS gallery_access_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid NOT NULL,
  email text NOT NULL,
  first_name text,
  last_name text,
  accessed_at timestamptz DEFAULT now(),
  ip_address text,
  user_agent text
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
      WHERE constraint_name = 'gallery_access_logs_gallery_id_fkey'
    ) THEN
      ALTER TABLE gallery_access_logs
        ADD CONSTRAINT gallery_access_logs_gallery_id_fkey
        FOREIGN KEY (gallery_id) REFERENCES galleries(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

-- Enable RLS on the access logs table
ALTER TABLE gallery_access_logs ENABLE ROW LEVEL SECURITY;

-- Create policy for admin users to view access logs
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'gallery_access_logs' 
    AND policyname = 'Admin users can view access logs'
  ) THEN
    EXECUTE 'CREATE POLICY "Admin users can view access logs"
      ON gallery_access_logs
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM admin_users
          WHERE admin_users.user_id = auth.uid()
          AND admin_users.is_admin = true
        )
      )';
  END IF;
END $$;

-- Create index on gallery_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_gallery_access_logs_gallery_id
  ON gallery_access_logs(gallery_id);

-- Create index on accessed_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_gallery_access_logs_accessed_at
  ON gallery_access_logs(accessed_at);

-- Add first_name and last_name columns to gallery_visitors if they don't exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'gallery_visitors'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'gallery_visitors' AND column_name = 'first_name'
    ) THEN
      ALTER TABLE gallery_visitors ADD COLUMN first_name text;
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'gallery_visitors' AND column_name = 'last_name'
    ) THEN
      ALTER TABLE gallery_visitors ADD COLUMN last_name text;
    END IF;
  END IF;
END $$;