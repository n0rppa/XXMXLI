#!/usr/bin/env python3
import os
import sys
import json
from pathlib import Path
from typing import Tuple

EXCLUDE_DIRS = {'.git', 'node_modules', 'dist', 'build', '__pycache__', '.venv', 'w'}

ROOT = Path(__file__).resolve().parents[1]

def should_exclude(path: Path) -> bool:
    parts = set(p for p in path.parts)
    return any(d in parts for d in EXCLUDE_DIRS)

def find_json_files(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        # Prune excluded directories in-place for efficiency
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
        cur = Path(dirpath)
        if should_exclude(cur):
            continue
        for name in filenames:
            if name.endswith('.json'):
                yield cur / name


def minify_json_file(path: Path, sort_keys: bool = True) -> Tuple[bool, str]:
    try:
        original = path.read_text(encoding='utf-8')
    except Exception as e:
        return False, f"skip: {path} (read error: {e})"

    try:
        data = json.loads(original)
    except Exception as e:
        return False, f"skip: {path} (parse error: {e})"

    try:
        compact = json.dumps(data, ensure_ascii=False, separators=(',', ':'), sort_keys=sort_keys)
    except Exception as e:
        return False, f"skip: {path} (dump error: {e})"

    # Only write if changed
    if compact != original:
        try:
            path.write_text(compact, encoding='utf-8')
            return True, f"updated: {path}"
        except Exception as e:
            return False, f"error: {path} (write error: {e})"
    else:
        return False, f"ok: {path} (no change)"


def main():
    root = ROOT
    changed = 0
    total = 0
    messages = []
    for jf in find_json_files(root):
        total += 1
        did, msg = minify_json_file(jf)
        if did:
            changed += 1
        messages.append(msg)

    print(f"Processed {total} JSON files; changed {changed}.")
    for m in messages:
        print(m)

if __name__ == '__main__':
    main()
