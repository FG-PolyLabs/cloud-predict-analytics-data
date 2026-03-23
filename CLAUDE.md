# cloud-predict-analytics-data

## Multi-Repo Project: cloud-predict-analytics

This repo is **one of three** repositories that together form the cloud-predict-analytics system. All three repos should be cloned as siblings under the same parent directory.

### Repository Layout

```
FutureGadgetLabs/
├── cloud-predict-analytics-frontend-admin/   (admin UI — Hugo + Firebase Auth + GitHub Pages)
├── cloud-predict-analytics/                  (backend — Cloud Run API + scheduled jobs)
└── cloud-predict-analytics-data/             ← THIS REPO (static data files + public frontend)
```

### Repository Roles

| Repo | GitHub | Role |
|------|--------|------|
| `cloud-predict-analytics-frontend-admin` | https://github.com/FG-PolyLabs/cloud-predict-analytics-frontend-admin | Admin UI; reads JSONL from this repo via GitHub Raw |
| `cloud-predict-analytics` | https://github.com/FG-PolyLabs/cloud-predict-analytics | Backend — ingests Polymarket data into BigQuery; `weather-sync` job writes JSONL back to this repo |
| `cloud-predict-analytics-data` | https://github.com/FG-PolyLabs/cloud-predict-analytics-data | **This repo** — static JSONL data files updated by `weather-sync`; serves as GitHub Raw data source for frontends |

---

## This Repo: Data Files

### What it does

- Stores exported data as JSONL files in `data/` — written automatically by the `weather-sync` Cloud Run job in `cloud-predict-analytics`
- Serves as the **primary GitHub Raw data source** for the admin frontend — `loadFromGitHub()` fetches from this repo's `main` branch
- The GCS bucket `fg-polylabs-weather-data` is a parallel copy; `weather-sync` writes to both simultaneously
- `tracked_cities.jsonl` can also be manually edited and pushed here to bulk-reset the reference city list (loaded into BigQuery on push via CI/CD)

### GCP Infrastructure

| Resource | Details |
|----------|---------|
| GCP Project | `fg-polylabs` |
| GCS Bucket | `fg-polylabs-weather-data` (prefix: `data/`) — mirror of this repo's `data/` |
| BigQuery | Project `fg-polylabs`, dataset `weather` |
| Tables managed | `tracked_cities`, `polymarket_snapshots` (read-only from this repo's perspective) |

### Data Files

| File | Written by | Description |
|------|------------|-------------|
| `data/tracked_cities.jsonl` | `weather-sync` job (daily) or manual push | One JSON object per line. Composite key: `(source, city)`. Fields: `city`, `source`, `display_name`, `timezone`, `active`, `added_date`, `notes`. |
| `data/snapshots.jsonl` | `weather-sync` job (daily) | Polymarket prediction market snapshots. Fields: `city`, `source`, `date`, `timestamp`, `temp_threshold`, `yes_cost`, `no_cost`, `spread`, `volume_24h`, `volume_total`, `liquidity`, `event_slug`, `market_end_date`. |

### Code Structure

```
.
├── data/
│   ├── tracked_cities.jsonl   Canonical city list (source + city composite key)
│   └── snapshots.jsonl        Polymarket snapshot history (written by weather-sync)
├── schema/
│   └── tracked_cities.json    BigQuery table schema for tracked_cities
├── scripts/
│   ├── sync_to_gcs.sh         Upload data/ to GCS bucket
│   └── load_to_bq.sh          bq load from GCS into BigQuery (--replace)
└── .github/
    └── workflows/
        └── sync.yml           CI: sync_to_gcs + load_to_bq on push to main
```

### Development Notes

- `bq load --replace` overwrites the BQ `tracked_cities` table on every push — this repo is the seed/recovery source for cities, not the live write path
- Day-to-day city management is done through the admin frontend which writes directly to BigQuery via the backend API
- `snapshots.jsonl` is **never manually edited** — it is always written by the `weather-sync` job and can be very large (90 days × all cities × all thresholds)
- Push to this repo only when you want to reset or bulk-update the `tracked_cities` reference data
- The admin frontend reads JSON from this repo via GitHub Raw at: `https://raw.githubusercontent.com/FG-PolyLabs/cloud-predict-analytics-data/main/data/<filename>`
- To add a new table: add a `.jsonl` file to `data/`, add its schema to `schema/`, and update the CI workflow and `weather-sync` syncer accordingly
