#!/usr/bin/env python3
"""
Enhanced Music File Scanner and HTML / JSON Generator
Scans assets/audio/ directory for audio files and updates (optionally) music.html
Generates assets/audio/tracklist.json consumed by the web music player.
Usage: python update_music.py [--update-html]
"""

import os
import json
import re
from pathlib import Path
from datetime import datetime
import mimetypes
import argparse

# Supported audio formats
AUDIO_EXTENSIONS = {'.mp3', '.flac', '.wav', '.ogg', '.m4a', '.aac', '.wma', '.opus'}

# Music (audio) directory path UPDATED to assets/audio
MUSIC_DIR = Path('assets/audio')
MUSIC_HTML_FILE = Path('music.html')
TRACKLIST_JSON = Path('assets/audio/tracklist.json')

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

def generate_music_html_content(music_files):
    """Generate the track list HTML content"""
    if not music_files:
        return """
        <div class="no-music">
            <p>Ei musiikkitiedostoja. Lisää äänitteitä assets/music/ -kansioon ja aja skripti uudelleen.</p>
        </div>
        """
    
    tracks_html = []
    
    for i, file_info in enumerate(music_files, 1):
        title = extract_title_from_filename(file_info['filename'])
        file_size = format_file_size(file_info['size'])
        
        track_html = f"""
        <div class="track-item" data-track-id="track{i}">
            <div class="track-info">
                <div class="track-title">{title}</div>
                <div class="track-details">
                    <span class="track-filename">{file_info['filename']}</span>
                    <span class="track-size">{file_size}</span>
                    <span class="track-format">{file_info['extension'].upper()}</span>
                </div>
            </div>
            <div class="track-controls">
                <button class="control-btn play-btn" onclick="playTrack('{file_info['path']}', '{title}')">
                    ▶
                </button>
                <button class="control-btn download-btn" onclick="downloadTrack('{file_info['path']}', '{file_info['filename']}')">
                    ⬇
                </button>
            </div>
        </div>"""
        
        tracks_html.append(track_html)
    
    return '\n'.join(tracks_html)

def update_music_html(music_files):
    """Update the music.html file with new track list"""
    try:
        # Read existing HTML file
        if MUSIC_HTML_FILE.exists():
            with open(MUSIC_HTML_FILE, 'r', encoding='utf-8') as f:
                html_content = f.read()
        else:
            print(f"{MUSIC_HTML_FILE} not found. Creating basic template...")
            html_content = create_basic_music_html()
        
        # Generate new tracks content
        tracks_content = generate_music_html_content(music_files)
        
        # Find and replace the playlist section
        playlist_start = html_content.find('<!-- MUSIC_TRACKS_START -->')
        playlist_end = html_content.find('<!-- MUSIC_TRACKS_END -->')
        
        if playlist_start != -1 and playlist_end != -1:
            # Replace the content between markers
            new_html = (
                html_content[:playlist_start + len('<!-- MUSIC_TRACKS_START -->')] +
                f'\n{tracks_content}\n        ' +
                html_content[playlist_end:]
            )
        else:
            # If markers not found, try to find playlist div
            playlist_start = html_content.find('<div class="playlist">')
            playlist_end = html_content.find('</div>', playlist_start)
            
            if playlist_start != -1 and playlist_end != -1:
                new_html = (
                    html_content[:playlist_start] +
                    f'<div class="playlist">\n        <!-- MUSIC_TRACKS_START -->\n{tracks_content}\n        <!-- MUSIC_TRACKS_END -->\n    ' +
                    html_content[playlist_end:]
                )
            else:
                # Add playlist section before closing body tag
                body_end = html_content.rfind('</body>')
                if body_end != -1:
                    playlist_html = f"""
    <div class="playlist">
        <!-- MUSIC_TRACKS_START -->
{tracks_content}
        <!-- MUSIC_TRACKS_END -->
    </div>
    
    <script>
        let currentAudio = null;
        
        function playTrack(path, title) {{
            console.log('Playing:', title, 'from', path);
            
            // Stop current audio if playing
            if (currentAudio) {{
                currentAudio.pause();
                currentAudio.currentTime = 0;
            }}
            
            // Create new audio element
            currentAudio = new Audio(path);
            currentAudio.play().catch(error => {{
                console.error('Error playing audio:', error);
                alert('Virhe äänen toistossa: ' + error.message);
            }});
            
            // Update button states
            document.querySelectorAll('.play-btn').forEach(btn => {{
                btn.textContent = '▶';
            }});
            
            // Find and update current button
            const button = event.target;
            button.textContent = '⏸';
            
            currentAudio.addEventListener('ended', () => {{
                button.textContent = '▶';
            }});
            
            currentAudio.addEventListener('pause', () => {{
                button.textContent = '▶';
            }});
        }}
        
        function downloadTrack(path, filename) {{
            const link = document.createElement('a');
            link.href = path;
            link.download = filename;
            link.click();
        }}
    </script>
"""
                    new_html = html_content[:body_end] + playlist_html + html_content[body_end:]
                else:
                    print("Could not find proper location to insert playlist.")
                    return False
        
        # Add timestamp comment
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        new_html = new_html.replace(
            '<!-- MUSIC_UPDATED_TIMESTAMP -->', 
            f'<!-- MUSIC_UPDATED_TIMESTAMP: {timestamp} -->'
        )
        
        # If timestamp marker doesn't exist, add it
        if '<!-- MUSIC_UPDATED_TIMESTAMP:' not in new_html:
            new_html = new_html.replace(
                '</head>',
                f'    <!-- MUSIC_UPDATED_TIMESTAMP: {timestamp} -->\n</head>'
            )
        
        # Write updated HTML
        with open(MUSIC_HTML_FILE, 'w', encoding='utf-8') as f:
            f.write(new_html)
        
        print(f"Successfully updated {MUSIC_HTML_FILE}")
        return True
        
    except Exception as e:
        print(f"Error updating HTML file: {e}")
        return False

