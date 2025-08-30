#!/bin/bash
# Automatic IP blocking based on failed attempts
THRESHOLD=5
LOG_FILE="/var/log/apache2/access.log"
BLOCK_FILE=".htaccess"

if [ -f "$LOG_FILE" ]; then
    # Find IPs with excessive 403 responses
    tail -1000 "$LOG_FILE" | awk '$9 == "403" {print $1}' | sort | uniq -c | sort -nr | while read count ip; do
        if [ $count -ge $THRESHOLD ]; then
            if ! grep -q "Require not ip $ip" "$BLOCK_FILE" 2>/dev/null; then
                echo "Require not ip $ip" >> "$BLOCK_FILE"
                echo "$(date): Auto-blocked $ip after $count attempts" >> logs/auto_blocking.log
            fi
        fi
    done
fi
