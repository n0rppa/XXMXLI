# XXMXLI Admin Audio Upload System

## Features

- **Secure Audio Upload**: Upload multiple audio files (MP3, WAV, FLAC, OGG, M4A, AAC)
- **Metadata Management**: Edit track titles, artists, albums, and durations
- **File Management**: Delete unwanted tracks
- **Real-time Updates**: Changes are immediately reflected on the music page
- **Security**: Authentication required for all admin functions

## Setup Instructions

### 1. File Permissions

Ensure the upload directory has proper permissions:
```bash
chmod 755 assets/audio/
chmod 644 assets/audio/tracklist.json
```

### 2. PHP Configuration

Make sure your server supports:
- File uploads (upload_max_filesize = 50M)
- POST data (post_max_size = 50M)
- Long execution time for large files (max_execution_time = 300)

### 3. Authentication

The system uses basic HTTP authentication as a fallback. Default credentials are:
- Username: `admin`, Password: `xxmxli2025`
- Username: `n0rppa`, Password: `music2025`

**⚠️ IMPORTANT: Change these passwords in `admin/auth.php` before going live!**

### 4. Audio Duration Detection (Optional)

For automatic duration detection, install one of these:

**Option A: getID3 PHP Library**
```bash
composer require james-heinrich/getid3
```

**Option B: FFmpeg/FFprobe**
```bash
# Ubuntu/Debian
sudo apt install ffmpeg

# CentOS/RHEL
sudo yum install ffmpeg

# macOS
brew install ffmpeg
```

## Usage

### Accessing the Upload Page

1. Go to `yoursite.com/admin/dashboard.html`
2. Click "Upload Audio" button
3. You'll be prompted for authentication

### Uploading Files

1. **Drag & Drop**: Drag audio files onto the upload area
2. **Browse**: Click the upload area to browse for files
3. **Multiple Files**: Select multiple files at once
4. **Upload**: Click "Upload Selected Files"

### Managing Tracks

- **Edit Metadata**: Use the metadata forms after upload
- **Edit Existing**: Click "Edit" on any current track
- **Delete Tracks**: Click "Delete" to remove tracks (this deletes both file and metadata)

### File Requirements

- **Max Size**: 50MB per file
- **Formats**: MP3, WAV, FLAC, OGG, M4A, AAC
- **Naming**: Files are automatically sanitized (spaces → underscores, special chars removed)

## File Structure

```
admin/
├── audio-upload.html       # Main upload interface
├── upload-audio.php        # Handle file uploads
├── update-track-metadata.php # Update track info
├── delete-audio.php        # Delete tracks
├── auth.php               # Authentication system
└── dashboard.html         # Admin dashboard (updated)

assets/audio/
├── .htaccess             # Security configuration
├── tracklist.json        # Track metadata
└── [audio files]         # Uploaded audio files
```

## Security Notes

1. **Authentication Required**: All upload endpoints require authentication
2. **File Type Validation**: Only audio files are accepted
3. **Size Limits**: 50MB maximum per file
4. **Sanitized Names**: Filenames are automatically cleaned
5. **No PHP Execution**: Upload directory prevents PHP execution

## Troubleshooting

### Upload Fails
- Check file permissions on `assets/audio/`
- Verify PHP upload limits
- Check available disk space

### Duration Not Detected
- Install getID3 or FFmpeg for automatic duration detection
- Manually enter durations in the metadata form

### Authentication Issues
- Verify credentials in `auth.php`
- Check server supports HTTP Basic Auth
- Clear browser cache/credentials

## API Endpoints

### POST /admin/upload-audio.php
Upload multiple audio files

### POST /admin/update-track-metadata.php
Update track metadata
```json
{
  "index": 0,
  "metadata": {
    "title": "New Title",
    "artist": "Artist Name",
    "album": "Album Name",
    "duration": "3:45"
  }
}
```

### POST /admin/delete-audio.php
Delete a track
```json
{
  "index": 0
}
```

## Integration

The upload system automatically updates the `tracklist.json` file that the music player reads. Changes are immediately visible on the music page without requiring a page refresh.

## Backup

Always backup your `assets/audio/` directory and `tracklist.json` file before making changes.
