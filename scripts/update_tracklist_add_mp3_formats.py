#!/usr/bin/env python3
import json
from pathlib import Path

audio_dir = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
tracklist_file = audio_dir / 'tracklist_complete_all.json'

with open(tracklist_file, 'r') as f:
    tracks = json.load(f)

existing = {p.name for p in audio_dir.iterdir() if p.is_file()}

for t in tracks:
    fmts = list(dict.fromkeys(t.get('formats', [])))
    base = Path(t['file']).stem
    # Add mp3 if exists
    mp3 = f"{base}.mp3"
    if mp3 in existing and mp3 not in fmts:
        fmts.insert(0, mp3)
    # Ensure primary file prefers mp3 when present
    if mp3 in fmts:
        t['file'] = mp3
    t['formats'] = fmts

with open(tracklist_file, 'w') as f:
    json.dump(tracks, f, indent=2)

print(f"Updated {tracklist_file} with MP3 where available.")
