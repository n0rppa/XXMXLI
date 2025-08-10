# -*- coding: utf-8 -*-
import os
import re
import sys

# Configuration
GALLERY_DIR = "assets/images"
HTML_FILE = "photography.html"  # canonical target at repository root
START_MARK = "<!-- GALLERY_START -->"
END_MARK = "<!-- GALLERY_END -->"
EXPECTED_NUMBERS = {"22", "23", "24"}

# Ensure we run relative to script location
ROOT = os.path.dirname(os.path.abspath(__file__))
os.chdir(ROOT)

# Resolve absolute path to repository root photography.html (even if executed from subdirs)
# Walk upward until we find .git to mark the repository root.
def find_repo_root(start):
    cur = start
    while True:
        if os.path.isdir(os.path.join(cur, '.git')):
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            return start  # fallback
        cur = parent

REPO_ROOT = find_repo_root(ROOT)
HTML_FILE_PATH = os.path.join(REPO_ROOT, HTML_FILE)

# Detect other photography.html duplicates (exclude canonical) for informational warning
duplicate_paths = []
for dirpath, dirnames, filenames in os.walk(REPO_ROOT):
    # Skip .git directories quickly
    if '.git' in dirnames:
        dirnames.remove('.git')
    if dirpath.startswith(os.path.join(REPO_ROOT, 'XXMXLI') + os.sep):
        # Skip nested submodule copy named XXMXLI (if present)
        continue
    if 'photography.html' in filenames:
        full = os.path.join(dirpath, 'photography.html')
        if os.path.abspath(full) != os.path.abspath(HTML_FILE_PATH):
            duplicate_paths.append(full)

if duplicate_paths:
    print("INFO: Ignoring duplicate photography.html files (only root will be updated):")
    for p in duplicate_paths:
        print(" -", os.path.relpath(p, REPO_ROOT))

if not os.path.isdir(GALLERY_DIR):
    print(f"ERROR: Directory not found: {GALLERY_DIR}")
    sys.exit(1)

# Natural sort helper (so 2 comes before 10)
def natural_key(s):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r'(\d+)', s)]

# Collect images
images = [
    f for f in os.listdir(GALLERY_DIR)
    if f.lower().endswith((".jpg", ".jpeg", ".png", ".gif", ".webp")) and os.path.isfile(os.path.join(GALLERY_DIR, f))
]
images.sort(key=natural_key)

if not images:
    print("WARNING: No images found in gallery directory.")
else:
    print(f"Found {len(images)} images.")

# Debug: list images
for i, img in enumerate(images, 1):
    print(f"[{i:03}] {img}")

# Check expected numbered files (base name match before extension)
bases = {os.path.splitext(i)[0] for i in images}
missing = EXPECTED_NUMBERS - bases
if missing:
    print("NOTICE: Expected image base names missing:", ", ".join(sorted(missing)))
else:
    print("All expected numbered images present (22,23,24).")

# Build gallery HTML
parts = []
for img in images:
    rel_path = f"{GALLERY_DIR}/{img}"
    alt = os.path.splitext(img)[0]
    parts.append(
        "            <div class=\"grid-item\">\n"
        f"                <img src=\"{rel_path}\" loading=\"lazy\" alt=\"{alt}\">\n"
        "            </div>"
    )
new_gallery_block = "\n".join(parts) + "\n"

# Read HTML
try:
    with open(HTML_FILE_PATH, "r", encoding="utf-8") as f:
        html = f.read()
except FileNotFoundError:
    print(f"ERROR: HTML file not found at canonical path: {HTML_FILE_PATH}")
    sys.exit(1)

if START_MARK not in html or END_MARK not in html:
    print("ERROR: One or both gallery markers not found in canonical photography.html")
    sys.exit(1)

# Replace content between markers (first occurrence) using regex non-greedy
pattern = re.compile(re.escape(START_MARK) + r"(.*?)" + re.escape(END_MARK), re.DOTALL)
replacement = START_MARK + "\n" + new_gallery_block + "        " + END_MARK
new_html, count = pattern.subn(replacement, html, count=1)

if count == 0:
    print("ERROR: Failed to replace gallery section (regex did not match).")
    sys.exit(1)

with open(HTML_FILE_PATH, "w", encoding="utf-8") as f:
    f.write(new_html)

print("Gallery updated successfully at:", os.path.relpath(HTML_FILE_PATH, REPO_ROOT))