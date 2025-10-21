# XXMXLI Incident Reporter Launcher

Enhanced `EASY_LAUNCHER.py` adds robust diagnostics and clearer error output.

## Features Added
- Environment validation (checks existence of `automated_incident_reporter.py` and writability of `reports/`).
- Consistent command building using the currently running Python interpreter.
- Captures and displays stdout/stderr for both setup and report actions.
- GUI error dialogs now include command + exit code hints (argparse usage detection).
- CLI mode provides explicit remediation hints if argument parsing fails (exit code 2 or "usage:" detected).
 - Dry-run mode (`--dry-run`) to generate a full report JSON without simulated submission.
 - Evidence attachment support (`--evidence path` repeatable) with SHA-256 hash + size metadata.
 - Rotating log file at `logs/incident_reporter.log`.

## Usage
Double click `EASY_LAUNCHER.py` (GUI if Tk available) or run:

```bash
python EASY_LAUNCHER.py            # GUI if possible, else CLI fallback
python EASY_LAUNCHER.py --cli      # Force CLI mode
```

### CLI Flow
1. Choose setup or report.
2. For report you will be prompted for type, severity (1-10), description.

### Programmatic Report Example
Equivalent manual call the launcher wraps:
```bash
python automated_incident_reporter.py report --type DDOS --severity 7 --description "Edge device disconnect storm"
```

### With Evidence & Dry Run
```bash
python automated_incident_reporter.py report \
	--type INTRUSION \
	--severity 9 \
	--description "Brute force SSH from multiple IPs" \
	--evidence ./auth.log \
	--evidence ./fail2ban.log \
	--dry-run
```

## Troubleshooting
| Symptom | Cause | Fix |
|---------|-------|-----|
| Exit 127 / Executable not found | Python path invalid | Ensure Python is installed and on PATH or run with `py -3` on Windows |
| Exit 2 + usage text | Missing required flags | Supply all: `--type --severity --description` |
| Environment Error: Missing required script | File moved or deleted | Restore `automated_incident_reporter.py` in same directory |
| Cannot write to reports directory | Permissions issue | Run as admin or adjust directory permissions |
| Evidence NOT_FOUND | Wrong path | Verify file exists and pass absolute or correct relative path |

## Notes
- Severity must be integer 1–10.
- Incident type is uppercased automatically.
- Reports saved to `reports/XXMXLI_INC_<timestamp>.json`.
 - Evidence files are not copied (only metadata recorded) to avoid large storage bloat.

## Building Executables
Prereq: `pip install pyinstaller`

Linux / macOS:
```bash
./build_incident_tools.sh
```

Windows (PowerShell):
```powershell
./build_incident_tools.ps1 -Python python
```

Outputs go to `dist_executables/`.

## Next Ideas
- Optional secure upload integration endpoint
- Evidence archiving/compression toggle
- GUI progress log window
