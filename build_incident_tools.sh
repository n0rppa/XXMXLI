#!/usr/bin/env bash
set -euo pipefail
# Build standalone executables for incident tools (Linux/macOS host).
# Requires: pip install pyinstaller

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OUT_DIR="dist_executables"
mkdir -p "$OUT_DIR"

PYTHON_BIN="${PYTHON_BIN:-python3}"

apps=(
  "automated_incident_reporter.py:incident-reporter"
  "EASY_LAUNCHER.py:incident-launcher"
)

for entry in "${apps[@]}"; do
  IFS=":" read -r script name <<<"$entry"
  echo "==> Building $script -> $name"
  $PYTHON_BIN -m PyInstaller --onefile --name "$name" "$script"
  mv -f "dist/$name"* "$OUT_DIR/" || true
  rm -rf build "$script.spec"
  echo "Built: $OUT_DIR/$name"
  echo
done

echo "All builds complete. Files in $OUT_DIR"