class MusicPlayerComponent {
  constructor(selector, options = {}) {
    // Configuration
    this.config = {
      container: selector,
      audioPath: 'assets/audio/',
      showPlaylist: true,
      theme: 'dark', // 'dark' or 'light'
      visualizer: true,
      ...options
    };
    
    // Player instance
    this.player = null;
    
    // DOM elements
    this.elements = {
      container: null,
      controls: {},
      progress: {},
      time: {},
      playlist: {},
      visualizer: null
    };
    
    // Initialize
    this.init();
  }
  
  // Initialize the component
  init() {
    // Create the player instance
    this.player = new MusicPlayer({
      audioPath: this.config.audioPath,
      debug: false
    });
    
    // Create the player UI
    this.createUI();
    
    // Set up event listeners
    this.setupEventListeners();
    
    // Load the first track when player is ready
    this.player.on('playlistLoaded', () => {
      if (this.player.state.playlist.length > 0) {
        this.updatePlaylist();
        this.updateTrackInfo(this.player.state.currentTrack);
      }
    });
    
    // Handle track changes
    this.player.on('trackChanged', ({ track }) => {
      this.updateTrackInfo(track);
      this.highlightCurrentTrack();
    });
    
    // Handle play/pause events
    this.player.on('play', () => this.updatePlayButton(true));
    this.player.on('pause', () => this.updatePlayButton(false));
    
    // Handle time updates
    this.player.on('timeUpdate', ({ currentTime, duration }) => {
      this.updateProgress(currentTime, duration);
    });
    
    // Handle volume changes
    this.player.on('volumeChange', ({ volume }) => {
      this.updateVolumeIcon(volume);
    });
    
    // Handle errors
    this.player.on('error', ({ error }) => {
      this.showError(error);
    });
  }
  
  // Create the player UI
  createUI() {
    const container = document.querySelector(this.config.container);
    if (!container) {
      console.error(`Container ${this.config.container} not found`);
      return;
    }
    
    // Clear container
    container.innerHTML = '';
    
    // Add theme class
    container.className = `music-player ${this.config.theme}-theme`;
    
    // Create player HTML
    container.innerHTML = `
      <div class="player-container">
        <!-- Track Info -->
        <div class="track-info">
          <div class="cover-art">
            <img src="assets/images/deow (12).jpg" alt="Album Art" class="cover-image" onerror="this.src='assets/images/deow (12).jpg';">
          </div>
          <div class="track-details">
            <div class="track-title">Select a track</div>
            <div class="track-artist">-</div>
          </div>
        </div>
        
        <!-- Progress Bar -->
        <div class="progress-container">
          <div class="time current">0:00</div>
          <div class="progress-bar">
            <div class="progress"></div>
            <div class="progress-handle"></div>
          </div>
          <div class="time total">0:00</div>
        </div>
        
        <!-- Controls -->
        <div class="controls">
          <button class="control-btn shuffle" title="Shuffle">
            <i class="fas fa-random"></i>
          </button>
          <button class="control-btn prev" title="Previous">
            <i class="fas fa-step-backward"></i>
          </button>
          <button class="control-btn play" title="Play">
            <i class="fas fa-play"></i>
          </button>
          <button class="control-btn next" title="Next">
            <i class="fas fa-step-forward"></i>
          </button>
          <button class="control-btn repeat" title="Repeat">
            <i class="fas fa-redo"></i>
          </button>
          
          <div class="volume-container">
            <button class="control-btn volume-btn" title="Mute">
              <i class="fas fa-volume-up"></i>
            </button>
            <div class="volume-slider">
              <div class="volume-level"></div>
              <div class="volume-handle"></div>
            </div>
          </div>
        </div>
        
        <!-- Visualizer -->
        ${this.config.visualizer ? '<div class="visualizer"></div>' : ''}
      </div>
      
      <!-- Playlist -->
      ${this.config.showPlaylist ? `
        <div class="playlist-container">
          <div class="playlist-header">
            <h3>Playlist</h3>
            <div class="playlist-info">
              <span class="track-count">0 tracks</span>
              <span class="playlist-duration">0:00</span>
            </div>
          </div>
          <div class="playlist"></div>
        </div>
      ` : ''}
    `;
    
    // Store references to DOM elements
    this.elements.container = container;
    this.elements.controls = {
      play: container.querySelector('.play'),
      prev: container.querySelector('.prev'),
      next: container.querySelector('.next'),
      shuffle: container.querySelector('.shuffle'),
      repeat: container.querySelector('.repeat'),
      volume: container.querySelector('.volume-btn')
    };
    
    this.elements.progress = {
      bar: container.querySelector('.progress-bar'),
      progress: container.querySelector('.progress-bar .progress'),
      handle: container.querySelector('.progress-bar .progress-handle')
    };
    
    this.elements.time = {
      current: container.querySelector('.time.current'),
      total: container.querySelector('.time.total')
    };
    
    this.elements.trackInfo = {
      title: container.querySelector('.track-title'),
      artist: container.querySelector('.track-artist'),
      cover: container.querySelector('.cover-image')
    };
    
    this.elements.volume = {
      slider: container.querySelector('.volume-slider'),
      level: container.querySelector('.volume-level'),
      handle: container.querySelector('.volume-handle')
    };
    
    if (this.config.visualizer) {
      this.elements.visualizer = container.querySelector('.visualizer');
    }
    
    if (this.config.showPlaylist) {
      this.elements.playlist = {
        container: container.querySelector('.playlist'),
        trackCount: container.querySelector('.track-count'),
        duration: container.querySelector('.playlist-duration')
      };
    }
  }
  
