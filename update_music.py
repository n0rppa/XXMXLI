#!/usr/bin/env python3
"""
Music File Scanner and HTML Generator
Scans assets/music/ directory for audio files and updates music.html
"""

import os
import json
import re
from pathlib import Path
from datetime import datetime
import mimetypes

# Supported audio formats
AUDIO_EXTENSIONS = {'.mp3', '.flac', '.wav', '.ogg', '.m4a', '.aac', '.wma'}

# Music directory path
MUSIC_DIR = Path('assets/music')
MUSIC_HTML_FILE = Path('music.html')

def get_file_info(file_path):
    """Extract basic info from audio file"""
    try:
        stat = file_path.stat()
        return {
            'filename': file_path.name,
            'path': str(file_path).replace('\\', '/'),
            'size': stat.st_size,
            'modified': datetime.fromtimestamp(stat.st_mtime).isoformat(),
            'extension': file_path.suffix.lower()
        }
    except Exception as e:
        print(f"Error getting info for {file_path}: {e}")
        return None

def scan_music_files():
    """Scan music directory for audio files"""
    if not MUSIC_DIR.exists():
        print(f"Music directory {MUSIC_DIR} does not exist. Creating...")
        MUSIC_DIR.mkdir(parents=True, exist_ok=True)
        return []
    
    music_files = []
    
    print(f"Scanning {MUSIC_DIR} for audio files...")
    
    for file_path in MUSIC_DIR.rglob('*'):
        if file_path.is_file() and file_path.suffix.lower() in AUDIO_EXTENSIONS:
            file_info = get_file_info(file_path)
            if file_info:
                music_files.append(file_info)
                print(f"Found: {file_info['filename']}")
    
    # Sort by filename
    music_files.sort(key=lambda x: x['filename'].lower())
    
    print(f"Total audio files found: {len(music_files)}")
    return music_files

def format_file_size(size_bytes):
    """Convert bytes to human readable format"""
    if size_bytes == 0:
        return "0B"
    size_names = ["B", "KB", "MB", "GB"]
    i = 0
    while size_bytes >= 1024 and i < len(size_names) - 1:
        size_bytes /= 1024.0
        i += 1
    return f"{size_bytes:.1f}{size_names[i]}"

def extract_title_from_filename(filename):
    """Extract a clean title from filename"""
    # Remove extension
    title = Path(filename).stem
    
    # Remove common prefixes like track numbers
    title = re.sub(r'^\d+\.?\s*', '', title)
    title = re.sub(r'^track\s*\d+\.?\s*', '', title, flags=re.IGNORECASE)
    
    # Replace underscores and hyphens with spaces
    title = title.replace('_', ' ').replace('-', ' ')
    
    # Clean up multiple spaces
    title = re.sub(r'\s+', ' ', title).strip()
    
    # Capitalize words
    title = title.title()
    
    return title if title else filename

def generate_js_tracks_array(music_files):
    """Generate JavaScript tracks array for music.html"""
    if not music_files:
        return "const tracks = [];"
    
    tracks_js = "const tracks = [\n"
    
    for i, file_info in enumerate(music_files):
        title = extract_title_from_filename(file_info['filename'])
        tracks_js += f"            {{ id: {i+1}, title: '{title}', file: '{file_info['path']}' }}"
        
        # Add comma if not last item
        if i < len(music_files) - 1:
            tracks_js += ","
        tracks_js += "\n"
    
    tracks_js += "        ];"
    return tracks_js

def update_music_html(music_files):
    """Update the music.html file with new track list"""
    try:
        # Read existing HTML file
        if MUSIC_HTML_FILE.exists():
            with open(MUSIC_HTML_FILE, 'r', encoding='utf-8') as f:
                html_content = f.read()
        else:
            print(f"{MUSIC_HTML_FILE} not found. Please make sure the file exists.")
            return False
        
        # Generate new JavaScript tracks array
        tracks_js = generate_js_tracks_array(music_files)
        
        # Find and replace the tracks array in the JavaScript
        tracks_start = html_content.find('const tracks = [')
        if tracks_start != -1:
            tracks_end = html_content.find('];', tracks_start) + 2
            new_html = (
                html_content[:tracks_start] +
                tracks_js +
                html_content[tracks_end:]
            )
        else:
            print("Could not find tracks array in music.html")
            return False
        
        # Add timestamp comment
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        new_html = new_html.replace(
            '<!-- MUSIC_UPDATED_TIMESTAMP -->', 
            f'<!-- MUSIC_UPDATED_TIMESTAMP: {timestamp} -->'
        )
        
        # Write updated HTML
        with open(MUSIC_HTML_FILE, 'w', encoding='utf-8') as f:
            f.write(new_html)
        
        print(f"Successfully updated {MUSIC_HTML_FILE}")
        return True
        
    except Exception as e:
        print(f"Error updating HTML file: {e}")
        return False

def save_music_data(music_files):
    """Save music file data to JSON for other scripts"""
    data = {
        'last_updated': datetime.now().isoformat(),
        'total_files': len(music_files),
        'files': music_files
    }
    
    json_file = Path('assets/music/music_data.json')
    json_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"Music data saved to {json_file}")

def main():
    """Main function"""
    print("=== Music File Scanner ===")
    print(f"Scanning directory: {MUSIC_DIR.absolute()}")
    
    # Scan for music files
    music_files = scan_music_files()
    
    if music_files:
        # Save data to JSON
        save_music_data(music_files)
        
        # Update HTML file
        if update_music_html(music_files):
            print("\n✅ Music page updated successfully!")
            print(f"Found {len(music_files)} audio files:")
            for file_info in music_files:
                print(f"  - {file_info['filename']} ({format_file_size(file_info['size'])})")
        else:
            print("\n❌ Failed to update music page.")
    else:
        print(f"\n⚠️  No audio files found in {MUSIC_DIR}")
        print("Add some audio files (.mp3, .flac, .wav, etc.) to the directory and run again.")

if __name__ == "__main__":
    main()

