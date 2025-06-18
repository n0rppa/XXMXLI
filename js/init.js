// Initialize components when DOM is loaded
document.addEventListener('DOMContentLoaded', async () => {
  // Initialize music player if on music page
  if (document.querySelector('#music-player')) {
    const player = new MusicPlayer({
      container: '#music-player',
      audioPath: '../assets/audio/'
    });
    window.musicPlayer = player;
  }

  // Initialize image gallery if on photos page
  if (document.querySelector('#image-gallery')) {
    const gallery = new ImageGallery({
      container: '#image-gallery',
      imagesPath: '../assets/images/',
      lazyLoad: true,
      masonry: true
    });
    window.imageGallery = gallery;
  }

  // Initialize theme
  const theme = {
    init() {
      const savedTheme = localStorage.getItem('theme') || 
        (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
      this.setTheme(savedTheme);
      
      document.getElementById('theme-toggle')?.addEventListener('click', () => this.toggle());
    },
    
    setTheme(mode) {
      document.documentElement.setAttribute('data-theme', mode);
      localStorage.setItem('theme', mode);
      const themeToggle = document.getElementById('theme-toggle');
      if (themeToggle) {
        themeToggle.textContent = mode === 'dark' ? '🌕' : '🌓';
      }
    },
    
    toggle() {
      const current = document.documentElement.getAttribute('data-theme');
      this.setTheme(current === 'dark' ? 'light' : 'dark');
    }
  };

  theme.init();
});
