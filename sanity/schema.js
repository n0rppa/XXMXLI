// Schema for Sanity.io content models
export default {
  types: [
    {
      name: 'photo',
      title: 'Photo',
      type: 'document',
      fields: [
        {
          name: 'title',
          title: 'Title',
          type: 'string',
          validation: Rule => Rule.required()
        },
        {
          name: 'image',
          title: 'Image',
          type: 'image',
          options: {
            hotspot: true // Enable hotspot for responsive image cropping
          },
          validation: Rule => Rule.required()
        },
        {
          name: 'tags',
          title: 'Tags',
          type: 'array',
          of: [{ type: 'string' }]
        },
        {
          name: 'description',
          title: 'Description',
          type: 'text'
        }
      ]
    },
    {
      name: 'track',
      title: 'Music Track',
      type: 'document',
      fields: [
        {
          name: 'title',
          title: 'Title',
          type: 'string',
          validation: Rule => Rule.required()
        },
        {
          name: 'audioFile',
          title: 'Audio File',
          type: 'file',
          validation: Rule => Rule.required()
        },
        {
          name: 'tags',
          title: 'Tags',
          type: 'array',
          of: [{ type: 'string' }]
        },
        {
          name: 'description',
          title: 'Description',
          type: 'text'
        }
      ]
    },
    {
      name: 'project',
      title: 'Project',
      type: 'document',
      fields: [
        {
          name: 'title',
          title: 'Title',
          type: 'string',
          validation: Rule => Rule.required()
        },
        {
          name: 'coverImage',
          title: 'Cover Image',
          type: 'image',
          options: {
            hotspot: true
          }
        },
        {
          name: 'description',
          title: 'Description',
          type: 'text'
        },
        {
          name: 'tags',
          title: 'Tags',
          type: 'array',
          of: [{ type: 'string' }]
        },
        {
          name: 'startDate',
          title: 'Start Date',
          type: 'date'
        },
        {
          name: 'endDate',
          title: 'End Date',
          type: 'date'
        }
      ]
    }
  ]
}
