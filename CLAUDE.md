# cloud-predict-analytics-data

## Multi-Repo Project: cloud-predict-analytics

This repo is **one of three** repositories that together form the cloud-predict-analytics system. All three repos should be cloned as siblings under the same parent directory.

### Repository Layout

```
FutureGadgetLabs/
├── cloud-predict-analytics-frontend-admin/   (admin UI — Hugo + Firebase Auth + GitHub Pages)
├── cloud-predict-analytics/                  (backend — CLI + future Cloud Run API/job)
└── cloud-predict-analytics-data/             ← THIS REPO (reference data + BQ seed)
```

### Repository Roles

| Repo | GitHub | Role |
|------|--------|------|
| `cloud-predict-analytics-frontend-admin` | https://github.com/FG-PolyLabs/cloud-predict-analytics-frontend-admin | Admin UI; reads JSON from this repo via GitHub Raw |
| `cloud-predict-analytics` | https://github.com/FG-PolyLabs/cloud-predict-analytics | Backend — ingests Polymarket data into BigQuery |
| `cloud-predict-analytics-data` | https://github.com/FG-PolyLabs/cloud-predict-analytics-data | **This repo** — canonical reference data (JSONL → GCS → BigQuery) |

---

## This Repo: Reference Data

### What it does

- Stores canonical reference data (e.g. `tracked_cities`) as JSONL files in `data/`
- On every push to `main`, GitHub Actions syncs `data/` to GCS (`weather-data` bucket) and loads it into BigQuery (`fg-polylabs.weather.*`)
- Also serves as the **GitHub Raw data source** for the admin frontend — `loadJsonData()` in the admin frontend fetches from this repo's `main` branch

### GCP Infrastructure

| Resource | Details |
|----------|---------|
| GCP Project | `fg-polylabs` |
| GCS Bucket | `weather` (prefix: `data/`) |
| BigQuery | Project `fg-polylabs`, dataset `weather` |
| Tables managed | `tracked_cities` |

### Code Structure

```
.
├── config.yaml                    # GCP project, bucket, dataset, table names
├── data/
│   └── tracked_cities.jsonl       # One JSON object per line — canonical city list
├── schema/
│   └── tracked_cities.json        # BigQuery table schema
├── scripts/
│   ├── sync_to_gcs.sh             # Upload data/ to GCS
│   └── load_to_bq.sh              # bq load from GCS into BigQuery (--replace)
└── .github/
    └── workflows/
        └── sync.yml               # CI: sync_to_gcs + load_to_bq on push to main
```

### Development Notes

- `bq load --replace` overwrites the BQ table on every push — this repo is the seed/recovery source, not the live write path
- Day-to-day city management is done through the admin frontend which writes directly to BigQuery via the backend API
- Push to this repo only when you want to reset or bulk-update reference data
- The admin frontend reads JSON from this repo via GitHub Raw at: `https://raw.githubusercontent.com/FG-PolyLabs/cloud-predict-analytics-data/main/<filename>`
- To add a new table: add a `.jsonl` file to `data/`, add its schema to `schema/`, and add the table name to `config.yaml`
