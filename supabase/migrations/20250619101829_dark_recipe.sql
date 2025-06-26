/*
  # Fix Blog Posts Author Relationship

  1. Changes
     - Checks if the foreign key constraint already exists before attempting to add it
     - Uses DO block with conditional logic to safely add the constraint
*/

-- Check if constraint exists before adding it
DO $$ 
BEGIN
  -- Check if the constraint already exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'blog_posts_author_id_fkey' 
    AND conrelid = 'public.blog_posts'::regclass
  ) THEN
    -- Add foreign key constraint for author_id if it doesn't exist
    ALTER TABLE public.blog_posts 
    ADD CONSTRAINT blog_posts_author_id_fkey 
    FOREIGN KEY (author_id) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;
  END IF;
END $$;