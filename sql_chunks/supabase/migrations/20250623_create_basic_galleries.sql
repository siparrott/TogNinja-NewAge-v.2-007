/*
  # Create Basic Galleries Table
  
  This creates a basic galleries table with minimal required columns
  that can be enhanced later with additional features.
*/

-- Create basic galleries table
CREATE TABLE IF NOT EXISTS galleries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  client_id uuid REFERENCES auth.users(id) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE galleries ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admin can manage galleries" ON galleries;
DROP POLICY IF EXISTS "Authenticated users can create galleries" ON galleries;

-- Create comprehensive policy for gallery management
CREATE POLICY "Gallery management policy" 
  ON galleries FOR ALL 
  TO authenticated 
  USING (auth.uid() = client_id)
  WITH CHECK (auth.uid() = client_id);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_galleries_client_id ON galleries(client_id);
CREATE INDEX IF NOT EXISTS idx_galleries_created_at ON galleries(created_at);
