-- Complete Neon Database Export Commands
-- Run these commands in your Shell to create a complete backup

-- STEP 1: Create complete database dump
-- Replace the connection string with your actual credentials
-- This will create a file called 'neon_complete_backup.sql' in your current directory

pg_dump "postgresql://[username]:[password]@ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech/neondb?sslmode=require" > neon_complete_backup.sql

-- STEP 2: (Optional) Create schema-only dump for structure reference
pg_dump --schema-only "postgresql://[username]:[password]@ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech/neondb?sslmode=require" > neon_schema_only.sql

-- STEP 3: (Optional) Create data-only dump for just the data
pg_dump --data-only "postgresql://[username]:[password]@ep-bitter-tooth-a6gzcoua.us-west-2.aws.neon.tech/neondb?sslmode=require" > neon_data_only.sql

-- RESTORE COMMANDS (for your new database):

-- STEP 4: Restore complete database to new location
-- Replace with your new database connection string
psql "postgresql://[new_username]:[new_password]@new-host:5432/new_database" < neon_complete_backup.sql

-- Or if you have schema + data separately:
-- psql "new-connection" < neon_schema_only.sql
-- psql "new-connection" < neon_data_only.sql

-- FILE LOCATIONS:
-- All .sql files will be created in your current working directory: /home/runner/workspace/
-- Files created:
-- - neon_complete_backup.sql (complete database with structure + data)
-- - neon_schema_only.sql (just table structures, no data)  
-- - neon_data_only.sql (just data, no table structures)