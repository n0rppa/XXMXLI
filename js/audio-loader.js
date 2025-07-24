// Audio preloading functionality
function preloadAudio(audioElement) {
    const loader = document.getElementById('audio-loader');
    const error = document.getElementById('audio-error');
    // Show the loading indicator and hide any previous error message
    loader.style.display = 'block';
    error.style.display = 'none';
    // When the audio data is loaded, remove the loader
    audioElement.addEventListener('loadeddata', () => {
      loader.style.display = 'none';
    });
    // In case of an error loading the audio, hide the loader and display error state
    audioElement.addEventListener('error', () => {
      loader.style.display = 'none';
      error.style.display = 'block';
    });
  }
  function retryLoadAudio() {
    const audioElement = document.getElementById('audio-player');
    // Reload the audio element and reinitialize preloading
    audioElement.load();
    preloadAudio(audioElement);
  }
  // Initialize audio preloading once the DOM is fully loaded
  document.addEventListener('DOMContentLoaded', () => {
    const audioElement = document.getElementById('audio-player');
    if (audioElement) {
      preloadAudio(audioElement);
    }
  });