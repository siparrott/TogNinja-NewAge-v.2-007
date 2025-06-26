/*
  # Add galleries and photos tables

  1. New Tables
    - `galleries`
      - `id` (uuid, primary key)
      - `title` (text)
      - `description` (text)
      - `client_id` (uuid, references auth.users)
      - `created_at` (timestamp)
      - `expires_at` (timestamp)
    
    - `photos`
      - `id` (uuid, primary key)
      - `gallery_id` (uuid, references galleries)
      - `url` (text)
      - `title` (text)
      - `description` (text)
      - `created_at` (timestamp)
  
  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users to read their own galleries and photos
*/

-- Create galleries table
CREATE TABLE IF NOT EXISTS galleries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  client_id uuid REFERENCES auth.users NOT NULL,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz
);

-- Create photos table
CREATE TABLE IF NOT EXISTS photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id uuid REFERENCES galleries NOT NULL,
  url text NOT NULL,
  title text,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE galleries ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

-- Create policies for galleries
CREATE POLICY "Users can view own galleries"
  ON galleries
  FOR SELECT
  TO authenticated
  USING (auth.uid() = client_id);

-- Create policies for photos
CREATE POLICY "Users can view photos from their galleries"
  ON photos
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM galleries 
      WHERE galleries.id = gallery_id 
      AND galleries.client_id = auth.uid()
    )
  );