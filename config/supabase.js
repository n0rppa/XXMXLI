/**
 * Supabase client configuration
 */

// Supabase client URL and anon key
const SUPABASE_URL = 'https://ucctolvpslfbpvknqrtv.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjY3RvbHZwc2xmYnB2a25xcnR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODQ0MzI5MDAsImV4cCI6MTk5OTgwODkwMH0.HvzGtHKqBDd6T9UVAkm0RHYEGpOGYFQjbiDYTNFrEYE';

// Initialize Supabase client
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    autoRefreshToken: true,
    persistSession: true
  }
});

// Export the initialized client
export { supabaseClient as supabase };

// Storage functions
export const storage = {
  // Upload a file to storage
  async uploadFile(bucket, path, file) {
    const { data, error } = await supabaseClient.storage
      .from(bucket)
      .upload(path, file, {
        cacheControl: '3600',
        upsert: false
      });
    return { data, error };
  },

  // Get public URL for a file
  getPublicUrl(bucket, path) {
    const { data } = supabaseClient.storage
      .from(bucket)
      .getPublicUrl(path);
    return data?.publicUrl || '';
  },

  // List files in a bucket
  async listFiles(bucket, path = '') {
    const { data, error } = await supabaseClient.storage
      .from(bucket)
      .list(path);
    return { data, error };
  }
};

// Database functions
export const db = {
  // Fetch photos from the database
  async getPhotos() {
    const { data, error } = await supabaseClient
      .from('photos')
      .select('*')
      .order('created_at', { ascending: false });
    return { data, error };
  },

  // Insert a new photo
  async insertPhoto(photoData) {
    const { data, error } = await supabaseClient
      .from('photos')
      .insert([photoData])
      .select();
    return { data, error };
  },

  // Delete a photo
  async deletePhoto(id) {
    const { error } = await supabaseClient
      .from('photos')
      .delete()
      .eq('id', id);
    return { error };
  }
};
