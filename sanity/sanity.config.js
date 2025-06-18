/**
 * Sanity.io configuration
 * This file configures the Sanity Content Studio
 */

export default {
  projectId: 'vqm8chb9', // Luova Studio project ID
  dataset: 'production',
  plugins: [
    '@sanity/dashboard',
    '@sanity/desk-tool',
    '@sanity/vision',
  ],
  schema: {
    types: require('./schema').default,
  },
  document: {
    // For the admin studio configuration
    newDocumentOptions: {
      // Shown when clicking "New" button
    },
    actions: (prev) => {
      // Customize document actions
      return prev
    },
  },
}
