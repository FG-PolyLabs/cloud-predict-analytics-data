#!/usr/bin/env bash
# sync_to_gcs.sh — Upload all data files from data/ to the configured GCS bucket.
# Reads config from config.yaml. Requires: gsutil, python3 (for config parsing).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$REPO_ROOT/config.yaml"

# Parse config.yaml with Python (no extra dependencies required)
BUCKET=$(python3 -c "import yaml, sys; c=yaml.safe_load(open('$CONFIG')); print(c['gcs']['bucket'])")
PREFIX=$(python3 -c "import yaml, sys; c=yaml.safe_load(open('$CONFIG')); print(c['gcs']['data_prefix'])")

echo "Syncing $REPO_ROOT/data/ -> gs://$BUCKET/$PREFIX"
gsutil -m rsync -r -d "$REPO_ROOT/data/" "gs://$BUCKET/$PREFIX"
echo "Done."
