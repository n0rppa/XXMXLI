document.addEventListener("DOMContentLoaded", () => {
    console.log("Sivusto ladattu!");
  });
  
// Service worker registration
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').then(() => {
    console.log('Service worker registered');
  }).catch(err => console.warn('SW register failed', err));
}
