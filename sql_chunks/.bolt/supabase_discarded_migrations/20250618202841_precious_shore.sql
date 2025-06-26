/*
  # Add client import tables

  1. New Tables
    - `import_logs` - Tracks CSV import operations
    - `import_presets` - Stores saved column mappings for CSV imports
    - `import_errors` - Records errors encountered during imports
  
  2. Security
    - Enable RLS on all tables
    - Add policies for admin users
*/

-- Import logs table
CREATE TABLE IF NOT EXISTS import_logs (
  id uuid PRIMARY KEY,
  filename text NOT NULL,
  imported_by uuid NOT NULL REFERENCES auth.users(id),
  rows_processed integer DEFAULT 0,
  rows_success integer DEFAULT 0,
  rows_error integer DEFAULT 0,
  error_file_url text,
  created_at timestamptz DEFAULT now()
);

-- Import presets table
CREATE TABLE IF NOT EXISTS import_presets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  mapping jsonb NOT NULL,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- Import errors table
CREATE TABLE IF NOT EXISTS import_errors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  import_id uuid REFERENCES import_logs(id) ON DELETE CASCADE,
  row_number integer NOT NULL,
  row_data jsonb NOT NULL,
  error_message text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE import_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_errors ENABLE ROW LEVEL SECURITY;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_import_logs_imported_by ON import_logs(imported_by);
CREATE INDEX IF NOT EXISTS idx_import_presets_created_by ON import_presets(created_by);
CREATE INDEX IF NOT EXISTS idx_import_errors_import_id ON import_errors(import_id);

-- Create policies
CREATE POLICY "Admin users can manage import logs"
  ON import_logs
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.user_id = auth.uid() AND admin_users.is_admin = true
  ));

CREATE POLICY "Admin users can manage import presets"
  ON import_presets
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.user_id = auth.uid() AND admin_users.is_admin = true
  ));

CREATE POLICY "Admin users can manage import errors"
  ON import_errors
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.user_id = auth.uid() AND admin_users.is_admin = true
  ));