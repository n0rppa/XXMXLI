/**
 * Sanity.io configuration
 * This file configures the Sanity Content Studio
 */

// Sanity Studio configuration (browser-based/embed friendly)
// Note: If using Sanity Studio v3 with ESM, this file is typically used by the Studio build,
// but here we keep it as reference/unified values for admin pages.
export default {
  projectId: '5njdlic9',
  dataset: 'production',
  plugins: [
    '@sanity/dashboard',
    '@sanity/desk-tool',
    '@sanity/vision'
  ],
  schema: {
    // If bundling with ESM, use: import schema from './schema'; and set types: schema.types
    // For this static repo reference, require may not be executed—kept for developer context.
    types: (await import('./schema.js')).default.types
  },
  document: {
    newDocumentOptions: {},
    actions: (prev) => prev
  }
}
