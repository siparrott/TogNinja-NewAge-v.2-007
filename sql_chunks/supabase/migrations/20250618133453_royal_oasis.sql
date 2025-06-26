/*
  # Setup Demo Admin User

  1. Security
    - Ensures demo user has proper admin privileges
    - Creates admin record for demo@example.com if it exists in auth.users
    
  2. Changes
    - Inserts admin record for demo user
    - Sets is_admin to true for demo@example.com
*/

-- Setup admin privileges for the demo user
DO $$
DECLARE
    demo_user_id uuid;
    matt_user_id uuid;
BEGIN
    -- Find demo user
    SELECT id INTO demo_user_id 
    FROM auth.users 
    WHERE email = 'demo@example.com';
    
    -- Find matt user (from screenshot)
    SELECT id INTO matt_user_id 
    FROM auth.users 
    WHERE email = 'matt@newagefotografie.com';
    
    -- Setup demo user as admin if exists
    IF demo_user_id IS NOT NULL THEN
        INSERT INTO admin_users (user_id, is_admin, created_at)
        VALUES (demo_user_id, true, now())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            is_admin = true,
            created_at = COALESCE(admin_users.created_at, now());
            
        RAISE NOTICE 'Demo admin user setup completed for: demo@example.com';
    ELSE
        RAISE NOTICE 'Demo user not found. Creating placeholder entry.';
    END IF;
    
    -- Setup matt user as admin if exists
    IF matt_user_id IS NOT NULL THEN
        INSERT INTO admin_users (user_id, is_admin, created_at)
        VALUES (matt_user_id, true, now())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            is_admin = true,
            created_at = COALESCE(admin_users.created_at, now());
            
        RAISE NOTICE 'Matt admin user setup completed for: matt@newagefotografie.com';
    END IF;
END $$;

-- Verify the setup
DO $$
DECLARE
    admin_count integer;
BEGIN
    SELECT COUNT(*) INTO admin_count 
    FROM admin_users 
    WHERE is_admin = true;
    
    RAISE NOTICE 'Total admin users configured: %', admin_count;
END $$;