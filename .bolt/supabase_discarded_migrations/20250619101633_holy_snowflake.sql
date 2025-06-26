/*
  # Add foreign key constraint for blog posts author

  1. Changes
    - Add foreign key constraint linking blog_posts.author_id to auth.users.id
    - This enables Supabase to understand the relationship for queries

  2. Security
    - No changes to RLS policies needed
    - Foreign key ensures data integrity
*/

-- Add foreign key constraint for author_id
ALTER TABLE public.blog_posts 
ADD CONSTRAINT blog_posts_author_id_fkey 
FOREIGN KEY (author_id) 
REFERENCES auth.users(id) 
ON DELETE SET NULL;