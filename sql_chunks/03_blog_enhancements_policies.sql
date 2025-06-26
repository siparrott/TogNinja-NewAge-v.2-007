-- BLOG ENHANCEMENT - CHUNK 3: Create Policies and Functions
-- Run this AFTER Chunk 2 completes successfully

-- Update existing policies
DROP POLICY IF EXISTS "Public can read published posts" ON blog_posts;
DROP POLICY IF EXISTS "Admin users can manage all posts" ON blog_posts;

-- Create enhanced policies for blog_posts
CREATE POLICY "Public can read published blog posts"
  ON blog_posts FOR SELECT TO public
  USING (status = 'PUBLISHED' AND (published_at IS NULL OR published_at <= now()));

CREATE POLICY "Admin users can manage blog posts"
  ON blog_posts FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create policies for blog_tags
CREATE POLICY "Public can read blog tags"
  ON blog_tags FOR SELECT TO public
  USING (true);

CREATE POLICY "Admin users can manage blog tags"
  ON blog_tags FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create policies for blog_post_tags
CREATE POLICY "Public can read blog post tags"
  ON blog_post_tags FOR SELECT TO public
  USING (EXISTS (
    SELECT 1 FROM blog_posts
    WHERE blog_posts.id = post_id
    AND blog_posts.status = 'PUBLISHED'
    AND (blog_posts.published_at IS NULL OR blog_posts.published_at <= now())
  ));

CREATE POLICY "Admin users can manage blog post tags"
  ON blog_post_tags FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Create policies for blog_comments
CREATE POLICY "Public can read approved comments"
  ON blog_comments FOR SELECT TO public
  USING (status = 'approved');

CREATE POLICY "Public can insert comments"
  ON blog_comments FOR INSERT TO public
  WITH CHECK (status = 'pending');

CREATE POLICY "Admin users can manage comments"
  ON blog_comments FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid() AND is_admin = true
  ));

-- Verify the changes
SELECT 'Blog policies created successfully!' as status;
