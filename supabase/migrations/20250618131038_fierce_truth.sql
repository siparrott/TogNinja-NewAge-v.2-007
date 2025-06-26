/*
  # Manual Admin Setup Function

  1. Function to manually add admin user
    - Creates a function to add admin privileges to any user
    - Can be called after user registration

  2. Usage
    - After user signs up with matt@newagefotografie.com
    - Call SELECT setup_admin_user('matt@newagefotografie.com');
*/

-- Function to manually set up admin user
CREATE OR REPLACE FUNCTION setup_admin_user(user_email text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  target_user_id uuid;
  result_message text;
BEGIN
  -- Find user by email
  SELECT id INTO target_user_id 
  FROM auth.users 
  WHERE email = user_email 
  LIMIT 1;

  -- Check if user exists
  IF target_user_id IS NULL THEN
    result_message := 'User with email ' || user_email || ' not found. Please sign up first.';
    RETURN result_message;
  END IF;

  -- Insert or update admin status
  INSERT INTO admin_users (user_id, is_admin)
  VALUES (target_user_id, true)
  ON CONFLICT (user_id) 
  DO UPDATE SET is_admin = true;

  result_message := 'Successfully set up admin privileges for ' || user_email;
  RETURN result_message;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION setup_admin_user(text) TO authenticated;

-- Automatically try to set up the admin user if they exist
SELECT setup_admin_user('matt@newagefotografie.com');