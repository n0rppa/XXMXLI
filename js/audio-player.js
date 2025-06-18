/**
 * Enhanced Audio Player Integration
 * This script integrates with MusicPlayerComponent to provide additional audio functionality.
 */

// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
  // Initialize the audio context for visualization
  const AudioContext = window.AudioContext || window.webkitAudioContext;
  let audioContext;
  
  try {
    audioContext = new AudioContext();
  } catch (e) {
    console.error('Web Audio API is not supported in this browser', e);
  }
  
  // Function to initialize Howler.js with our player
  function initAudioPlayers() {
    // Find all the music player instances on the page
    const playerElements = document.querySelectorAll('.music-player');
    
    if (playerElements.length === 0) {
      console.log('No music players found on this page');
      return;
    }
    
    console.log(`Found ${playerElements.length} music player(s)`);
    
    // Set up error handling for Howler
    Howler.autoUnlock = true;
    Howler.html5PoolSize = 10;
    
    Howler.autoSuspend = false; // Prevent auto-suspending for better playback
    
    // Set global volume
    Howler.volume(0.7);
    
    // Add global error handling
    window.addEventListener('error', function(e) {
      if (e.target.tagName === 'AUDIO' || e.target.tagName === 'SOURCE') {
        console.error('Audio error detected:', e);
        showNotification('Audio playback error. Please try again.');
      }
    }, true);
  }
  
  // Function to show a notification to the user
  function showNotification(message, type = 'error') {
    const notification = document.createElement('div');
    notification.className = `audio-notification ${type}`;
    notification.innerHTML = `
      <div class="notification-content">
        <i class="fas ${type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle'}"></i>
        <span>${message}</span>
        <button class="close-btn"><i class="fas fa-times"></i></button>
      </div>
    `;
    
    document.body.appendChild(notification);
    
    // Add animation
    setTimeout(() => {
      notification.classList.add('show');
    }, 10);
    
    // Remove after 5 seconds
    setTimeout(() => {
      notification.classList.remove('show');
      setTimeout(() => {
        notification.remove();
      }, 300);
    }, 5000);
    
    // Close button functionality
    const closeBtn = notification.querySelector('.close-btn');
    if (closeBtn) {
      closeBtn.addEventListener('click', () => {
        notification.classList.remove('show');
        setTimeout(() => {
          notification.remove();
        }, 300);
      });
    }
  }
  
  // Initialize audio preloading for better performance
  function preloadAudio(sources) {
    sources.forEach(src => {
      const audio = new Audio();
      audio.preload = 'metadata';
      audio.src = src;
    });
  }
  
  // Handle image preloading for cover art
  function preloadImages(sources) {
    sources.forEach(src => {
      const img = new Image();
      img.src = src;
    });
  }
  
  // Add keyboard shortcuts for global control
  function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
      // Only process if not in an input, textarea, or select
      if (['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement.tagName)) {
        return;
      }
      
      // Assuming we have a global reference to the active player
      const activePlayers = window.musicPlayers || [];
      if (activePlayers.length === 0) return;
      
      // Use the first player as the main controller
      const mainPlayer = activePlayers[0];
      
      switch (e.code) {
        case 'Space': // Play/Pause
          e.preventDefault();
          if (mainPlayer.player.state.isPlaying) {
            mainPlayer.player.pause();
          } else {
            mainPlayer.player.play().catch(err => {
              console.error('Error playing audio:', err);
            });
          }
          break;
        
        case 'ArrowRight': // Next track
          if (e.ctrlKey || e.metaKey) {
            e.preventDefault();
            mainPlayer.player.next();
          }
          break;
        
        case 'ArrowLeft': // Previous track
          if (e.ctrlKey || e.metaKey) {
            e.preventDefault();
            mainPlayer.player.previous();
          }
          break;
          
        case 'KeyM': // Mute/Unmute
          e.preventDefault();
          mainPlayer.player.toggleMute();
          break;
      }
    });
  }
  
  // Fix for FLAC playback in some browsers
  function patchFlacSupport() {
    // Check if browser supports FLAC natively
    const audio = document.createElement('audio');
    const canPlayFlac = audio.canPlayType('audio/flac').replace('no', '');
    
    if (!canPlayFlac) {
      console.log('Native FLAC support not detected. Adding fallback.');
      // Add a listener to convert FLAC to format the browser can play
      // This would require a server-side component in a real implementation
      showNotification('Your browser may not support FLAC audio files. Consider using Chrome or Edge for best experience.', 'info');
    }
  }
  
  // Initialize all audio features
  function init() {
    // Store all player instances for global access
    window.musicPlayers = window.musicPlayers || [];
    
    // Poll for players since they might be initialized after this script
    const checkForPlayers = setInterval(() => {
      const newPlayers = Array.from(document.querySelectorAll('.music-player'))
        .map(el => el.musicPlayerComponent)
        .filter(Boolean);
      
      if (newPlayers.length > 0) {
        window.musicPlayers = newPlayers;
        clearInterval(checkForPlayers);
        
        console.log('Music players registered:', window.musicPlayers.length);
        initAudioPlayers();
        setupKeyboardShortcuts();
        patchFlacSupport();
        
        // Preload audio files and images for better performance
        const audioSources = newPlayers.flatMap(player => 
          player.player.state.playlist.map(track => player.player.config.audioPath + track.filename)
        );
        
        const imageSources = newPlayers.flatMap(player => 
          player.player.state.playlist.map(track => track.cover)
        );
        
        preloadAudio(audioSources);
        preloadImages(imageSources);
      }
    }, 500);
    
    // Stop checking after 10 seconds
    setTimeout(() => {
      clearInterval(checkForPlayers);
    }, 10000);
  }
  
  // Start initialization
  init();
  
  // Add CSS for notifications
  const style = document.createElement('style');
  style.textContent = `
    .audio-notification {
      position: fixed;
      bottom: 20px;
      right: 20px;
      background-color: rgba(239, 68, 68, 0.9);
      color: white;
      padding: 10px 15px;
      border-radius: 4px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
      z-index: 9999;
      transform: translateY(100px);
      opacity: 0;
      transition: transform 0.3s ease, opacity 0.3s ease;
    }
    
    .audio-notification.info {
      background-color: rgba(59, 130, 246, 0.9);
    }
    
    .audio-notification.show {
      transform: translateY(0);
      opacity: 1;
    }
    
    .notification-content {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    
    .close-btn {
      background: none;
      border: none;
      color: white;
      cursor: pointer;
      padding: 0;
      margin-left: 10px;
    }
  `;
  document.head.appendChild(style);
});

