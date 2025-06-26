-- BLOG ENHANCEMENT - CHUNK 5: Sample Data and Views
-- Run this AFTER Chunk 4 completes successfully

-- Insert enhanced sample tags
INSERT INTO blog_tags (name, description, color) VALUES
('Photography Tips', 'Professional photography advice and techniques', '#3B82F6'),
('Family Sessions', 'Family portrait photography', '#10B981'),
('Wedding Photography', 'Wedding day photography insights', '#F59E0B'),
('Newborn Photography', 'Newborn and baby photography', '#EC4899'),
('Business Portraits', 'Corporate and business photography', '#6366F1'),
('Behind the Scenes', 'Studio insights and processes', '#8B5CF6'),
('Photo Editing', 'Post-processing tips and techniques', '#06B6D4'),
('Client Stories', 'Featured client experiences', '#84CC16'),
('Equipment Reviews', 'Camera gear and equipment', '#EF4444'),
('Studio News', 'Updates and announcements', '#F97316')
ON CONFLICT (name) DO NOTHING;

-- Create enhanced view for posts with tags
CREATE OR REPLACE VIEW blog_posts_with_tags AS
SELECT 
  p.*,
  COALESCE(
    json_agg(
      json_build_object(
        'id', t.id,
        'name', t.name,
        'slug', t.slug,
        'color', t.color
      ) ORDER BY t.name
    ) FILTER (WHERE t.id IS NOT NULL),
    '[]'::json
  ) as tags
FROM blog_posts p
LEFT JOIN blog_post_tags pt ON p.id = pt.post_id
LEFT JOIN blog_tags t ON pt.tag_id = t.id
GROUP BY p.id, p.title, p.slug, p.content_html, p.excerpt, p.cover_image, 
         p.status, p.published, p.seo_title, p.meta_description, p.author_id, 
         p.created_at, p.updated_at, p.published_at, p.scheduled_for, 
         p.view_count, p.featured;

-- Update any existing published posts to have the correct status
UPDATE blog_posts 
SET status = 'PUBLISHED', published_at = COALESCE(published_at, created_at)
WHERE published = true AND status IS NULL;

UPDATE blog_posts 
SET status = 'DRAFT'
WHERE (published = false OR published IS NULL) AND status IS NULL;

-- Verify the changes
SELECT 
  'Blog enhancement complete!' as status,
  count(*) as total_posts,
  count(*) FILTER (WHERE status = 'PUBLISHED') as published_posts,
  count(*) FILTER (WHERE status = 'DRAFT') as draft_posts
FROM blog_posts;
