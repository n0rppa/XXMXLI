#!/usr/bin/env bash
# DEPRECATED wrapper: use ../../deploy_ip_blocking_optimized.sh directly.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
echo "[WARN] This path is deprecated. Redirecting to $REPO_ROOT/deploy_ip_blocking_optimized.sh" >&2
exec "$REPO_ROOT/deploy_ip_blocking_optimized.sh" "$@"
