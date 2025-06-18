// Photo Upload Functionality
class PhotoUploader {
  constructor() {
    this.supabase = null;
    this.isLoading = false;
    this.uploadProgress = 0;
    this.errorMessage = '';
    this.successMessage = '';
    this.showAddPhoto = false;
    this.editingPhotoId = null;
    this.newPhoto = {
      title: '',
      image_url: '',
      tags: ''
    };
    this.photos = [];
  }

  // Initialize Supabase client
  initSupabase() {
    try {
      const supabaseUrl = 'https://ucctolvpslfbpvknqrtv.supabase.co';
      const supabaseKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjY3RvbHZwc2xmYnB2a25xcnR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODQ0MzI5MDAsImV4cCI6MTk5OTgwODkwMH0.HvzGtHKqBDd6T9UVAkm0RHYEGpOGYFQjbiDYTNFrEYE';
      
      this.supabase = supabase.createClient(supabaseUrl, supabaseKey, {
        auth: {
          autoRefreshToken: true,
          persistSession: true,
          detectSessionInUrl: true
        }
      });
      
      console.log('Supabase client initialized');
      this.loadData();
      this.setupRealtime();
      
    } catch (error) {
      console.error('Error initializing Supabase:', error);
      this.errorMessage = 'Failed to connect to Supabase. Please check your configuration.';
    }
  }

