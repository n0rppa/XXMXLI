/**
 * Sanity Loader - No npm required
 * This file handles loading content from Sanity CMS using their CDN-based client
 */

// Load the necessary scripts
function loadSanityScripts() {
  return new Promise((resolve, reject) => {
    // Load @sanity/client from CDN
    const script = document.createElement('script');
    script.src = "https://cdn.jsdelivr.net/npm/@sanity/client@6.1.7/dist/index.browser.min.js";
    script.async = true;
    
    script.onload = () => {
      console.log('Sanity client loaded successfully');
      resolve();
    };
    
    script.onerror = () => {
      console.error('Failed to load Sanity client');
      reject(new Error('Failed to load Sanity client'));
    };
    
    document.head.appendChild(script);
  });
}

// Initialize the Sanity client
function initSanityClient() {
  if (!window.sanityClient) {
    console.error('Sanity client not loaded');
    return null;
  }
  
  return window.sanityClient({
    projectId: '5njdlic9',
    dataset: 'production',
    apiVersion: '2025-05-16',
    useCdn: true
  });
}

// Main initialization function
async function initSanity() {
  try {
    await loadSanityScripts();
    const client = initSanityClient();
    
    if (!client) {
      throw new Error('Failed to initialize Sanity client');
    }
    
    console.log('Sanity initialized successfully');
    return client;
  } catch (error) {
    console.error('Sanity initialization error:', error);
    document.getElementById('sanity-status').textContent = 'Error: ' + error.message;
    return null;
  }
}

// Fetch content from Sanity
async function fetchSanityContent(query, params = {}) {
  const client = initSanityClient();
  if (!client) return [];
  
  try {
    // Add proper error handling and data validation
    const result = await client.fetch(query, params);
    
    // Validate the result
    if (!result) {
      console.warn('No data returned from Sanity');
      return [];
    }
    
    // If it's an array, filter out any invalid items
    if (Array.isArray(result)) {
      return result.filter(item => item && typeof item === 'object');
    }
    
    // If it's a single object, return it in an array
    if (result && typeof result === 'object') {
      return [result];
    }
    
    return [];
  } catch (error) {
    console.error('Sanity query error:', error);
    // Return a more descriptive error
    throw new Error(`Failed to fetch content from Sanity: ${error.message}`);
  }
}
