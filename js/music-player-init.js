// Music Player Initialization Module
// Purpose: Handles player initialization, error handling, and UI updates

// Wait for DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
  console.log("DOM loaded, initializing player...");
  
  const statusContainer = document.getElementById('status-container');
  
  // Function to show status messages
  function showStatus(message, isError = false) {
    const messageDiv = document.createElement('div');
    messageDiv.className = isError ? 'error-message' : 'status-message';
    messageDiv.innerHTML = message;
    statusContainer.appendChild(messageDiv);
    
    console.log(isError ? "ERROR:" : "STATUS:", message);
    
    // Auto-remove success messages after 5 seconds
    if (!isError) {
      setTimeout(() => {
        messageDiv.style.opacity = '0';
        messageDiv.style.transition = 'opacity 0.5s';
        setTimeout(() => messageDiv.remove(), 500);
      }, 5000);
    }
  }
  
  // Check for audio format compatibility
  const audio = document.createElement('audio');
  const canPlayFlac = audio.canPlayType('audio/flac').replace('no', '');
  
  if (!canPlayFlac) {
    showStatus('<i class="fas fa-exclamation-triangle"></i> Your browser may not support FLAC audio files. Consider using Chrome or Firefox for best experience.', true);
  }
  
  // Fetch track configuration from external file to avoid exposing raw paths
  fetch('js/track-config.js')
    .then(response => {
      if (!response.ok) {
        throw new Error('Failed to load track configuration');
      }
      return response.json();
    })
    .then(tracks => {
      initializePlayer(tracks);
    })
    .catch(error => {
      showStatus(`Failed to load track configuration: ${error.message}`, true);
      
      // Fallback to default tracks if config can't be loaded
      const fallbackTracks = [
        {
          title: 'Sample Track 1',
          artist: 'Artist Name',
          src: 'assets/audio/sample.flac', 
          cover: 'assets/images/default-cover.jpg',
          duration: 180
        }
      ];
      
      initializePlayer(fallbackTracks);
    });
  
  // Initialize player with provided tracks
  function initializePlayer(tracks) {
    try {
      // Initialize the music player
      const player = new MusicPlayerComponent('#musicPlayer', {
        tracks: tracks,
        showPlaylist: true,
        visualizer: false,  // Disable visualizer initially for simplicity
        theme: 'light'
      });
      
      // We don't expose player to window object in production for security
      // Only enable this in development environment
      if (window.location.hostname === 'localhost') {
        window.player = player;
      }
      
      // Add event listeners for player states
      player.player.on('trackChanged', ({ track }) => {
        showStatus(`Now playing: ${track.title} by ${track.artist}`);
      });
      
      player.player.on('error', ({ error }) => {
        showStatus(`Player error: ${error}`, true);
      });
      
      // Add manual play button for better user interaction
      const playButton = document.createElement('button');
      playButton.className = 'play-button';
      playButton.innerHTML = '<i class="fas fa-play"></i> Play First Track';
      playButton.setAttribute('aria-label', 'Play First Track');
      
      playButton.addEventListener('click', () => {
        player.player.loadTrack(0);
        player.player.play().catch(error => {
          showStatus(`Could not play track: ${error.message}`, true);
        });
      });
      
      statusContainer.appendChild(playButton);
      
      showStatus('<i class="fas fa-check-circle"></i> Music player initialized successfully. Click a track to play.');
      
    } catch (error) {
      showStatus(`Failed to initialize music player: ${error.message}`, true);
      console.error('Music player initialization error:', error);
    }
    
    // Handle image errors
    document.querySelectorAll('.music-player img').forEach(img => {
      if (!img.hasAttribute('loading')) {
        img.setAttribute('loading', 'lazy');
      }
      
      img.onerror = function() {
        this.src = 'assets/images/default-cover.jpg'; // Fallback image
        showStatus('An image failed to load and was replaced with a placeholder.', true);
      };
    });
  }
});

