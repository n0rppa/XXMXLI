#!/usr/bin/env bash
set -euo pipefail
# Convert all non-MP3 audio files in assets/audio to MP3, side-by-side
# Requires: ffmpeg

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)/assets/audio"
cd "$SRC_DIR"

echo "Converting audio to MP3 in: $SRC_DIR"
shopt -s nullglob
for f in *.flac *.m4a *.wav *.ogg; do
  [ -e "$f" ] || continue
  base="${f%.*}"
  out="$base.mp3"
  if [[ -f "$out" ]]; then
    echo "Skipping $f -> $out (already exists)"
    continue
  fi
  echo "ffmpeg -y -i '$f' -codec:a libmp3lame -b:a 192k '$out'"
  ffmpeg -y -i "$f" -codec:a libmp3lame -b:a 192k "$out"
  echo "Created: $out"
done

echo "Done."
