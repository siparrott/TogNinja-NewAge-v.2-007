-- Create professional digital files table with IPTC metadata support
CREATE TABLE IF NOT EXISTS digital_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  filename text NOT NULL,
  original_filename text NOT NULL,
  file_size bigint NOT NULL,
  mime_type text NOT NULL,
  file_path text NOT NULL,
  client_id uuid REFERENCES auth.users(id),
  client_name text,
  booking_id uuid,
  category text NOT NULL DEFAULT 'other',
  is_public boolean DEFAULT false,
  uploaded_by uuid REFERENCES auth.users(id) NOT NULL,
  
  -- Image dimensions
  width integer,
  height integer,
  
  -- Camera metadata (EXIF)
  camera_make text,
  camera_model text,
  lens_model text,
  focal_length text,
  aperture text,
  shutter_speed text,
  iso integer,
  captured_at timestamptz,
  
  -- IPTC metadata
  keywords text[], -- Array of keywords
  copyright text,
  description text,
  rating integer CHECK (rating >= 0 AND rating <= 5),
  color_profile text,
  
  -- Professional features
  is_favorite boolean DEFAULT false,
  view_count integer DEFAULT 0,
  download_count integer DEFAULT 0,
  
  -- Location metadata
  location text,
  city text,
  state text,
  country text,
  
  -- Creator information
  creator text,
  creator_title text,
  
  -- Timestamps
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE digital_files ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can manage their own files" 
  ON digital_files FOR ALL 
  TO authenticated 
  USING (uploaded_by = auth.uid())
  WITH CHECK (uploaded_by = auth.uid());

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_digital_files_uploaded_by ON digital_files(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_digital_files_category ON digital_files(category);
CREATE INDEX IF NOT EXISTS idx_digital_files_created_at ON digital_files(created_at);
CREATE INDEX IF NOT EXISTS idx_digital_files_keywords ON digital_files USING gin(keywords);
CREATE INDEX IF NOT EXISTS idx_digital_files_rating ON digital_files(rating);
CREATE INDEX IF NOT EXISTS idx_digital_files_is_favorite ON digital_files(is_favorite);

-- Create storage bucket for digital files
INSERT INTO storage.buckets (id, name, public) 
VALUES ('digital-files', 'digital-files', false)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies
CREATE POLICY "Users can upload their own files" 
  ON storage.objects FOR INSERT 
  TO authenticated 
  WITH CHECK (bucket_id = 'digital-files');

CREATE POLICY "Users can view their own files" 
  ON storage.objects FOR SELECT 
  TO authenticated 
  USING (bucket_id = 'digital-files');

CREATE POLICY "Users can update their own files" 
  ON storage.objects FOR UPDATE 
  TO authenticated 
  USING (bucket_id = 'digital-files');

CREATE POLICY "Users can delete their own files" 
  ON storage.objects FOR DELETE 
  TO authenticated 
  USING (bucket_id = 'digital-files');

-- Create function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_digital_files_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_update_digital_files_updated_at
  BEFORE UPDATE ON digital_files
  FOR EACH ROW
  EXECUTE FUNCTION update_digital_files_updated_at();
