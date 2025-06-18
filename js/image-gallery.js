import { supabase } from '../config/supabase.js';

class ImageGallery {
  constructor(options = {}) {
    this.config = {
      container: '#image-gallery',
      imagesPath: '../assets/images/',
      lazyLoad: true,
      masonry: true,
      ...options
    };

    this.state = {
      images: [],
      loading: false,
      error: null,
      lastUpdated: null
    };

    this.init();
  }

  async init() {
    try {
      const container = document.querySelector(this.config.container);
      if (!container) throw new Error('Gallery container not found');

      // Setup intersection observer for lazy loading
      if (this.config.lazyLoad) {
        this.setupLazyLoading();
      }

      // Setup masonry layout if enabled
      if (this.config.masonry && window.Masonry) {
        this.masonry = new Masonry(container, {
          itemSelector: '.gallery-item',
          columnWidth: '.gallery-item',
          percentPosition: true
        });
      }

      // Load images
      await this.loadImages();

      // Add refresh button listener
      const refreshBtn = document.getElementById('refresh-gallery');
      if (refreshBtn) {
        refreshBtn.addEventListener('click', () => this.loadImages());
      }
    } catch (error) {
      console.error('Failed to initialize gallery:', error);
      this.showError('Gallerian alustus epäonnistui');
    }
  }

  async loadImages() {
    this.state.loading = true;
    this.state.error = null;

    try {
      let images = [];
      
      if (supabase) {
        // Try loading from Supabase first
        const { data, error } = await supabase
          .from('photos')
          .select('*')
          .order('created_at', { ascending: false });
          
        if (error) throw error;
        
        if (data && data.length > 0) {
          images = data.map(photo => ({
            id: photo.id,
            src: photo.image_url,
            title: photo.title,
            description: photo.description,
            tags: photo.tags || [],
            timestamp: photo.created_at
          }));
        }
      }
      
      // If no images from Supabase or error occurred, fall back to local images
      if (images.length === 0) {
        const response = await fetch(this.config.imagesPath + 'filelist.json');
        if (!response.ok) throw new Error('Failed to load image list');
        
        const data = await response.json();
        images = data.map(img => ({
          id: img.id || crypto.randomUUID(),
          src: this.config.imagesPath + img.filename,
          title: img.title || img.filename,
          description: img.description || '',
          tags: img.tags || [],
          timestamp: img.timestamp || new Date().toISOString()
        }));
      }
      
      this.state.images = images;
      this.state.lastUpdated = new Date().toISOString();
      
      // Update the UI
      await this.renderImages();
      
    } catch (error) {
      console.error('Error loading images:', error);
      this.state.error = error.message;
    } finally {
      this.state.loading = false;
    }
  }

  async renderImages() {
    const container = document.querySelector(this.config.container);
    if (!container) return;
    
    // Clear existing content
    container.innerHTML = '';
    
    // Create and append image elements
    this.state.images.forEach(image => {
      const item = document.createElement('div');
      item.className = 'gallery-item';
      
      const img = document.createElement('img');
      if (this.config.lazyLoad) {
        img.dataset.src = image.src;
        img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'; // Blank placeholder
      } else {
        img.src = image.src;
      }
      
      img.alt = image.title;
      img.className = 'gallery-image';
      
      // Add loading animation
      img.style.opacity = '0';
      img.style.transition = 'opacity 0.3s ease-in-out';
      
      img.onload = () => {
        img.style.opacity = '1';
        if (this.masonry) {
          this.masonry.layout();
        }
      };
      
      // Add image info
      const info = document.createElement('div');
      info.className = 'gallery-info';
      info.innerHTML = `
        <h3>${image.title}</h3>
        ${image.description ? `<p>${image.description}</p>` : ''}
        ${image.tags.length ? `
          <div class="gallery-tags">
            ${image.tags.map(tag => `<span class="gallery-tag">${tag}</span>`).join('')}
          </div>
        ` : ''}
      `;
      
      item.appendChild(img);
      item.appendChild(info);
      container.appendChild(item);
      
      // Observe for lazy loading if enabled
      if (this.config.lazyLoad && this.observer) {
        this.observer.observe(img);
      }
    });
  }

  setupLazyLoading() {
    if ('IntersectionObserver' in window) {
      this.observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            const img = entry.target;
            img.src = img.dataset.src;
            observer.unobserve(img);
          }
        });
      }, {
        root: null,
        rootMargin: '50px',
        threshold: 0.1
      });
    }
  }

  createGalleryItem(image) {
    const article = document.createElement('article');
    article.className = 'gallery-item';
    
    const img = document.createElement('img');
    if (this.config.lazyLoad) {
      img.classList.add('lazy');
      img.dataset.src = image.src;
      img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
    } else {
      img.src = image.src;
    }
    img.alt = image.title;
    
    const content = document.createElement('div');
    content.className = 'gallery-item-content';
    
    if (image.title) {
      const title = document.createElement('h3');
      title.textContent = image.title;
      content.appendChild(title);
    }
    
    if (image.description) {
      const desc = document.createElement('p');
      desc.textContent = image.description;
      content.appendChild(desc);
    }
    
    article.appendChild(img);
    article.appendChild(content);
    
    if (this.config.lazyLoad) {
      this.observer.observe(img);
    }
    
    return article;
  }

  updateUI() {
    const container = document.querySelector(this.config.container);
    if (!container) return;

    // Update loading state
    const loadingEl = document.querySelector('.loading');
    if (loadingEl) {
      loadingEl.style.display = this.state.loading ? 'block' : 'none';
    }

    // Update error state
    const errorEl = document.querySelector('.error-message');
    if (errorEl) {
      errorEl.textContent = this.state.error || '';
      errorEl.style.display = this.state.error ? 'block' : 'none';
    }

    // Update last updated timestamp
    const timestampEl = document.getElementById('last-updated-time');
    if (timestampEl && this.state.lastUpdated) {
      timestampEl.textContent = this.state.lastUpdated;
    }

    // Update gallery items
    if (!this.state.loading && !this.state.error) {
      container.innerHTML = '';
      this.state.images.forEach(image => {
        container.appendChild(this.createGalleryItem(image));
      });
    }
  }

  showError(message) {
    const errorEl = document.createElement('div');
    errorEl.className = 'error-message';
    errorEl.textContent = message;
    
    const container = document.querySelector(this.config.container);
    if (container) {
      container.insertAdjacentElement('beforebegin', errorEl);
    }
    
    setTimeout(() => errorEl.remove(), 5000);
  }
}

// Export for ES modules
export default ImageGallery;

// Make available globally
if (typeof window !== 'undefined') {
  window.ImageGallery = ImageGallery;
}
