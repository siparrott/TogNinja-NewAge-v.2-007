-- FIX BLOG FEATURED IMAGES
-- Run this to fix existing blog posts with missing or incorrect image paths

-- Update existing blog posts to use correct image paths
UPDATE public.blog_posts 
SET image_url = '/frontend-logo.jpg'
WHERE image_url IS NULL OR image_url = '' OR image_url NOT LIKE '/%';

-- Fix specific problematic image references
UPDATE public.blog_posts 
SET image_url = '/crm-logo.png'
WHERE title LIKE '%Photography Tips%';

UPDATE public.blog_posts 
SET image_url = '/togninja-logo.svg'
WHERE title LIKE '%Behind the Scenes%' OR title LIKE '%Wedding%';

-- Ensure all published posts have an image
UPDATE public.blog_posts 
SET image_url = '/frontend-logo.jpg'
WHERE status = 'published' AND (image_url IS NULL OR image_url = '');

-- Remove any demo/test posts that shouldn't be there
DELETE FROM public.blog_posts 
WHERE title IN ('DV', 'TEST', 'test') 
   OR content IN ('QREG', 'test')
   OR slug IN ('dv', 'test');

-- Verify the fixes
SELECT title, slug, image_url, status FROM public.blog_posts 
WHERE status = 'published' 
ORDER BY published_at DESC;
