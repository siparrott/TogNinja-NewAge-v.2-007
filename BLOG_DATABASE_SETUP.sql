-- BLOG SYSTEM DATABASE SETUP
-- Run this in your Supabase SQL Editor to fix blog functionality

-- 1. CREATE BLOG POSTS TABLE
CREATE TABLE IF NOT EXISTS public.blog_posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    content TEXT,
    content_html TEXT,
    excerpt TEXT,
    image_url TEXT,
    author_id UUID REFERENCES auth.users(id),
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    featured BOOLEAN DEFAULT false,
    meta_title TEXT,
    meta_description TEXT,
    tags TEXT[]
);

-- 2. ENABLE RLS
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;

-- 3. CREATE RLS POLICIES
DROP POLICY IF EXISTS "Blog posts are publicly readable" ON public.blog_posts;
CREATE POLICY "Blog posts are publicly readable" ON public.blog_posts
    FOR SELECT USING (status = 'published');

DROP POLICY IF EXISTS "Authors can manage their blog posts" ON public.blog_posts;
CREATE POLICY "Authors can manage their blog posts" ON public.blog_posts
    FOR ALL USING (auth.uid() = author_id);

-- 4. CREATE INDEXES
CREATE INDEX IF NOT EXISTS idx_blog_posts_slug ON public.blog_posts(slug);
CREATE INDEX IF NOT EXISTS idx_blog_posts_published_at ON public.blog_posts(published_at);
CREATE INDEX IF NOT EXISTS idx_blog_posts_status ON public.blog_posts(status);
CREATE INDEX IF NOT EXISTS idx_blog_posts_featured ON public.blog_posts(featured);

-- 5. CREATE SAMPLE BLOG POSTS (REAL CONTENT WITH WORKING IMAGES)
INSERT INTO public.blog_posts (
    title, 
    slug, 
    content, 
    content_html, 
    excerpt, 
    image_url, 
    author_id, 
    published_at, 
    status,
    featured,
    meta_title,
    meta_description,
    tags
) VALUES 
(
    'Welcome to Our Photography Blog',
    'welcome-to-our-photography-blog',
    'Welcome to our photography blog! Here you''ll find tips, insights, and behind-the-scenes looks at our work.',
    '<p>Welcome to our photography blog! Here you''ll find tips, insights, and behind-the-scenes looks at our work.</p>',
    'Welcome to our photography blog with tips and insights.',
    '/frontend-logo.jpg',
    auth.uid(),
    NOW(),
    'published',
    true,
    'Welcome to Our Photography Blog',
    'Discover photography tips, insights, and behind-the-scenes content.',
    ARRAY['welcome', 'photography', 'blog']
),
(
    'Photography Tips for Beginners',
    'photography-tips-for-beginners',
    'Starting your photography journey? Here are essential tips to help you get started with camera basics, composition, and lighting.',
    '<p>Starting your photography journey? Here are essential tips to help you get started with camera basics, composition, and lighting.</p>',
    'Essential photography tips for beginners covering camera basics and composition.',
    '/crm-logo.png',
    auth.uid(),
    NOW() - INTERVAL '1 day',
    'published',
    false,
    'Photography Tips for Beginners',
    'Learn essential photography tips for beginners including camera basics and composition.',
    ARRAY['photography', 'tips', 'beginners', 'tutorial']
),
(
    'Behind the Scenes: Wedding Photography',
    'behind-the-scenes-wedding-photography',
    'Take a look behind the scenes of a recent wedding photoshoot and discover the planning and preparation that goes into capturing the perfect moments.',
    '<p>Take a look behind the scenes of a recent wedding photoshoot and discover the planning and preparation that goes into capturing the perfect moments.</p>',
    'Behind the scenes look at wedding photography planning and execution.',
    '/togninja-logo.svg',
    auth.uid(),
    NOW() - INTERVAL '3 days',
    'published',
    false,
    'Behind the Scenes: Wedding Photography',
    'Discover the planning and preparation behind professional wedding photography.',
    ARRAY['wedding', 'photography', 'behind-the-scenes']
)
ON CONFLICT (slug) DO NOTHING;

-- 6. CREATE BLOG CATEGORIES TABLE (OPTIONAL)
CREATE TABLE IF NOT EXISTS public.blog_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. ENABLE RLS FOR CATEGORIES
ALTER TABLE public.blog_categories ENABLE ROW LEVEL SECURITY;

-- 8. CREATE POLICY FOR CATEGORIES
CREATE POLICY "Blog categories are publicly readable" ON public.blog_categories
    FOR SELECT USING (true);

-- 9. INSERT SAMPLE CATEGORIES
INSERT INTO public.blog_categories (name, slug, description) VALUES
('Photography Tips', 'photography-tips', 'Tips and techniques for better photography'),
('Behind the Scenes', 'behind-the-scenes', 'Behind the scenes content from our shoots'),
('Client Stories', 'client-stories', 'Stories and testimonials from our clients'),
('Equipment Reviews', 'equipment-reviews', 'Reviews of photography equipment and gear')
ON CONFLICT (slug) DO NOTHING;

-- 10. CREATE BLOG POST CATEGORIES JUNCTION TABLE
CREATE TABLE IF NOT EXISTS public.blog_post_categories (
    blog_post_id UUID REFERENCES public.blog_posts(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.blog_categories(id) ON DELETE CASCADE,
    PRIMARY KEY (blog_post_id, category_id)
);

-- 11. ENABLE RLS FOR JUNCTION TABLE
ALTER TABLE public.blog_post_categories ENABLE ROW LEVEL SECURITY;

-- 12. CREATE POLICY FOR JUNCTION TABLE
CREATE POLICY "Blog post categories are publicly readable" ON public.blog_post_categories
    FOR SELECT USING (true);

-- 13. VERIFY TABLES EXIST
SELECT 'blog_posts' as table_name, count(*) as row_count FROM public.blog_posts
UNION ALL
SELECT 'blog_categories' as table_name, count(*) as row_count FROM public.blog_categories;
