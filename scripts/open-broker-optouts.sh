#!/usr/bin/env bash
# Open common broker opt-out pages in default browser (EU relevance varies)
# Usage: ./scripts/open-broker-optouts.sh
set -euo pipefail

URLS=(
  "https://privacyportal.onetrust.com/webform/4c46b8e8-70dc-4b8b-8ad7-9a071e4d1eae/4f4d4fbe-a13b-4ef8-b24a-0f3c99d1b5b3" # ZoomInfo DSAR
  "https://privacyportal-de.onetrust.com/webform/3e9a8a64-0d12-4bf3-bbe4-f1b8ee2b50b4/d3652c6b-b4b5-4d9a-9b9f-06e1c5c5a62e" # Clearbit DSAR
  "https://optout.liveramp.com/opt_out" # LiveRamp opt-out
  "https://www.acxiom.com/privacy/us-citizen-privacy-policy/opt-out/" # Acxiom (US-centric)
  "https://www.whitepages.com/remove-me" # Whitepages
  "https://www.intelius.com/opt-out/" # Intelius
  "https://www.beenverified.com/opt-out/" # BeenVerified
  "https://radaris.com/page/optout/" # Radaris
)

for u in "${URLS[@]}"; do
  xdg-open "$u" >/dev/null 2>&1 || true
  sleep 0.5
done

echo "Opened ${#URLS[@]} opt-out pages."
