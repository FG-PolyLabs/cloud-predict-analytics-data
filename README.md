# bq-cr-gcs-git-architecture-data-template

A generic template for the **BigQuery + Cloud Run + GCS + Git** data architecture — a pattern that keeps data permanently accessible even when GCP billing is disrupted, by treating this Git repository as the source of truth.

## Architecture overview

```
┌─────────────────────────────────────────────────────┐
│  Git repository  (this repo — always available)     │
│  data/*.jsonl  ←  source of truth for all records   │
└────────────────────────┬────────────────────────────┘
                         │ GitHub Actions (on push to main)
          ┌──────────────▼──────────────┐
          │   Google Cloud Storage      │
          │   gs://<bucket>/data/       │
          └──────────────┬──────────────┘
                         │ bq load
          ┌──────────────▼──────────────┐
          │        BigQuery             │
          │   <dataset>.<table>         │
          └──────────────┬──────────────┘
                         │ SQL / REST API
          ┌──────────────▼──────────────┐
          │        Cloud Run            │
          │   frontend / API service    │
          └─────────────────────────────┘
```

**Why Git as source of truth?**
GCP billing outages (or account suspensions) take down GCS, BigQuery, and Cloud Run simultaneously. Because all data is committed here, a separate static host or CDN can serve directly from the raw GitHub URLs with zero GCP dependency.

## Repository layout

```
.
├── config.yaml              # GCP project, bucket, dataset, table names
├── data/
│   └── items.jsonl          # Newline-delimited JSON data files (one per BQ table)
├── schema/
│   └── items.json           # BigQuery table schemas
├── scripts/
│   ├── sync_to_gcs.sh       # Upload data/ to GCS
│   └── load_to_bq.sh        # Load from GCS into BigQuery
└── .github/
    └── workflows/
        └── sync.yml         # CI: run both scripts on every push to main
```

## Setup

### 1. Fill in `config.yaml`

Replace the placeholder values:

```yaml
gcp:
  project_id: my-gcp-project

gcs:
  bucket: my-data-bucket
  data_prefix: data/

bigquery:
  dataset: my_dataset
  tables:
    - items
```

### 2. Configure GitHub secrets

| Secret | Value |
|---|---|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity provider resource name |
| `GCP_SERVICE_ACCOUNT` | Service account email with Storage and BigQuery permissions |

See [google-github-actions/auth](https://github.com/google-github-actions/auth) for how to set up keyless authentication via Workload Identity Federation.

### 3. Add your data

- Add `data/<table>.jsonl` files (one JSON object per line).
- Add a matching `schema/<table>.json` BigQuery schema file.
- Register the table name under `bigquery.tables` in `config.yaml`.

### 4. Push to `main`

The GitHub Actions workflow triggers automatically and syncs everything to GCS and BigQuery.

## Running scripts locally

```bash
# Authenticate first
gcloud auth application-default login

pip install pyyaml

bash scripts/sync_to_gcs.sh
bash scripts/load_to_bq.sh
```

## License

GPL-3.0 — see [LICENSE](LICENSE).