  // Set up event listeners
  setupEventListeners() {
    // Play/Pause button
    this.elements.controls.play.addEventListener('click', () => {
      this.player.togglePlay();
    });
    
    // Previous track button
    this.elements.controls.prev.addEventListener('click', () => {
      this.player.previous();
    });
    
    // Next track button
    this.elements.controls.next.addEventListener('click', () => {
      this.player.next();
    });
    
    // Shuffle button
    this.elements.controls.shuffle.addEventListener('click', () => {
      this.player.toggleShuffle();
      this.toggleActiveClass(this.elements.controls.shuffle, 'active');
    });
    
    // Repeat button
    this.elements.controls.repeat.addEventListener('click', () => {
      this.player.toggleRepeat();
      this.updateRepeatButton();
    });
    
    // Volume button
    this.elements.controls.volume.addEventListener('click', () => {
      this.player.toggleMute();
    });
    
    // Progress bar click
    this.elements.progress.bar.addEventListener('click', (e) => {
      if (!this.player.state.currentTrack) return;
      
      const rect = this.elements.progress.bar.getBoundingClientRect();
      const pos = (e.clientX - rect.left) / rect.width;
      const time = pos * this.player.state.duration;
      
      this.player.seek(time);
    });
    
    // Volume slider
    if (this.elements.volume.slider) {
      this.elements.volume.slider.addEventListener('click', (e) => {
        const rect = this.elements.volume.slider.getBoundingClientRect();
        const volume = Math.min(1, Math.max(0, (e.clientX - rect.left) / rect.width));
        
        this.player.setVolume(volume);
      });
    }
    
    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      // Space to play/pause (only if not focused on input/textarea/select)
      if (e.code === 'Space' && !['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement.tagName)) {
        e.preventDefault();
        this.player.togglePlay();
      }
      
      // Left/Right arrow keys for seeking
      if (e.code === 'ArrowLeft' && this.player.state.currentTrack) {
        e.preventDefault();
        this.player.seek(Math.max(0, this.player.state.currentTime - 5));
      } else if (e.code === 'ArrowRight' && this.player.state.currentTrack) {
        e.preventDefault();
        this.player.seek(Math.min(this.player.state.duration, this.player.state.currentTime + 5));
      }
      
      // M key to mute/unmute
      if (e.code === 'KeyM') {
        e.preventDefault();
        this.player.toggleMute();
      }
    });
  }
  
  // Update track information in the UI
  updateTrackInfo(track) {
    if (!track) return;
    
    if (this.elements.trackInfo.title) {
      this.elements.trackInfo.title.textContent = track.title || 'Unknown Title';
    }
    
    if (this.elements.trackInfo.artist) {
      this.elements.trackInfo.artist.textContent = track.artist || 'Unknown Artist';
    }
    
    if (this.elements.trackInfo.cover) {
      // Update the cover art with error handling
      if (track.cover) {
        this.elements.trackInfo.cover.src = track.cover;
      } else {
        this.elements.trackInfo.cover.src = 'assets/images/deow (12).jpg';
      }
      
      // Add error handler for cover image
      this.elements.trackInfo.cover.onerror = function() {
        this.src = 'assets/images/deow (12).jpg';
      };
    }
  }
  
  // Update the progress bar
  updateProgress(currentTime, duration) {
    if (!duration) return;
    
    const progress = (currentTime / duration) * 100;
    
    if (this.elements.progress.progress) {
      this.elements.progress.progress.style.width = `${progress}%`;
    }
    
    if (this.elements.time.current) {
      this.elements.time.current.textContent = this.formatTime(currentTime);
    }
    
    if (this.elements.time.total) {
      this.elements.time.total.textContent = this.formatTime(duration);
    }
  }
  
  // Update the play/pause button
  updatePlayButton(isPlaying) {
    if (!this.elements.controls.play) return;
    
    const icon = this.elements.controls.play.querySelector('i');
    if (!icon) return;
    
    if (isPlaying) {
      icon.className = 'fas fa-pause';
      this.elements.controls.play.setAttribute('title', 'Pause');
    } else {
      icon.className = 'fas fa-play';
      this.elements.controls.play.setAttribute('title', 'Play');
    }
  }
  
  // Update the volume icon based on volume level
  updateVolumeIcon(volume) {
    if (!this.elements.controls.volume) return;
    
    const icon = this.elements.controls.volume.querySelector('i');
    if (!icon) return;
    
    if (volume === 0 || this.player.state.muted) {
      icon.className = 'fas fa-volume-mute';
    } else if (volume < 0.5) {
      icon.className = 'fas fa-volume-down';
    } else {
      icon.className = 'fas fa-volume-up';
    }
    
    // Update volume level indicator
    if (this.elements.volume.level) {
      this.elements.volume.level.style.width = `${volume * 100}%`;
    }
  }
  
  // Update the playlist in the UI
  updatePlaylist() {
    if (!this.config.showPlaylist || !this.elements.playlist.container) return;
    
    const { playlist } = this.player.state;
    
    // Clear existing playlist
    this.elements.playlist.container.innerHTML = '';
    
    // Add each track to the playlist
    playlist.forEach((track, index) => {
      const trackElement = document.createElement('div');
      trackElement.className = 'playlist-track';
      trackElement.innerHTML = `
        <div class="track-number">${index + 1}</div>
        <div class="track-info">
          <div class="track-title">${track.title || 'Unknown Title'}</div>
          <div class="track-artist">${track.artist || 'Unknown Artist'}</div>
        </div>
        <div class="track-duration">${this.formatTime(track.duration || 0)}</div>
      `;
      
      // Highlight current track
      if (index === this.player.state.currentTrackIndex) {
        trackElement.classList.add('active');
      }
      
      // Play track when clicked
      trackElement.addEventListener('click', () => {
        this.player.loadTrack(index);
        if (this.player.state.isPlaying) {
          this.player.play().catch(console.error);
        }
      });
      
      this.elements.playlist.container.appendChild(trackElement);
    });
    
    // Update track count and duration
    if (this.elements.playlist.trackCount) {
      this.elements.playlist.trackCount.textContent = `${playlist.length} ${playlist.length === 1 ? 'track' : 'tracks'}`;
    }
    
    if (this.elements.playlist.duration) {
      const totalDuration = playlist.reduce((sum, track) => sum + (track.duration || 0), 0);
      this.elements.playlist.duration.textContent = this.formatTime(totalDuration);
    }
  }
  
  // Highlight the current track in the playlist
  highlightCurrentTrack() {
    if (!this.config.showPlaylist || !this.elements.playlist.container) return;
    
    const tracks = this.elements.playlist.container.querySelectorAll('.playlist-track');
    tracks.forEach((track, index) => {
      if (index === this.player.state.currentTrackIndex) {
        track.classList.add('active');
      } else {
        track.classList.remove('active');
      }
    });
  }
  
  // Update the repeat button state
  updateRepeatButton() {
    if (!this.elements.controls.repeat) return;
    
    const icon = this.elements.controls.repeat.querySelector('i');
    if (!icon) return;
    
    switch (this.player.state.repeat) {
      case 'all':
        this.elements.controls.repeat.classList.add('active');
        icon.className = 'fas fa-redo';
        this.elements.controls.repeat.setAttribute('title', 'Repeat All');
        break;
      case 'one':
        this.elements.controls.repeat.classList.add('active');
        icon.className = 'fas fa-redo-alt';
        this.elements.controls.repeat.setAttribute('title', 'Repeat One');
        break;
      default:
        this.elements.controls.repeat.classList.remove('active');
        icon.className = 'fas fa-redo';
        this.elements.controls.repeat.setAttribute('title', 'Repeat Off');
    }
  }
  
  // Toggle active class on an element
  toggleActiveClass(element, className = 'active') {
    if (element.classList.contains(className)) {
      element.classList.remove(className);
    } else {
      element.classList.add(className);
    }
  }
  
  // Show an error message
  showError(message) {
    console.error('Music Player Error:', message);
    
    // Create a more user-friendly error display
    const errorContainer = document.createElement('div');
    errorContainer.className = 'player-error-message';
    errorContainer.innerHTML = `
      <div class="error-content">
        <i class="fas fa-exclamation-triangle"></i>
        <p>${message}</p>
        <button class="error-close"><i class="fas fa-times"></i></button>
      </div>
    `;
    
    // Add to container
    this.elements.container.appendChild(errorContainer);
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
      if (errorContainer.parentNode) {
        errorContainer.parentNode.removeChild(errorContainer);
      }
    }, 5000);
    
    // Add click handler to close button
    const closeButton = errorContainer.querySelector('.error-close');
    if (closeButton) {
      closeButton.addEventListener('click', () => {
        if (errorContainer.parentNode) {
          errorContainer.parentNode.removeChild(errorContainer);
        }
      });
    }
  }
  
  // Format time in MM:SS format
  formatTime(seconds) {
    if (isNaN(seconds)) return '0:00';
    
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  }
  
  // Clean up
  destroy() {
    // Clean up the player instance
    if (this.player) {
      this.player.cleanup();
    }
    
    // Remove event listeners
    // Note: For simplicity, we're not removing all event listeners here
    // In a production app, you'd want to properly clean them up
    
    // Clear the container
    if (this.elements.container) {
      this.elements.container.innerHTML = '';
    }
  }
}

// Export for different module systems
if (typeof module !== 'undefined' && module.exports) {
  // Node/CommonJS
  module.exports = MusicPlayerComponent;
} else if (typeof define === 'function' && define.amd) {
  // AMD
  define([], () => MusicPlayerComponent);
} else {
  // Browser global
  window.MusicPlayerComponent = MusicPlayerComponent;
}
