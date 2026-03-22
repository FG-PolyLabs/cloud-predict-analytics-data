# cloud-predict-analytics-data

Git-as-source-of-truth for the **`fg-polylabs.weather`** BigQuery reference tables. This repo ensures reference data (city configuration, etc.) remains permanently accessible even if GCP billing is disrupted — Git is always available, GCS and BigQuery are not.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Git repository  (this repo — always available)     │
│  data/*.jsonl  ←  source of truth for all records   │
└────────────────────────┬────────────────────────────┘
                         │ GitHub Actions (on push to main)
          ┌──────────────▼──────────────┐
          │   Google Cloud Storage      │
          │   gs://fg-polylabs-data/    │
          └──────────────┬──────────────┘
                         │ bq load --replace
          ┌──────────────▼──────────────┐
          │   BigQuery                  │
          │   fg-polylabs.weather.*     │
          └──────────────┬──────────────┘
                         │ REST API
          ┌──────────────▼──────────────┐
          │   Cloud Run (backend API)   │
          │   + Frontend Admin          │
          └─────────────────────────────┘
```

> **Note:** `bq load --replace` overwrites the BQ table on every push. This repo is the canonical seed/recovery source. Day-to-day city management is done through the admin frontend, which writes directly to BigQuery via the backend API — push to this repo only when you want to reset or bulk-update the reference data.

## Tables managed here

### `fg-polylabs.weather.tracked_cities`

Controls which cities the Cloud Run Job fetches Polymarket weather market data for. The scheduler reads `WHERE active = TRUE` on each run.

| Column | Type | Description |
|---|---|---|
| `city` | STRING (REQUIRED) | Polymarket slug, e.g. `london`, `nyc`, `buenos-aires` |
| `display_name` | STRING (REQUIRED) | Human-readable name, e.g. `London`, `New York` |
| `timezone` | STRING (REQUIRED) | IANA timezone, e.g. `Europe/London` |
| `active` | BOOL (REQUIRED) | `false` pauses tracking without deleting the row |
| `added_date` | DATE (REQUIRED) | Date added to tracking |
| `notes` | STRING (NULLABLE) | Optional free-text notes |

**Currently tracked cities (12):**

| City | Slug | Timezone |
|---|---|---|
| London | `london` | Europe/London |
| Singapore | `singapore` | Asia/Singapore |
| Paris | `paris` | Europe/Paris |
| Tokyo | `tokyo` | Asia/Tokyo |
| New York | `nyc` | America/New_York |
| Chicago | `chicago` | America/Chicago |
| Miami | `miami` | America/New_York |
| Dallas | `dallas` | America/Chicago |
| Toronto | `toronto` | America/Toronto |
| Seoul | `seoul` | Asia/Seoul |
| Ankara | `ankara` | Europe/Istanbul |
| Buenos Aires | `buenos-aires` | America/Argentina/Buenos_Aires |

## Repository layout

```
.
├── config.yaml                    # GCP project, bucket, dataset, table names
├── data/
│   └── tracked_cities.jsonl       # Reference city list (one JSON object per line)
├── schema/
│   └── tracked_cities.json        # BigQuery table schema
├── scripts/
│   ├── sync_to_gcs.sh             # Upload data/ to GCS
│   └── load_to_bq.sh              # Load from GCS into BigQuery
└── .github/
    └── workflows/
        └── sync.yml               # CI: run both scripts on every push to main
```

## Adding or modifying cities

**For immediate effect** (no GCP disruption): use the [Admin Frontend](https://github.com/FG-PolyLabs/cloud-predict-analytics-frontend-admin) to add/edit/pause cities via the UI — changes are written directly to BigQuery.

**To update the canonical seed data** (and sync to BQ): edit `data/tracked_cities.jsonl` and push to `main`. GitHub Actions will overwrite the BQ table with the file contents.

To add a city, append a line to `data/tracked_cities.jsonl`:
```json
{"city": "sydney", "display_name": "Sydney", "timezone": "Australia/Sydney", "active": true, "added_date": "2026-03-21", "notes": null}
```

To pause a city, set `"active": false` for that row.

## Setup

### 1. GitHub secrets

| Secret | Value |
|---|---|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity provider resource name |
| `GCP_SERVICE_ACCOUNT` | Service account email with Storage + BigQuery permissions |

### 2. Run locally

```bash
gcloud auth application-default login
pip install pyyaml

bash scripts/sync_to_gcs.sh
bash scripts/load_to_bq.sh
```

## License

GPL-3.0 — see [LICENSE](LICENSE).
