class MusicPlayer {
  constructor(options = {}) {
    // Default configuration
    this.config = {
      container: '#music-player',
      audioPath: '../assets/audio/',
      debug: false,
      ...options
    };

    // Player state
    this.state = {
      isPlaying: false,
      currentTrack: null,
      volume: 0.7,
      duration: 0,
      currentTime: 0,
      muted: false,
      shuffle: false,
      repeat: false, // off, 'all', 'one'
      playlist: []
    };

    this.audioContext = null;
    this.audioElement = null;
    this.visualizer = null;
    this.gainNode = null;
    
    // Initialize
    this.init();
  }


  // Initialize the player
  async init() {
    try {
      // Create audio context
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      this.audioContext = new AudioContext();
      
      // Create audio element as fallback
      this.audioElement = new Audio();
      this.audioElement.crossOrigin = 'anonymous';
      
      // Set up audio nodes
      this.source = this.audioContext.createMediaElementSource(this.audioElement);
      this.analyser = this.audioContext.createAnalyser();
      this.gainNode = this.audioContext.createGain();
      
      // Configure analyser
      this.analyser.fftSize = 256;
      const bufferLength = this.analyser.frequencyBinCount;
      this.dataArray = new Uint8Array(bufferLength);
      
      // Connect audio nodes
      this.source.connect(this.analyser);
      this.analyser.connect(this.gainNode);
      this.gainNode.connect(this.audioContext.destination);
      
      // Set initial volume
      this.setVolume(this.state.volume);
      
      // Set up event listeners
      this.setupEventListeners();
      
      // Load playlist
      await this.loadPlaylist();
      
      if (this.state.playlist.length > 0) {
        this.loadTrack(0);
      }
      
      this.log('Music Player initialized');
    } catch (error) {
      console.error('Error initializing music player:', error);
      this.handleError(error);
    }
  }

  // Set up event listeners
  setupEventListeners() {
    // Throttle time updates for better performance
    let lastTimeUpdate = 0;
    const timeUpdateThrottle = 100; // Update every 100ms
    
    const throttledTimeUpdate = () => {
      const now = Date.now();
      if (now - lastTimeUpdate >= timeUpdateThrottle) {
        this.handleTimeUpdate();
        lastTimeUpdate = now;
      }
    };
    
    // Audio element events
    this.audioElement.addEventListener('timeupdate', throttledTimeUpdate);
    this.audioElement.addEventListener('durationchange', this.handleDurationChange.bind(this));
    this.audioElement.addEventListener('play', this.handlePlay.bind(this));
    this.audioElement.addEventListener('pause', this.handlePause.bind(this));
    this.audioElement.addEventListener('ended', this.handleEnded.bind(this));
    this.audioElement.addEventListener('error', this.handleAudioError.bind(this));
    this.audioElement.addEventListener('waiting', this.handleWaiting.bind(this));
    this.audioElement.addEventListener('canplay', this.handleCanPlay.bind(this));
    
    // Window events
    window.addEventListener('beforeunload', this.cleanup.bind(this));
    
    // Store bound functions for cleanup
    this._boundHandlers = {
      timeUpdate: throttledTimeUpdate,
      durationChange: this.handleDurationChange.bind(this),
      play: this.handlePlay.bind(this),
      pause: this.handlePause.bind(this),
      ended: this.handleEnded.bind(this),
      error: this.handleAudioError.bind(this),
      waiting: this.handleWaiting.bind(this),
      canPlay: this.handleCanPlay.bind(this),
      beforeUnload: this.cleanup.bind(this)
    };
  }

  // Load playlist
  async loadPlaylist() {
    try {
      const response = await fetch('../assets/audio/tracklist.json');
      const tracklist = await response.json();
      this.state.playlist = tracklist.map(track => ({
        id: track.file,
        filename: track.file,
        title: track.title || track.file.replace(/\.[^/.]+$/, ''),
        artist: track.artist || 'Unknown Artist',
        album: track.album || '',
        duration: this.parseDuration(track.duration) || 0,
        path: `${this.config.audioPath}${track.file}`
      }));
      this.log('Playlist loaded:', this.state.playlist.length, 'tracks');
    } catch (error) {
      console.error('Failed to load playlist:', error);
      // Fallback to empty playlist
      this.state.playlist = [];
    }
  }