  // Load photos from the database
  async loadData() {
    if (!this.supabase) return;
    
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      const { data: photos, error } = await this.supabase
        .from('photos')
        .select('*')
        .order('created_at', { ascending: false });
        
      if (error) throw error;
      this.photos = photos || [];
      
    } catch (error) {
      console.error('Error loading photos:', error);
      this.errorMessage = `Failed to load photos: ${error.message}`;
    } finally {
      this.isLoading = false;
    }
  }

  // Set up real-time updates
  setupRealtime() {
    if (!this.supabase) return;
    
    this.supabase
      .channel('photos')
      .on('postgres_changes', 
        { 
          event: '*',
          schema: 'public',
          table: 'photos'
        }, 
        (payload) => {
          console.log('Photo change detected:', payload);
          this.loadData();
        }
      )
      .subscribe();
  }

  // Handle file selection
  handleFileSelect(event) {
    const file = event.target.files[0];
    if (!file) return;
    
    // Check file type
    if (!file.type.match('image.*')) {
      this.errorMessage = 'Please select a valid image file (JPG, PNG, GIF, WebP)';
      return;
    }
    
    // Check file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      this.errorMessage = 'Image size must be less than 5MB';
      return;
    }
    
    // Create preview
    const reader = new FileReader();
    reader.onload = (e) => {
      this.newPhoto.image_url = e.target.result;
      
      // Auto-fill title if empty
      if (!this.newPhoto.title) {
        const fileName = file.name.replace(/\.[^/.]+$/, ''); // Remove extension
        this.newPhoto.title = fileName;
      }
    };
    reader.readAsDataURL(file);
  }

  // Close modal and reset form
  closeModal() {
    this.showAddPhoto = false;
    this.resetForm();
  }

  // Reset form
  resetForm() {
    this.newPhoto = { 
      title: '', 
      image_url: '', 
      tags: '' 
    };
    this.editingPhotoId = null;
    if (this.$refs?.fileInput) {
      this.$refs.fileInput.value = '';
    }
  }

  // Upload file to Supabase Storage
  async uploadFile(bucket, file, filePath) {
    try {
      const { data, error } = await this.supabase.storage
        .from(bucket)
        .upload(filePath, file, {
          cacheControl: '3600',
          upsert: false
        });
        
      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error uploading file:', error);
      throw error;
    }
  }

  // Get public URL for a file
  getPublicUrl(bucket, filePath) {
    const { data } = this.supabase.storage
      .from(bucket)
      .getPublicUrl(filePath);
    return data.publicUrl;
  }

  // Handle photo upload
  async handlePhotoUpload() {
    const file = this.$refs?.fileInput?.files?.[0] || null;
    if (!file && !this.newPhoto.image_url) return;
    
    this.isLoading = true;
    this.errorMessage = '';
    this.uploadProgress = 0;
    
    try {
      let imageUrl = this.newPhoto.image_url;
      
      // If there's a new file to upload
      if (file) {
        // Generate unique filename
        const fileExt = file.name.split('.').pop();
        const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`;
        const filePath = `photos/${fileName}`;
        
        // Upload file to storage
        await this.uploadFile('photos', file, filePath);
        
        // Get public URL
        imageUrl = this.getPublicUrl('photos', filePath);
      }
      
      // Add or update photo in the database
      let response;
      if (this.editingPhotoId) {
        // Update existing photo
        response = await this.supabase
          .from('photos')
          .update({
            title: this.newPhoto.title || 'Untitled',
            image_url: imageUrl,
            tags: this.newPhoto.tags ? 
              this.newPhoto.tags.split(',').map(tag => tag.trim()).filter(tag => tag) : 
              [],
            updated_at: new Date().toISOString()
          })
          .eq('id', this.editingPhotoId)
          .select();
      } else {
        // Add new photo
        response = await this.supabase
          .from('photos')
          .insert([{ 
            title: this.newPhoto.title || file.name.split('.')[0],
            image_url: imageUrl,
            tags: this.newPhoto.tags ? 
              this.newPhoto.tags.split(',').map(tag => tag.trim()).filter(tag => tag) : 
              []
          }])
          .select();
      }
      
      const { data, error } = response;
      if (error) throw error;
      
      if (!data || data.length === 0) {
        throw new Error('No data returned from server');
      }
      
      this.successMessage = this.editingPhotoId ? 
        'Photo updated successfully!' : 
        'Photo uploaded successfully!';
      
      if (this.editingPhotoId) {
        // Update the photo in the list
        this.photos = this.photos.map(photo => 
          photo.id === this.editingPhotoId ? { ...data[0] } : photo
        );
      } else {
        // Add the new photo to the beginning of the list
        this.photos = [data[0], ...this.photos];
      }
      
      // Reset form and close modal
      this.closeModal();
      
      // Auto-hide success message after 3 seconds
      setTimeout(() => {
        this.successMessage = '';
      }, 3000);
      
    } catch (error) {
      console.error('Error processing photo:', error);
      this.errorMessage = `Failed to ${this.editingPhotoId ? 'update' : 'upload'} photo: ${error.message}`;
    } finally {
      this.isLoading = false;
      this.uploadProgress = 0;
    }
  }

  // Edit photo
  editPhoto(photo) {
    this.editingPhotoId = photo.id;
    this.newPhoto = {
      title: photo.title,
      image_url: photo.image_url,
      tags: Array.isArray(photo.tags) ? photo.tags.join(', ') : ''
    };
    this.showAddPhoto = true;
    
    // Scroll to top of modal
    this.$nextTick(() => {
      const modal = document.querySelector('.modal-content');
      if (modal) modal.scrollTop = 0;
    });
  }

  // Delete photo
  async deletePhoto(photo) {
    if (!confirm('Are you sure you want to delete this photo? This action cannot be undone.')) return;
    
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // Extract file path from URL
      const url = new URL(photo.image_url);
      const pathParts = url.pathname.split('/');
      const filePath = pathParts[pathParts.length - 1];
      
      // Delete from storage
      const { error: storageError } = await this.supabase.storage
        .from('photos')
        .remove([filePath]);
      
      // Even if storage deletion fails, continue with database deletion
      // as the file might not exist in storage anymore
      
      // Delete from database
      const { error } = await this.supabase
        .from('photos')
        .delete()
        .eq('id', photo.id);
        
      if (error) throw error;
      
      // Update local state
      this.photos = this.photos.filter(p => p.id !== photo.id);
      this.successMessage = 'Photo deleted successfully!';
      
      // Hide success message after 3 seconds
      setTimeout(() => {
        this.successMessage = '';
      }, 3000);
      
    } catch (error) {
      console.error('Error deleting photo:', error);
      this.errorMessage = `Failed to delete photo: ${error.message}`;
    } finally {
      this.isLoading = false;
    }
  }
}

// Initialize the photo uploader when the page loads
document.addEventListener('DOMContentLoaded', () => {
  // Create a new instance of the photo uploader
  const photoUploader = new PhotoUploader();
  
  // Initialize Alpine.js component
  Alpine.data('photoUploader', () => ({
    ...photoUploader,
    
    // Initialize the component
    init() {
      // Set up Supabase
      this.initSupabase();
      
      // Set up keyboard shortcuts
      document.addEventListener('keydown', (e) => {
        // Close modal on Escape key
        if (e.key === 'Escape' && this.showAddPhoto) {
          this.closeModal();
        }
      });
    }
  }));
  
  // Start Alpine.js
  Alpine.start();
});