def create_basic_music_html():
    """Create a basic music.html template if it doesn't exist"""
    return """<!DOCTYPE html>
<html lang="fi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Musiikki - XXMXLI</title>
    <link rel="stylesheet" href="styles.css">
    <!-- MUSIC_UPDATED_TIMESTAMP -->
</head>
<body>
    <header>
        <h1>Musiikki</h1>
        <nav>
            <a href="index.html">Etusivu</a>
            <a href="photography.html">Valokuvaus</a>
            <a href="music.html" class="active">Musiikki</a>
            <a href="projects-final.html">Projektit</a>
        </nav>
    </header>

    <main>
        <div class="playlist">
            <!-- MUSIC_TRACKS_START -->
            <!-- MUSIC_TRACKS_END -->
        </div>
    </main>
</body>
</html>"""

def save_music_data(music_files):
    """Save detailed music file data to JSON (legacy / extended data)."""
    data = {
        'last_updated': datetime.now().isoformat(),
        'total_files': len(music_files),
        'files': music_files
    }
    json_file = Path('assets/audio/music_data.json')  # moved to assets/audio for consistency
    json_file.parent.mkdir(parents=True, exist_ok=True)
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"Music data saved to {json_file}")

def save_tracklist_json(music_files, default_artist='n0rppa'):
    """Generate the simplified tracklist.json expected by the front-end player.
    Structure: [ {"file": filename, "title": title, "artist": artist, "duration": optional } ]
    Duration left blank (could be populated by a metadata library if desired).
    """
    tracklist = []
    for info in music_files:
        tracklist.append({
            'file': info['filename'],
            'title': extract_title_from_filename(info['filename']),
            'artist': default_artist,
            'duration': ''  # placeholder; computing requires extra dependency
        })
    TRACKLIST_JSON.parent.mkdir(parents=True, exist_ok=True)
    with open(TRACKLIST_JSON, 'w', encoding='utf-8') as f:
        json.dump(tracklist, f, indent=2, ensure_ascii=False)
    print(f"Tracklist saved to {TRACKLIST_JSON} ({len(tracklist)} tracks)")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Scan audio files and update tracklist.json (and optionally music.html).')
    parser.add_argument('--update-html', action='store_true', help='Also update music.html static playlist section (not needed for dynamic player).')
    parser.add_argument('--artist', default='n0rppa', help='Default artist name to embed in tracklist.json')
    args = parser.parse_args()

    print("=== Enhanced Music File Scanner ===")
    print(f"Scanning directory: {MUSIC_DIR.absolute()}")

    # Scan for music files
    music_files = scan_music_files()

    if music_files:
        # Save extended data & tracklist for player
        save_music_data(music_files)
        save_tracklist_json(music_files, default_artist=args.artist)

        # Optionally update static HTML (not required for JS player which reads JSON)
        if args.update_html:
            if update_music_html(music_files):
                print("\n✅ music.html updated successfully (static playlist).")
            else:
                print("\n❌ Failed to update music.html.")
        else:
            print("(Skipped updating music.html; JSON dynamic playlist in use.)")

        print(f"\n✅ Completed. Found {len(music_files)} audio files.")
    else:
        print(f"\n⚠️  No audio files found in {MUSIC_DIR}")
        print("Add audio files (.mp3, .flac, .wav, etc.) and run again.")

if __name__ == "__main__":
    main()