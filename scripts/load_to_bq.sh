#!/usr/bin/env bash
# load_to_bq.sh — Load each JSONL file from GCS into its corresponding BigQuery table.
# Table names are derived from filenames in data/ (e.g. items.jsonl -> <dataset>.items).
# Schema files must exist in schema/<table>.json.
# Reads config from config.yaml. Requires: bq CLI, python3.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$REPO_ROOT/config.yaml"

PROJECT=$(python3 -c "import yaml; c=yaml.safe_load(open('$CONFIG')); print(c['gcp']['project_id'])")
BUCKET=$(python3 -c  "import yaml; c=yaml.safe_load(open('$CONFIG')); print(c['gcs']['bucket'])")
PREFIX=$(python3 -c  "import yaml; c=yaml.safe_load(open('$CONFIG')); print(c['gcs']['data_prefix'])")
DATASET=$(python3 -c "import yaml; c=yaml.safe_load(open('$CONFIG')); print(c['bigquery']['dataset'])")
TABLES=$(python3 -c  "import yaml; c=yaml.safe_load(open('$CONFIG')); print('\n'.join(c['bigquery']['tables']))")

while IFS= read -r TABLE; do
  GCS_URI="gs://$BUCKET/${PREFIX}${TABLE}.jsonl"
  SCHEMA="$REPO_ROOT/schema/$TABLE.json"

  echo "Loading $GCS_URI -> $PROJECT:$DATASET.$TABLE"
  bq load \
    --project_id="$PROJECT" \
    --source_format=NEWLINE_DELIMITED_JSON \
    --replace \
    "$DATASET.$TABLE" \
    "$GCS_URI" \
    "$SCHEMA"
done <<< "$TABLES"

echo "Done."