  // Load a track by index
  async loadTrack(index) {
    try {
      if (index < 0 || index >= this.state.playlist.length) {
        throw new Error('Track index out of bounds');
      }
      
      this.state.loading = true;
      this.state.currentTrackIndex = index;
      this.state.currentTrack = this.state.playlist[index];
      
      // Pause current playback
      if (this.state.isPlaying) {
        this.pause();
      }
      
      // Reset audio element
      this.audioElement.src = this.config.audioPath + this.state.currentTrack.filename;
      this.audioElement.load();
      
      // Update UI
      this.triggerEvent('trackChanged', { 
        track: this.state.currentTrack, 
        index: this.state.currentTrackIndex 
      });
      
      // If was playing, start playback after loading
      if (this.state.isPlaying) {
        await this.play();
      }
      
      this.state.loading = false;
      
    } catch (error) {
      console.error(`Error loading track ${index}:`, error);
      this.handleError(error);
      this.state.loading = false;
    }
  }

  // Play the current track
  async play(trackId) {
    try {
      // Resume audio context if suspended
      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }

      if (trackId) {
        const track = this.state.playlist.find(t => t.id === trackId);
        if (!track) return;

        if (this.state.currentTrack?.id === trackId) {
          if (this.state.isPlaying) {
            this.pause();
          } else {
            this.resume();
          }
          return;
        }

        this.state.currentTrack = track;
        this.audioElement.src = track.path;
      }

      await this.audioElement.play();
      this.state.isPlaying = true;
      
      // Start visualization
      this.startVisualization();
      
      this.triggerEvent('play', { track: this.state.currentTrack });
      
    } catch (error) {
      console.error('Failed to play track:', error);
      this.handleError(error);
    }
  }

  // Resume playback
  resume() {
    if (!this.audioElement.src) return;
    
    this.audioElement.play()
      .then(() => {
        this.state.isPlaying = true;
        this.startVisualization();
        this.triggerEvent('play', { track: this.state.currentTrack });
      })
      .catch(error => {
        console.error('Failed to resume playback:', error);
        this.handleError(error);
      });
  }

  // Pause playback
  pause() {
    try {
      this.audioElement.pause();
      this.state.isPlaying = false;
      
      // Stop visualization
      this.stopVisualization();
      
      this.triggerEvent('pause', { track: this.state.currentTrack });
      
    } catch (error) {
      console.error('Error pausing audio:', error);
      this.handleError(error);
    }
  }

  // Toggle play/pause
  togglePlay() {
    if (this.state.isPlaying) {
      this.pause();
    } else {
      this.play();
    }
  }

  // Stop playback
  stop() {
    try {
      this.pause();
      this.audioElement.currentTime = 0;
      this.state.currentTime = 0;
      
      this.triggerEvent('stop', { track: this.state.currentTrack });
      
    } catch (error) {
      console.error('Error stopping audio:', error);
      this.handleError(error);
    }
  }

  // Skip to next track
  next() {
    if (this.state.playlist.length === 0) return;
    
    let nextIndex = this.state.currentTrackIndex + 1;
    
    if (nextIndex >= this.state.playlist.length) {
      if (this.state.repeat === 'all') {
        nextIndex = 0;
      } else {
        this.stop();
        return;
      }
    }
    
    this.loadTrack(nextIndex);
    
    if (this.state.isPlaying) {
      this.play();
    }
  }

  // Go to previous track
  previous() {
    if (this.state.playlist.length === 0) return;
    
    // If we're more than 3 seconds into the song, restart it
    if (this.audioElement.currentTime > 3) {
      this.audioElement.currentTime = 0;
      return;
    }
    
    let prevIndex = this.state.currentTrackIndex - 1;
    
    if (prevIndex < 0) {
      if (this.state.repeat === 'all') {
        prevIndex = this.state.playlist.length - 1;
      } else {
        this.audioElement.currentTime = 0;
        return;
      }
    }
    
    this.loadTrack(prevIndex);
    
    if (this.state.isPlaying) {
      this.play();
    }
  }

  // Set volume (0-1)
  setVolume(volume) {
    try {
      volume = Math.max(0, Math.min(1, volume)); // Clamp between 0 and 1
      this.state.volume = volume;
      this.gainNode.gain.setValueAtTime(volume, this.audioContext.currentTime);
      
      // Update muted state if volume is 0
      if (volume === 0) {
        this.state.muted = true;
      } else {
        this.state.muted = false;
      }
      
      this.triggerEvent('volumeChange', { volume });
      
    } catch (error) {
      console.error('Error setting volume:', error);
      this.handleError(error);
    }
  }

  // Toggle mute
  toggleMute() {
    if (this.state.muted) {
      this.setVolume(this.state.volume > 0 ? this.state.volume : 0.7);
    } else {
      this.setVolume(0);
    }
  }

  // Seek to a specific time in the track
  seek(time) {
    try {
      time = Math.max(0, Math.min(time, this.state.duration));
      this.audioElement.currentTime = time;
      this.state.currentTime = time;
      
      this.triggerEvent('seek', { time });
      
    } catch (error) {
      console.error('Error seeking:', error);
      this.handleError(error);
    }
  }

  // Toggle shuffle
  toggleShuffle() {
    this.state.shuffle = !this.state.shuffle;
    
    if (this.state.shuffle) {
      // Shuffle the playlist
      this.shufflePlaylist();
    } else {
      // Restore original order
      this.loadPlaylist();
    }
    
    this.triggerEvent('shuffleChange', { shuffle: this.state.shuffle });
  }

  // Toggle repeat mode
  toggleRepeat() {
    if (!this.state.repeat) {
      this.state.repeat = 'all';
    } else if (this.state.repeat === 'all') {
      this.state.repeat = 'one';
    } else {
      this.state.repeat = false;
    }
    
    this.triggerEvent('repeatChange', { repeat: this.state.repeat });
  }

  // Shuffle the playlist
  shufflePlaylist() {
    const currentTrackId = this.state.currentTrack?.id;
    let currentIndex = 0;
    
    // Create a copy of the playlist and shuffle it
    const shuffled = [...this.state.playlist];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    
    // Find the current track in the shuffled list
    if (currentTrackId) {
      currentIndex = shuffled.findIndex(track => track.id === currentTrackId);
      if (currentIndex === -1) currentIndex = 0;
    }
    
    // Update the playlist and current track
    this.state.playlist = shuffled;
    this.state.currentTrackIndex = currentIndex;
    this.state.currentTrack = shuffled[currentIndex];
    
    this.triggerEvent('playlistShuffled', { playlist: this.state.playlist });
  }

  // Start visualization with performance optimization
  startVisualization() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }
    
    if (!this.canvas) {
      this.canvas = document.createElement('canvas');
      this.canvas.width = 300;
      this.canvas.height = 80;
      this.canvasContext = this.canvas.getContext('2d');
      
      // Add canvas to the player UI
      const container = document.querySelector(`${this.config.container} .visualizer`);
      if (container) {
        container.innerHTML = '';
        container.appendChild(this.canvas);
      }
    }
    
    // Throttle animation to 30fps for better performance
    let lastTime = 0;
    const targetFPS = 30;
    const frameInterval = 1000 / targetFPS;
    
    const draw = (currentTime) => {
      if (!this.analyser || !this.canvasContext || !this.state.isPlaying) return;
      
      this.animationFrame = requestAnimationFrame(draw);
      
      // Throttle to target FPS
      if (currentTime - lastTime < frameInterval) return;
      lastTime = currentTime;
      
      const width = this.canvas.width;
      const height = this.canvas.height;
      const barWidth = (width / this.analyser.frequencyBinCount) * 2.5;
      let x = 0;
      
      this.analyser.getByteFrequencyData(this.dataArray);
      
      // Clear with fade effect for smoother visualization
      this.canvasContext.fillStyle = 'rgba(0, 0, 0, 0.3)';
      this.canvasContext.fillRect(0, 0, width, height);
      
      // Draw fewer bars for better performance
      const step = Math.max(1, Math.floor(this.analyser.frequencyBinCount / 64));
      
      for (let i = 0; i < this.analyser.frequencyBinCount; i += step) {
        const barHeight = (this.dataArray[i] / 255) * height;
        
        const hue = (i / this.analyser.frequencyBinCount) * 360;
        this.canvasContext.fillStyle = `hsl(${hue}, 70%, 50%)`;
        
        this.canvasContext.fillRect(
          x, 
          height - barHeight, 
          barWidth - 1, 
          barHeight
        );
        
        x += barWidth + 1;
      }
    };
    
    draw(0);
  }

  // Stop visualization
  stopVisualization() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
      this.animationFrame = null;
    }
    
    if (this.canvasContext) {
      this.canvasContext.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }
  }

  // Event handlers
  handleTimeUpdate() {
    this.state.currentTime = this.audioElement.currentTime;
    this.triggerEvent('timeUpdate', { 
      currentTime: this.state.currentTime,
      duration: this.state.duration
    });
  }

  handleDurationChange() {
    this.state.duration = this.audioElement.duration || 0;
    this.triggerEvent('durationChange', { duration: this.state.duration });
  }

  handlePlay() {
    this.state.isPlaying = true;
    this.triggerEvent('play', { track: this.state.currentTrack });
  }

  handlePause() {
    this.state.isPlaying = false;
    this.triggerEvent('pause', { track: this.state.currentTrack });
  }

  handleEnded() {
    this.state.isPlaying = false;
    
    if (this.state.repeat === 'one') {
      this.audioElement.currentTime = 0;
      this.play();
    } else if (this.state.repeat === 'all' || this.state.currentTrackIndex < this.state.playlist.length - 1) {
      this.next();
    } else {
      this.triggerEvent('end', { track: this.state.currentTrack });
    }
  }

  handleAudioError(error) {
    console.error('Audio error:', error);
    this.handleError(new Error('Failed to load audio'));
  }

  handleWaiting() {
    this.triggerEvent('waiting');
  }

  handleCanPlay() {
    this.triggerEvent('canPlay');
  }

  // Error handling
  handleError(error) {
    console.error('Music Player Error:', error);
    this.state.error = error;
    
    this.triggerEvent('error', { 
      error: error.message || 'An unknown error occurred',
      details: error 
    });
  }

  // Event system
  on(event, callback) {
    if (!this.eventListeners) {
      this.eventListeners = {};
    }
    
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = [];
    }
    
    this.eventListeners[event].push(callback);
  }

  off(event, callback) {
    if (!this.eventListeners || !this.eventListeners[event]) return;
    
    if (callback) {
      this.eventListeners[event] = this.eventListeners[event].filter(cb => cb !== callback);
    } else {
      delete this.eventListeners[event];
    }
  }

  triggerEvent(event, data = {}) {
    if (!this.eventListeners || !this.eventListeners[event]) return;
    
    const eventData = { 
      type: event,
      target: this,
      ...data 
    };
    
    this.eventListeners[event].forEach(callback => {
      try {
        callback(eventData);
      } catch (error) {
        console.error(`Error in ${event} handler:`, error);
      }
    });
  }

  // Utility methods
  formatTime(seconds) {
    if (isNaN(seconds)) return '0:00';
    
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  }

  // Parse duration string (e.g., "3:42" or "2:01") to seconds
  parseDuration(durationStr) {
    if (!durationStr || typeof durationStr !== 'string') return 0;
    
    const parts = durationStr.split(':').map(Number);
    if (parts.length === 2) {
      return parts[0] * 60 + parts[1]; // minutes:seconds
    } else if (parts.length === 3) {
      return parts[0] * 3600 + parts[1] * 60 + parts[2]; // hours:minutes:seconds
    }
    
    return 0;
  }

  log(...args) {
    if (this.config.debug) {
      console.log('[MusicPlayer]', ...args);
    }
  }

  // Clean up resources
  cleanup() {
    this.pause();
    this.stopVisualization();
    
    // Disconnect audio nodes
    if (this.source) {
      this.source.disconnect();
    }
    
    if (this.analyser) {
      this.analyser.disconnect();
    }
    
    if (this.gainNode) {
      this.gainNode.disconnect();
    }
    
    // Close audio context
    if (this.audioContext && this.audioContext.state !== 'closed') {
      this.audioContext.close();
    }
    
    // Remove event listeners using stored bound handlers
    if (this.audioElement && this._boundHandlers) {
      this.audioElement.removeEventListener('timeupdate', this._boundHandlers.timeUpdate);
      this.audioElement.removeEventListener('durationchange', this._boundHandlers.durationChange);
      this.audioElement.removeEventListener('play', this._boundHandlers.play);
      this.audioElement.removeEventListener('pause', this._boundHandlers.pause);
      this.audioElement.removeEventListener('ended', this._boundHandlers.ended);
      this.audioElement.removeEventListener('error', this._boundHandlers.error);
      this.audioElement.removeEventListener('waiting', this._boundHandlers.waiting);
      this.audioElement.removeEventListener('canplay', this._boundHandlers.canPlay);
      
      // Release audio element
      this.audioElement.src = '';
      this.audioElement.load();
    }
    
    // Remove window event listener
    if (this._boundHandlers) {
      window.removeEventListener('beforeunload', this._boundHandlers.beforeUnload);
    }
    
    // Clear all event listeners
    this.eventListeners = {};
    this._boundHandlers = null;
    
    this.log('Music Player cleaned up');
  }
}

// Export for different module systems
if (typeof module !== 'undefined' && module.exports) {
  // Node/CommonJS
  module.exports = MusicPlayer;
} else if (typeof define === 'function' && define.amd) {
  // AMD
  define([], () => MusicPlayer);
} else {
  // Browser global
  window.MusicPlayer = MusicPlayer;
}
