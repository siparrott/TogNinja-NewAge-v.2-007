import { createClient } from 'npm:@supabase/supabase-js@2.39.7';
import { DOMPurify } from 'npm:isomorphic-dompurify@1.3.0';
import slugify from 'npm:slugify@1.6.6';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const path = url.pathname.replace('/functions/v1/blog-api', '');
    const method = req.method;

    console.log(`Blog API: ${method} ${path}`);

    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    
    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('Missing Supabase environment variables');
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get auth token for protected routes
    const authHeader = req.headers.get('Authorization');
    let user = null;
    let isAdmin = false;

    if (authHeader) {
      try {
        const token = authHeader.replace('Bearer ', '');
        const { data: { user: authUser }, error: authError } = await supabase.auth.getUser(token);
        
        if (authError) {
          console.error('Auth error:', authError);
        } else {
          user = authUser;

          if (user) {
            // Check if user is admin
            const { data: adminData, error: adminError } = await supabase
              .from('admin_users')
              .select('is_admin')
              .eq('user_id', user.id)
              .single();

            if (adminError) {
              console.error('Admin check error:', adminError);
            } else {
              isAdmin = adminData?.is_admin || false;
            }
          }
        }
      } catch (error) {
        console.error('Authentication processing error:', error);
      }
    }

    // Route handling
    if (path === '/posts' && method === 'GET') {
      return await getPosts(supabase, url.searchParams);
    } else if (path.startsWith('/posts/') && method === 'GET') {
      const slug = path.split('/')[2];
      return await getPostBySlug(supabase, slug);
    } else if (path === '/posts' && method === 'POST') {
      // Check admin access
      if (!user || !isAdmin) {
        return new Response(
          JSON.stringify({ error: 'Unauthorized' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      return await createPost(supabase, req, user.id);
    } else if (path.startsWith('/posts/') && method === 'PUT') {
      // Check admin access
      if (!user || !isAdmin) {
        return new Response(
          JSON.stringify({ error: 'Unauthorized' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      const id = path.split('/')[2];
      return await updatePost(supabase, req, id);
    } else if (path.startsWith('/posts/') && method === 'DELETE') {
      // Check admin access
      if (!user || !isAdmin) {
        return new Response(
          JSON.stringify({ error: 'Unauthorized' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      const id = path.split('/')[2];
      return await deletePost(supabase, id);
    } else if (path === '/upload' && method === 'POST') {
      // Check admin access
      if (!user || !isAdmin) {
        return new Response(
          JSON.stringify({ error: 'Unauthorized' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      return await handleImageUpload(supabase, req);
    } else if (path.startsWith('/publish/') && method === 'POST') {
      // Check admin access
      if (!user || !isAdmin) {
        return new Response(
          JSON.stringify({ error: 'Unauthorized' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      const id = path.split('/')[2];
      return await publishPost(supabase, id);
    } else if (path.startsWith('/schedule/') && method === 'POST') {
      // Check admin access
      if (!user || !isAdmin) {
        return new Response(
          JSON.stringify({ error: 'Unauthorized' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      const id = path.split('/')[2];
      return await schedulePost(supabase, req, id);
    } else if (path === '/tags' && method === 'GET') {
      return await getTags(supabase);
    }

    return new Response(
      JSON.stringify({ error: 'Endpoint not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Blog API Error:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

async function getPosts(supabase: any, searchParams: URLSearchParams) {
  try {
    let query = supabase
      .from('blog_posts')
      .select('*', { count: 'exact' });
    
    // Filter by status (default to published for public)
    const status = searchParams.get('status') || 'PUBLISHED';
    if (status !== 'all') {
      query = query.eq('published', status === 'PUBLISHED');
    }
    
    // Filter by tag
    const tag = searchParams.get('tag');
    if (tag) {
      query = query.contains('tags', [tag]);
    }
    
    // Search by title or content
    const search = searchParams.get('search');
    if (search) {
      query = query.or(`title.ilike.%${search}%,content.ilike.%${search}%`);
    }
    
    // Pagination
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');
    const offset = (page - 1) * limit;
    
    query = query
      .order('published_at', { ascending: false })
      .range(offset, offset + limit - 1);
    
    const { data, error, count } = await query;
    
    if (error) throw error;
    
    return new Response(
      JSON.stringify({ posts: data, count }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error fetching posts:', error);
    throw error;
  }
}

async function getPostBySlug(supabase: any, slug: string) {
  try {
    const { data, error } = await supabase
      .from('blog_posts')
      .select(`
        *,
        author:author_id(email)
      `)
      .eq('slug', slug)
      .eq('published', true)
      .single();
    
    if (error) throw error;
    
    return new Response(
      JSON.stringify(data),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error fetching post by slug:', error);
    throw error;
  }
}

async function createPost(supabase: any, req: Request, authorId: string) {
  try {
    const postData = await req.json();
    
    // Sanitize HTML content and map to the correct database column
    if (postData.contentHtml) {
      const sanitizedContent = DOMPurify.sanitize(postData.contentHtml);
      postData.content = sanitizedContent; // Map to the required 'content' column
      postData.content_html = sanitizedContent; // Also populate content_html for consistency
      delete postData.contentHtml; // Remove the camelCase version
    } else {
      // Ensure content is never null
      postData.content = '';
      postData.content_html = '';
    }
    
    // Handle cover image
    if (postData.coverImage) {
      postData.image_url = postData.coverImage;
      delete postData.coverImage; // Remove the camelCase version
    }
    
    // Handle SEO fields
    if (postData.seoTitle) {
      postData.seo_title = postData.seoTitle;
      delete postData.seoTitle;
    }
    
    if (postData.metaDescription) {
      postData.meta_description = postData.metaDescription;
      delete postData.metaDescription;
    }
    
    // Generate slug if not provided
    if (!postData.slug && postData.title) {
      postData.slug = slugify(postData.title, { lower: true, strict: true });
      
      // Check if slug exists
      const { data: existingPost } = await supabase
        .from('blog_posts')
        .select('slug')
        .eq('slug', postData.slug)
        .maybeSingle();
      
      // If slug exists, append a random string
      if (existingPost) {
        const randomString = Math.random().toString(36).substring(2, 8);
        postData.slug = `${postData.slug}-${randomString}`;
      }
    }
    
    // Set author ID
    postData.author_id = authorId;
    
    // Set published status and date
    const isPublished = postData.status === 'PUBLISHED';
    postData.published = isPublished;
    
    if (isPublished && !postData.published_at) {
      postData.published_at = new Date().toISOString();
    }
    
    // Remove status field as we use published boolean
    delete postData.status;
    
    const { data, error } = await supabase
      .from('blog_posts')
      .insert(postData)
      .select()
      .single();
    
    if (error) throw error;
    
    return new Response(
      JSON.stringify(data),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error creating post:', error);
    throw error;
  }
}

async function updatePost(supabase: any, req: Request, id: string) {
  try {
    const postData = await req.json();
    
    // Sanitize HTML content and map to the correct database column
    if (postData.contentHtml) {
      const sanitizedContent = DOMPurify.sanitize(postData.contentHtml);
      postData.content = sanitizedContent; // Map to the required 'content' column
      postData.content_html = sanitizedContent; // Also populate content_html for consistency
      delete postData.contentHtml;
    }
    
    // Handle cover image
    if (postData.coverImage) {
      postData.image_url = postData.coverImage;
      delete postData.coverImage;
    }
    
    // Handle SEO fields
    if (postData.seoTitle) {
      postData.seo_title = postData.seoTitle;
      delete postData.seoTitle;
    }
    
    if (postData.metaDescription) {
      postData.meta_description = postData.metaDescription;
      delete postData.metaDescription;
    }
    
    // Update slug if title changed and slug not explicitly provided
    if (postData.title && !postData.slug) {
      postData.slug = slugify(postData.title, { lower: true, strict: true });
      
      // Check if slug exists for other posts
      const { data: existingPost } = await supabase
        .from('blog_posts')
        .select('slug')
        .eq('slug', postData.slug)
        .neq('id', id)
        .maybeSingle();
      
      // If slug exists, append a random string
      if (existingPost) {
        const randomString = Math.random().toString(36).substring(2, 8);
        postData.slug = `${postData.slug}-${randomString}`;
      }
    }
    
    // Handle published status
    if (postData.status) {
      const isPublished = postData.status === 'PUBLISHED';
      postData.published = isPublished;
      
      if (isPublished && !postData.published_at) {
        postData.published_at = new Date().toISOString();
      }
      
      delete postData.status;
    }
    
    // Set updated_at
    postData.updated_at = new Date().toISOString();
    
    const { data, error } = await supabase
      .from('blog_posts')
      .update(postData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    return new Response(
      JSON.stringify(data),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error updating post:', error);
    throw error;
  }
}

async function deletePost(supabase: any, id: string) {
  try {
    const { error } = await supabase
      .from('blog_posts')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
    
    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error deleting post:', error);
    throw error;
  }
}

async function handleImageUpload(supabase: any, req: Request) {
  try {
    console.log('Starting image upload...');
    
    const formData = await req.formData();
    const file = formData.get('image') as File;
    
    if (!file) {
      throw new Error('No image file provided');
    }
    
    console.log('File received:', file.name, file.type, file.size);
    
    // Convert File to Uint8Array for Deno environment
    const arrayBuffer = await file.arrayBuffer();
    const fileData = new Uint8Array(arrayBuffer);
    
    // Generate a unique filename
    const fileExt = file.name.split('.').pop();
    const fileName = `${Date.now()}-${Math.random().toString(36).substring(2, 15)}.${fileExt}`;
    const filePath = `blog/${fileName}`;
    
    console.log('Uploading to path:', filePath);
    
    // Upload to Supabase Storage with the correct data type
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('images')
      .upload(filePath, fileData, {
        contentType: file.type,
        upsert: false
      });
    
    if (uploadError) {
      console.error('Upload error:', uploadError);
      throw uploadError;
    }
    
    console.log('Upload successful:', uploadData);
    
    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('images')
      .getPublicUrl(filePath);
    
    console.log('Public URL:', publicUrl);
    
    return new Response(
      JSON.stringify({ url: publicUrl }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error uploading image:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Image upload failed',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

async function publishPost(supabase: any, id: string) {
  try {
    const { data, error } = await supabase
      .from('blog_posts')
      .update({
        published: true,
        published_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    return new Response(
      JSON.stringify(data),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error publishing post:', error);
    throw error;
  }
}

async function schedulePost(supabase: any, req: Request, id: string) {
  try {
    const { publishDate } = await req.json();
    
    if (!publishDate) {
      throw new Error('Publish date is required');
    }
    
    const { data, error } = await supabase
      .from('blog_posts')
      .update({
        published: false, // Will be published later
        published_at: new Date(publishDate).toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    return new Response(
      JSON.stringify(data),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error scheduling post:', error);
    throw error;
  }
}

async function getTags(supabase: any) {
  try {
    const { data, error } = await supabase
      .from('blog_tags')
      .select('*')
      .order('name');
    
    if (error) throw error;
    
    return new Response(
      JSON.stringify(data),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error fetching tags:', error);
    throw error;
  }
}