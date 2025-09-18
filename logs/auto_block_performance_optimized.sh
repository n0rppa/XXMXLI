#!/bin/bash
set -e
set -u
set -o pipefail
# Automatic IP blocking based on failed attempts
THRESHOLD=5
LOG_FILE="/var/log/apache2/access.log"
BLOCK_FILE=".htaccess"

if [ -f "$LOG_FILE" ]; then
    # Find IPs with excessive 403 responses
    tail -1000 "$LOG_FILE" | awk '$9 == "403" {print $1}' | sort | uniq -c | sort -nr | while read count ip; do
        if [ $count -ge $THRESHOLD ]; then

# Optimized search function with timeout protection
optimized_search() {
    local pattern="$1"
    local file="$2"
    local timeout="${3:-30}"
    
    for tool in rg ag awk grep; do
        if command -v "$tool" >/dev/null 2>&1; then
            case "$tool" in
                "rg") timeout "$timeout" rg --color=never "$pattern" "$file" 2>/dev/null && return 0 ;;
                "ag") timeout "$timeout" ag --nocolor "$pattern" "$file" 2>/dev/null && return 0 ;;
                "awk") timeout "$timeout" awk "/$pattern/" "$file" 2>/dev/null && return 0 ;;
                "grep") timeout "$timeout" grep "$pattern" "$file" 2>/dev/null && return 0 ;;
            esac
        fi
    done
    return 1
}

            if ! grep -q "Require not ip $ip" "$BLOCK_FILE" 2>/dev/null; then
                echo "Require not ip $ip" >> "$BLOCK_FILE"
                echo "$(date): Auto-blocked $ip after $count attempts" >> logs/auto_blocking.log
            fi
        fi
    done
fi
