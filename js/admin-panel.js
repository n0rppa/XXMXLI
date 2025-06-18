// Admin Panel JavaScript
import { supabase, db, storage } from './supabase-config.js';

document.addEventListener('alpine:init', () => {
  Alpine.data('adminPanel', () => ({
    // State
    currentTab: 'photos',
    isLoading: false,
    errorMessage: '',
    successMessage: '',
    showAddPhoto: false,
    showAddTrack: false,
    
    // Data
    users: [],
    photos: [],
    tracks: [],
    
    // New item forms
    newPhoto: {
      title: '',
      description: '',
      tags: '',
      image_url: '',
      image_file: null
    },
    
    newTrack: {
      title: '',
      artist: '',
      duration: 0,
      audio_file: null,
      cover_image: null,
      tags: ''
    },
    
    // Initialize the admin panel
    async init() {
      await this.checkAuth();
      await this.loadData();
      
      // Set up event listeners
      this.$watch('currentTab', () => this.loadData());
    },
    
    // Check if user is authenticated
    async checkAuth() {
      const { data: { user }, error } = await supabase.auth.getUser();
      
      if (error || !user) {
        window.location.href = '/admin/login.html';
        return;
      }
      
      // Check if user has admin role
      const { data: userData, error: userError } = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .single();
        
      if (userError || userData.role !== 'admin') {
        window.location.href = '/admin/unauthorized.html';
        return;
      }
    },
    
    // Load data based on current tab
    async loadData() {
      this.isLoading = true;
      this.errorMessage = '';
      
      try {
        switch (this.currentTab) {
          case 'users':
            await this.loadUsers();
            break;
          case 'photos':
            await this.loadPhotos();
            break;
          case 'tracks':
            await this.loadTracks();
            break;
        }
      } catch (error) {
        console.error('Error loading data:', error);
        this.errorMessage = 'Error loading data. Please try again.';
      } finally {
        this.isLoading = false;
      }
    },
    
    // Load users
    async loadUsers() {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false });
        
      if (error) throw error;
      this.users = data || [];
    },
    
    // Load photos
    async loadPhotos() {
      const { data, error } = await db.getPhotos();
      if (error) throw error;
      this.photos = data || [];
    },
    
    // Load tracks
    async loadTracks() {
      const { data, error } = await supabase
        .from('tracks')
        .select('*')
        .order('created_at', { ascending: false });
        
      if (error) throw error;
      this.tracks = data || [];
    },
    
    // Handle photo file selection
    handlePhotoFileSelect(event) {
      const file = event.target.files[0];
      if (!file) return;
      
      // Validate file type
      const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
      if (!validTypes.includes(file.type)) {
        this.errorMessage = 'Invalid file type. Please upload an image (JPEG, PNG, GIF, or WebP).';
        return;
      }
      
      // Validate file size (5MB max)
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (file.size > maxSize) {
        this.errorMessage = 'File is too large. Maximum size is 5MB.';
        return;
      }
      
      // Create preview URL
      this.newPhoto.image_url = URL.createObjectURL(file);
      this.newPhoto.image_file = file;
    },
    
    // Upload photo
    async uploadPhoto() {
      if (!this.newPhoto.image_file) {
        this.errorMessage = 'Please select an image file.';
        return;
      }
      
      this.isLoading = true;
      this.errorMessage = '';
      this.successMessage = '';
      
      try {
        // Upload the file to storage
        const fileExt = this.newPhoto.image_file.name.split('.').pop();
        const fileName = `${Math.random().toString(36).substring(2, 15)}.${fileExt}`;
        const filePath = `photos/${fileName}`;
        
        const { error: uploadError } = await storage.uploadFile('images', filePath, this.newPhoto.image_file);
        
        if (uploadError) throw uploadError;
        
        // Get the public URL
        const imageUrl = storage.getPublicUrl('images', filePath);
        
        // Save photo metadata to database
        const photoData = {
          title: this.newPhoto.title,
          description: this.newPhoto.description,
          tags: this.newPhoto.tags.split(',').map(tag => tag.trim()).filter(tag => tag),
          image_url: imageUrl,
          user_id: (await supabase.auth.getUser()).data.user.id
        };
        
        const { error: dbError } = await db.insertPhoto(photoData);
        
        if (dbError) throw dbError;
        
        // Reset form and show success message
        this.successMessage = 'Photo uploaded successfully!';
        this.showAddPhoto = false;
        this.resetPhotoForm();
        
        // Reload photos
        await this.loadPhotos();
      } catch (error) {
        console.error('Error uploading photo:', error);
        this.errorMessage = error.message || 'Error uploading photo. Please try again.';
      } finally {
        this.isLoading = false;
      }
    },
    
    // Delete photo
    async deletePhoto(photo) {
      if (!confirm('Are you sure you want to delete this photo? This action cannot be undone.')) {
        return;
      }
      
      this.isLoading = true;
      this.errorMessage = '';
      
      try {
        // Delete from storage
        const filePath = photo.image_url.split('/').pop();
        const { error: storageError } = await supabase.storage
          .from('images')
          .remove([`photos/${filePath}`]);
          
        if (storageError) throw storageError;
        
        // Delete from database
        const { error: dbError } = await db.deletePhoto(photo.id);
        if (dbError) throw dbError;
        
        // Remove from local state
        this.photos = this.photos.filter(p => p.id !== photo.id);
        this.successMessage = 'Photo deleted successfully!';
      } catch (error) {
        console.error('Error deleting photo:', error);
        this.errorMessage = error.message || 'Error deleting photo. Please try again.';
      } finally {
        this.isLoading = false;
      }
    },
    
    // Reset photo form
    resetPhotoForm() {
      this.newPhoto = {
        title: '',
        description: '',
        tags: '',
        image_url: '',
        image_file: null
      };
      
      // Clear file input
      const fileInput = this.$refs.photoFileInput;
      if (fileInput) fileInput.value = '';
    },
    
    // Sign out
    async signOut() {
      await supabase.auth.signOut();
      window.location.href = '/admin/login.html';
    },
    
    // Format date
    formatDate(dateString) {
      if (!dateString) return '';
      return new Date(dateString).toLocaleString('fi-FI');
    }
  }));
});
