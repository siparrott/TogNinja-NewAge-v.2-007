import { createClient } from 'npm:@supabase/supabase-js@2.39.7';
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { decode, create, verify } from 'npm:jsonwebtoken@9.0.2';
import { v4 as uuidv4 } from 'npm:uuid@9.0.1';
import sharp from 'npm:sharp@0.33.2';
import archiver from 'npm:archiver@6.0.1';

const JWT_SECRET = Deno.env.get('JWT_SECRET') || 'your-secret-key';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

// Create Supabase client
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const path = url.pathname.replace('/functions/v1/galleries', '');
    const method = req.method;

    // Public routes
    if (path.startsWith('/public/')) {
      return await handlePublicRoutes(req, path, method);
    }

    // Admin routes (require authentication)
    if (path.startsWith('/admin/')) {
      return await handleAdminRoutes(req, path, method);
    }

    return new Response(
      JSON.stringify({ error: 'Endpoint not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Galleries API Error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

async function handlePublicRoutes(req: Request, path: string, method: string) {
  // Get all public galleries
  if (path === '/public/galleries' && method === 'GET') {
    const url = new URL(req.url);
    const limit = url.searchParams.get('limit');
    return await getPublicGalleries(limit ? parseInt(limit) : undefined);
  }

  // Get gallery metadata
  if (path.match(/^\/public\/galleries\/[^\/]+$/) && method === 'GET') {
    const slug = path.split('/').pop();
    return await getPublicGallery(slug);
  }

  // Authenticate to gallery
  if (path.match(/^\/public\/galleries\/[^\/]+\/auth$/) && method === 'POST') {
    const slug = path.split('/')[3];
    return await authenticateGallery(req, slug);
  }

  // Get gallery images (requires JWT)
  if (path.match(/^\/public\/galleries\/[^\/]+\/images$/) && method === 'GET') {
    const slug = path.split('/')[3];
    return await getPublicGalleryImages(req, slug);
  }

  // Toggle image favorite (requires JWT)
  if (path.match(/^\/public\/images\/[^\/]+\/favorite$/) && method === 'POST') {
    const imageId = path.split('/')[3];
    return await toggleImageFavorite(req, imageId);
  }

  // Download gallery as ZIP (requires JWT)
  if (path.match(/^\/public\/galleries\/[^\/]+\/download$/) && method === 'GET') {
    const slug = path.split('/')[3];
    return await downloadGallery(req, slug);
  }

  return new Response(
    JSON.stringify({ error: 'Endpoint not found' }),
    { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

async function handleAdminRoutes(req: Request, path: string, method: string) {
  // Verify admin authentication
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: 'Authorization header required' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);

  if (authError || !user) {
    return new Response(
      JSON.stringify({ error: 'Invalid token' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // Check if user is admin
  const { data: adminUser } = await supabase
    .from('admin_users')
    .select('is_admin')
    .eq('user_id', user.id)
    .single();

  if (!adminUser?.is_admin) {
    return new Response(
      JSON.stringify({ error: 'Admin access required' }),
      { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  // Create gallery
  if (path === '/admin/galleries' && method === 'POST') {
    return await createGallery(req, user.id);
  }

  // Update gallery
  if (path.match(/^\/admin\/galleries\/[^\/]+$/) && method === 'PUT') {
    const galleryId = path.split('/').pop();
    return await updateGallery(req, galleryId);
  }

  // Delete gallery
  if (path.match(/^\/admin\/galleries\/[^\/]+$/) && method === 'DELETE') {
    const galleryId = path.split('/').pop();
    return await deleteGallery(galleryId);
  }

  // Upload images to gallery
  if (path.match(/^\/admin\/galleries\/[^\/]+\/upload$/) && method === 'POST') {
    const galleryId = path.split('/')[3];
    return await uploadGalleryImages(req, galleryId);
  }

  // Get gallery analytics
  if (path.match(/^\/admin\/analytics\/galleries\/[^\/]+$/) && method === 'GET') {
    const galleryId = path.split('/').pop();
    return await getGalleryAnalytics(galleryId);
  }

  return new Response(
    JSON.stringify({ error: 'Endpoint not found' }),
    { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  );
}

// PUBLIC ROUTE HANDLERS

// Get all public galleries
async function getPublicGalleries(limit?: number) {
  try {
    let query = supabase
      .from('galleries')
      .select('id, title, slug, description, cover_image, created_at, client_email')
      .or('password_hash.is.null,password_hash.eq.\'\'')
      .or('expires_at.is.null,expires_at.gt.now()')
      .order('created_at', { ascending: false });

    if (limit) {
      query = query.limit(limit);
    }

    const { data: galleries, error } = await query;

    if (error) throw error;

    // Format for public consumption
    const publicGalleries = galleries.map(gallery => ({
      id: gallery.id,
      title: gallery.title,
      slug: gallery.slug,
      description: gallery.description,
      coverImage: gallery.cover_image,
      clientEmail: gallery.client_email,
      createdAt: gallery.created_at,
      isPasswordProtected: false, // Only public galleries are returned
      downloadEnabled: true // Will be checked per gallery on access
    }));

    return new Response(
      JSON.stringify(publicGalleries),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error getting public galleries:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to fetch galleries' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}

async function getPublicGallery(slug: string) {
  try {
    const { data: gallery, error } = await supabase
      .from('galleries')
      .select('id, title, slug, cover_image, password_hash, download_enabled, created_at')
      .eq('slug', slug)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return new Response(
          JSON.stringify({ error: 'Gallery not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      throw error;
    }

    // Return only necessary information
    return new Response(
      JSON.stringify({
        id: gallery.id,
        title: gallery.title,
        slug: gallery.slug,
        coverImage: gallery.cover_image,
        isPasswordProtected: !!gallery.password_hash,
        downloadEnabled: gallery.download_enabled,
        createdAt: gallery.created_at
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error getting public gallery:', error);
    throw error;
  }
}

async function authenticateGallery(req: Request, slug: string) {
  try {
    const { email, password } = await req.json();

    if (!email) {
      return new Response(
        JSON.stringify({ error: 'Email is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get the gallery
    const { data: gallery, error } = await supabase
      .from('galleries')
      .select('id, password_hash')
      .eq('slug', slug)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return new Response(
          JSON.stringify({ error: 'Gallery not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      throw error;
    }

    // Check password if gallery is password protected
    if (gallery.password_hash) {
      if (!password) {
        return new Response(
          JSON.stringify({ error: 'Password is required' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Verify password (in a real implementation, use bcrypt.compare)
      const passwordMatches = await verifyPassword(password, gallery.password_hash);
      if (!passwordMatches) {
        return new Response(
          JSON.stringify({ error: 'Invalid password' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    // Create or get visitor
    let visitor;
    const { data: existingVisitor } = await supabase
      .from('gallery_visitors')
      .select('id, access_token')
      .eq('gallery_id', gallery.id)
      .eq('email', email)
      .maybeSingle();

    if (existingVisitor) {
      visitor = existingVisitor;
    } else {
      const { data: newVisitor, error: visitorError } = await supabase
        .from('gallery_visitors')
        .insert({
          gallery_id: gallery.id,
          email: email,
          access_token: uuidv4()
        })
        .select()
        .single();

      if (visitorError) throw visitorError;
      visitor = newVisitor;
    }

    // Generate JWT
    const token = create(
      { 
        sub: visitor.id,
        galleryId: gallery.id,
        accessToken: visitor.access_token
      },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    return new Response(
      JSON.stringify({ token }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error authenticating to gallery:', error);
    throw error;
  }
}

async function getPublicGalleryImages(req: Request, slug: string) {
  try {
    // Verify JWT
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization header required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const token = authHeader.replace('Bearer ', '');
    let payload;
    try {
      payload = verify(token, JWT_SECRET);
    } catch (jwtError) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get the gallery
    const { data: gallery, error: galleryError } = await supabase
      .from('galleries')
      .select('id')
      .eq('slug', slug)
      .single();

    if (galleryError) {
      if (galleryError.code === 'PGRST116') {
        return new Response(
          JSON.stringify({ error: 'Gallery not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      throw galleryError;
    }

    // Verify that the JWT is for this gallery
    if (payload.galleryId !== gallery.id) {
      return new Response(
        JSON.stringify({ error: 'Invalid token for this gallery' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get the images
    const { data: images, error: imagesError } = await supabase
      .from('gallery_images')
      .select('*')
      .eq('gallery_id', gallery.id)
      .order('order_index', { ascending: true });

    if (imagesError) throw imagesError;

    // Get favorites for this visitor
    const { data: favorites, error: favoritesError } = await supabase
      .from('image_actions')
      .select('image_id')
      .eq('visitor_id', payload.sub)
      .eq('action', 'FAVORITE');

    if (favoritesError) throw favoritesError;

    // Mark favorites
    const favoriteImageIds = new Set(favorites.map(f => f.image_id));
    const imagesWithFavorites = images.map(image => ({
      ...image,
      isFavorite: favoriteImageIds.has(image.id)
    }));

    return new Response(
      JSON.stringify(imagesWithFavorites),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error getting public gallery images:', error);
    throw error;
  }
}

async function toggleImageFavorite(req: Request, imageId: string) {
  try {
    // Verify JWT
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization header required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const token = authHeader.replace('Bearer ', '');
    let payload;
    try {
      payload = verify(token, JWT_SECRET);
    } catch (jwtError) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if image exists and get its gallery_id
    const { data: image, error: imageError } = await supabase
      .from('gallery_images')
      .select('gallery_id')
      .eq('id', imageId)
      .single();

    if (imageError) {
      if (imageError.code === 'PGRST116') {
        return new Response(
          JSON.stringify({ error: 'Image not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      throw imageError;
    }

    // Verify that the JWT is for this gallery
    if (payload.galleryId !== image.gallery_id) {
      return new Response(
        JSON.stringify({ error: 'Invalid token for this gallery' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if the image is already favorited
    const { data: existingFavorite, error: favoriteError } = await supabase
      .from('image_actions')
      .select('id')
      .eq('visitor_id', payload.sub)
      .eq('image_id', imageId)
      .eq('action', 'FAVORITE')
      .maybeSingle();

    if (favoriteError) throw favoriteError;

    if (existingFavorite) {
      // Remove favorite
      const { error: deleteError } = await supabase
        .from('image_actions')
        .delete()
        .eq('id', existingFavorite.id);

      if (deleteError) throw deleteError;

      return new Response(
        JSON.stringify({ isFavorite: false }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    } else {
      // Add favorite
      const { error: insertError } = await supabase
        .from('image_actions')
        .insert({
          visitor_id: payload.sub,
          image_id: imageId,
          action: 'FAVORITE'
        });

      if (insertError) throw insertError;

      return new Response(
        JSON.stringify({ isFavorite: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
  } catch (error) {
    console.error('Error toggling image favorite:', error);
    throw error;
  }
}

async function downloadGallery(req: Request, slug: string) {
  try {
    // Verify JWT
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Authorization header required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const token = authHeader.replace('Bearer ', '');
    let payload;
    try {
      payload = verify(token, JWT_SECRET);
    } catch (jwtError) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get the gallery
    const { data: gallery, error: galleryError } = await supabase
      .from('galleries')
      .select('id, title, download_enabled')
      .eq('slug', slug)
      .single();

    if (galleryError) {
      if (galleryError.code === 'PGRST116') {
        return new Response(
          JSON.stringify({ error: 'Gallery not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
      throw galleryError;
    }

    // Verify that the JWT is for this gallery
    if (payload.galleryId !== gallery.id) {
      return new Response(
        JSON.stringify({ error: 'Invalid token for this gallery' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check if downloads are enabled
    if (!gallery.download_enabled) {
      return new Response(
        JSON.stringify({ error: 'Downloads are disabled for this gallery' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get the images
    const { data: images, error: imagesError } = await supabase
      .from('gallery_images')
      .select('id, display_url, filename')
      .eq('gallery_id', gallery.id)
      .order('order_index', { ascending: true });

    if (imagesError) throw imagesError;

    if (images.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No images found in this gallery' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create a ZIP file
    const archive = archiver('zip', {
      zlib: { level: 5 }
    });

    // Set up the response
    const headers = {
      ...corsHeaders,
      'Content-Type': 'application/zip',
      'Content-Disposition': `attachment; filename="${gallery.title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.zip"`
    };

    // Create a ReadableStream from the archive
    const { readable, writable } = new TransformStream();
    const writer = writable.getWriter();

    // Pipe archive data to the writer
    archive.on('data', (chunk) => {
      writer.write(chunk);
    });

    archive.on('end', () => {
      writer.close();
    });

    // Add each image to the archive
    for (const image of images) {
      // Download the image
      const response = await fetch(image.display_url);
      const imageBuffer = await response.arrayBuffer();
      
      // Add to archive
      archive.append(Buffer.from(imageBuffer), { name: image.filename });
      
      // Log download action
      await supabase
        .from('image_actions')
        .insert({
          visitor_id: payload.sub,
          image_id: image.id,
          action: 'DOWNLOAD'
        });
    }

    // Finalize the archive
    archive.finalize();

    return new Response(
      readable,
      { headers }
    );
  } catch (error) {
    console.error('Error downloading gallery:', error);
    throw error;
  }
}

// ADMIN ROUTE HANDLERS

async function createGallery(req: Request, userId: string) {
  try {
    const { title, password, downloadEnabled } = await req.json();

    if (!title) {
      return new Response(
        JSON.stringify({ error: 'Title is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Hash password if provided
    let passwordHash = null;
    if (password) {
      passwordHash = await hashPassword(password);
    }

    // Create gallery
    const { data: gallery, error } = await supabase
      .from('galleries')
      .insert({
        title,
        password_hash: passwordHash,
        download_enabled: downloadEnabled !== undefined ? downloadEnabled : true,
        client_id: userId
      })
      .select()
      .single();

    if (error) throw error;

    return new Response(
      JSON.stringify(gallery),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error creating gallery:', error);
    throw error;
  }
}

async function updateGallery(req: Request, galleryId: string) {
  try {
    const { title, password, downloadEnabled, coverImage } = await req.json();

    if (!title) {
      return new Response(
        JSON.stringify({ error: 'Title is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Prepare update data
    const updateData: any = {
      title,
      download_enabled: downloadEnabled,
      updated_at: new Date().toISOString()
    };

    // Hash password if provided
    if (password) {
      updateData.password_hash = await hashPassword(password);
    }

    // Update cover image if provided
    if (coverImage) {
      updateData.cover_image = coverImage;
    }

    // Update gallery
    const { data: gallery, error } = await supabase
      .from('galleries')
      .update(updateData)
      .eq('id', galleryId)
      .select()
      .single();

    if (error) throw error;

    return new Response(
      JSON.stringify(gallery),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error updating gallery:', error);
    throw error;
  }
}

async function deleteGallery(galleryId: string) {
  try {
    // Delete gallery (cascade will delete images, visitors, and actions)
    const { error } = await supabase
      .from('galleries')
      .delete()
      .eq('id', galleryId);

    if (error) throw error;

    // Delete files from storage
    // This would need to be implemented based on your storage structure

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error deleting gallery:', error);
    throw error;
  }
}

async function uploadGalleryImages(req: Request, galleryId: string) {
  try {
    // Parse form data
    const formData = await req.formData();
    const files = formData.getAll('images');

    if (!files || files.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No images provided' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Process each file
    const uploadedImages = [];
    for (const file of files) {
      if (!(file instanceof File)) {
        continue;
      }

      // Generate unique filename
      const originalName = file.name;
      const fileExt = originalName.split('.').pop();
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(2, 15)}.${fileExt}`;
      
      // Get file buffer
      const arrayBuffer = await file.arrayBuffer();
      const buffer = new Uint8Array(arrayBuffer);

      // Process with sharp
      const originalBuffer = buffer;
      const displayBuffer = await sharp(buffer)
        .resize({ width: 1920, height: 1920, fit: 'inside' })
        .toBuffer();
      const thumbBuffer = await sharp(buffer)
        .resize({ width: 400, height: 400, fit: 'inside' })
        .toBuffer();

      // Upload to Supabase Storage
      const originalPath = `${galleryId}/original/${fileName}`;
      const displayPath = `${galleryId}/display/${fileName}`;
      const thumbPath = `${galleryId}/thumb/${fileName}`;

      // Upload original
      const { error: originalError } = await supabase.storage
        .from('galleries')
        .upload(originalPath, originalBuffer, {
          contentType: file.type
        });

      if (originalError) throw originalError;

      // Upload display version
      const { error: displayError } = await supabase.storage
        .from('galleries')
        .upload(displayPath, displayBuffer, {
          contentType: file.type
        });

      if (displayError) throw displayError;

      // Upload thumbnail
      const { error: thumbError } = await supabase.storage
        .from('galleries')
        .upload(thumbPath, thumbBuffer, {
          contentType: file.type
        });

      if (thumbError) throw thumbError;

      // Get public URLs
      const { data: { publicUrl: originalUrl } } = supabase.storage
        .from('galleries')
        .getPublicUrl(originalPath);

      const { data: { publicUrl: displayUrl } } = supabase.storage
        .from('galleries')
        .getPublicUrl(displayPath);

      const { data: { publicUrl: thumbUrl } } = supabase.storage
        .from('galleries')
        .getPublicUrl(thumbPath);

      // Get next order index
      const { data: maxOrderIndex } = await supabase
        .from('gallery_images')
        .select('order_index')
        .eq('gallery_id', galleryId)
        .order('order_index', { ascending: false })
        .limit(1)
        .single();

      const orderIndex = maxOrderIndex ? maxOrderIndex.order_index + 1 : 0;

      // Extract EXIF data for captured_at (if available)
      let capturedAt = null;
      // This would require additional libraries to extract EXIF data

      // Create database record
      const { data: image, error: imageError } = await supabase
        .from('gallery_images')
        .insert({
          gallery_id: galleryId,
          original_url: originalUrl,
          display_url: displayUrl,
          thumb_url: thumbUrl,
          filename: originalName,
          size_bytes: file.size,
          content_type: file.type,
          captured_at: capturedAt,
          order_index: orderIndex,
          uploaded_at: new Date().toISOString(),
          shared_to_togninja: false
        })
        .select()
        .single();

      if (imageError) throw imageError;

      uploadedImages.push(image);

      // If this is the first image, set it as the cover image if the gallery doesn't have one
      if (uploadedImages.length === 1) {
        const { data: gallery } = await supabase
          .from('galleries')
          .select('cover_image')
          .eq('id', galleryId)
          .single();

        if (!gallery.cover_image) {
          await supabase
            .from('galleries')
            .update({ cover_image: thumbUrl })
            .eq('id', galleryId);
        }
      }
    }

    return new Response(
      JSON.stringify(uploadedImages),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error uploading gallery images:', error);
    throw error;
  }
}

async function getGalleryAnalytics(galleryId: string) {
  try {
    // Get visitor count
    const { count: visitorCount, error: visitorError } = await supabase
      .from('gallery_visitors')
      .select('id', { count: 'exact', head: true })
      .eq('gallery_id', galleryId);

    if (visitorError) throw visitorError;

    // Get action counts
    const { data: actionCounts, error: actionError } = await supabase
      .from('image_actions')
      .select('action, count')
      .eq('gallery_id', galleryId)
      .group('action');

    if (actionError) throw actionError;

    // Get daily stats for the last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const { data: dailyStats, error: dailyError } = await supabase
      .from('gallery_daily_stats')
      .select('date, unique_visitors, total_views, total_favorites, total_downloads')
      .eq('gallery_id', galleryId)
      .gte('date', thirtyDaysAgo.toISOString().split('T')[0])
      .order('date', { ascending: true });

    if (dailyError) throw dailyError;

    // Get top images
    const { data: topImages, error: topImagesError } = await supabase
      .from('image_actions')
      .select(`
        image_id,
        count(*) as action_count,
        gallery_images!inner(thumb_url)
      `)
      .eq('gallery_id', galleryId)
      .group('image_id, gallery_images.thumb_url')
      .order('action_count', { ascending: false })
      .limit(10);

    if (topImagesError) throw topImagesError;

    // Format the response
    const viewCount = actionCounts.find(a => a.action === 'VIEW')?.count || 0;
    const favoriteCount = actionCounts.find(a => a.action === 'FAVORITE')?.count || 0;
    const downloadCount = actionCounts.find(a => a.action === 'DOWNLOAD')?.count || 0;

    const formattedDailyStats = dailyStats.map(day => ({
      date: day.date,
      views: day.total_views,
      favorites: day.total_favorites,
      downloads: day.total_downloads
    }));

    const formattedTopImages = topImages.map(img => ({
      imageId: img.image_id,
      thumbUrl: img.gallery_images.thumb_url,
      views: 0, // Would need additional queries to break down by action type
      favorites: 0,
      downloads: 0
    }));

    return new Response(
      JSON.stringify({
        uniqueVisitors: visitorCount,
        totalViews: viewCount,
        totalFavorites: favoriteCount,
        totalDownloads: downloadCount,
        dailyStats: formattedDailyStats,
        topImages: formattedTopImages
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error getting gallery analytics:', error);
    throw error;
  }
}

// HELPER FUNCTIONS

async function hashPassword(password: string): Promise<string> {
  // In a real implementation, this would use bcrypt
  // For now, we'll just use a simple hash
  const encoder = new TextEncoder();
  const data = encoder.encode(password);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  // In a real implementation, this would use bcrypt.compare
  // For now, we'll just compare the hashes
  const newHash = await hashPassword(password);
  return newHash === hash;
}