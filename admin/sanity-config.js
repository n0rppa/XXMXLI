/**
 * Sanity.io client configuration
 * CDN-based approach (no npm required)
 */

// Configure with your Sanity project ID, dataset, and API version
const sanityConfig = {
  projectId: '5njdlic9', // Unified project ID
  dataset: 'production',
  apiVersion: '2025-09-01', // Pin a recent API version for stability
  useCdn: true,
  // token: '' // If you need private data, set via runtime, never commit secrets
};

// Initialize the client
function createSanityClient() {
  return window.sanityClient(sanityConfig);
}

// Helper function to fetch data
async function fetchFromSanity(query, params = {}) {
  const client = createSanityClient();
  try {
    return await client.fetch(query, params);
  } catch (error) {
    console.error('Sanity query error:', error);
    throw error;
  }
}

// Common queries
const Queries = {
  // Get all photos
  allPhotos: `*[_type == "photo"] {
    _id,
    title,
    "imageUrl": image.asset->url,
    tags,
    description
  }`,
  
  // Get all music tracks
  allTracks: `*[_type == "track"] {
    _id,
    title,
    "audioUrl": audioFile.asset->url,
    tags,
    description
  }`,
  
  // Get all projects
  allProjects: `*[_type == "project"] {
    _id,
    title,
    "imageUrl": coverImage.asset->url,
    tags,
    description,
    startDate,
    endDate
  }`,
  
  // Get content by tag
  byTag: (tag) => `*[_type in ["photo", "track", "project"] && "${tag}" in tags]`
};
