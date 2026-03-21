# Source Watcher — Example Pipelines

This repository contains ready-to-run example pipelines for [Source Watcher](https://github.com/TheCocoTeam/source-watcher-api).

Each file uses the `.swt` (Source Watcher Transformation) format — a JSON array of steps (extractors, transformers, loaders) that define a pipeline.

---

## Prerequisites

- Source Watcher API running locally (default: `http://localhost:8181`)
- A valid JWT token (obtain via `POST /api/v1/credentials`)

Place `.swt` files inside `.source-watcher/transformations/` in the API container's working directory, then run them from the board UI or via `curl`.

### Run via curl

```bash
TOKEN="your_jwt_token_here"

curl -X POST http://localhost:8181/api/v1/transformation-run \
  -H "Content-Type: application/json" \
  -H "x-access-token: $TOKEN" \
  -d '{"name": "pipeline-name-without-extension"}'
```

### Run via the board UI

1. Open the board at `http://localhost:8282`
2. Select the pipeline from the dropdown
3. Click **Load**, draw connections between steps, then click **Run Saved**

---

## Pipelines

### `csv-lower-to-sqlite`

**Steps:** CSV Extractor → Convert Case → Database Loader

Fetches the [Oscar Female Winners CSV](https://people.sc.fsu.edu/~jburkardt/data/csv/oscar_age_female.csv) from a public URL, converts the `Year`, `Name`, and `Movie` column names to lowercase, and loads the result into a local SQLite database.

| Detail | Value |
|---|---|
| Source | `https://people.sc.fsu.edu/~jburkardt/data/csv/oscar_age_female.csv` |
| Output table | `people` |
| Output file | `.source-watcher/test-jp.db` |

```bash
sqlite3 .source-watcher/test-jp.db "SELECT * FROM people LIMIT 5;"
```

---

### `csv-lower-rename-to-sqlite`

**Steps:** CSV Extractor → Convert Case → Rename Columns → Database Loader

Same source CSV as above. Converts column names to lowercase, then renames `movie` to `preferred_movie` before loading into SQLite.

| Detail | Value |
|---|---|
| Source | `https://people.sc.fsu.edu/~jburkardt/data/csv/oscar_age_female.csv` |
| Output table | `people` |
| Output file | `.source-watcher/test-2-jp.db` |

```bash
sqlite3 .source-watcher/test-2-jp.db "SELECT * FROM people LIMIT 5;"
```

---

### `csv-title-rename-to-sqlite-1`

**Steps:** CSV Extractor → Convert Case (title) → Rename Columns → Database Loader

Fetches the Oscar CSV, applies Title Case to the `Movie` column name, then renames `Movie` to `Preferred_Movie`.

| Detail | Value |
|---|---|
| Source | `https://people.sc.fsu.edu/~jburkardt/data/csv/oscar_age_female.csv` |
| Output table | `people` |
| Output file | `.source-watcher/test-jp.db` |

> `csv-title-rename-to-sqlite-2` and `csv-title-rename-to-sqlite-3` are variants testing different column mapping styles.

---

### `cve-json-to-sqlite`

**Steps:** JSON Extractor (URL) → Database Loader

Fetches the CVE record for [CVE-2026-3494](https://cveawg.mitre.org/api/cve/CVE-2026-3494) from the MITRE CVE API and extracts top-level metadata fields into a SQLite table using JSONPath mappings.

| Detail | Value |
|---|---|
| Source | `https://cveawg.mitre.org/api/cve/CVE-2026-3494` |
| Columns | `dataType`, `dataVersion`, `cveId`, `state`, `assignerShortName`, `dateReserved`, `datePublished`, `dateUpdated`, `title` |
| Output table | `cve_metadata` |
| Output file | `.source-watcher/cve-metadata.db` |

```bash
sqlite3 .source-watcher/cve-metadata.db "SELECT cveId, title, state FROM cve_metadata;"
```

---

### `cve-json-deep-to-sqlite`

**Steps:** JSON Extractor (URL) → Database Loader

Same CVE source as above, but extracts deeper nested fields — including arrays stored as JSON strings — giving a richer view of the record.

| Detail | Value |
|---|---|
| Source | `https://cveawg.mitre.org/api/cve/CVE-2026-3494` |
| Columns | `dataType`, `dataVersion`, `cveId`, `state`, `assignerShortName`, `datePublished`, `dateUpdated`, `title`, `descriptionText`, `descriptionsJson`, `affectedJson`, `metricsJson`, `referencesJson`, `problemTypesJson` |
| Output table | `cve_deep` |
| Output file | `.source-watcher/cve-deep-3.db` |

```bash
sqlite3 .source-watcher/cve-deep-3.db "SELECT cveId, title, descriptionText FROM cve_deep;"
```

---

### `chinook-artists-to-sqlite`

**Steps:** Database Extractor (remote SQLite URL) → Database Loader

Downloads the [Chinook sample database](https://github.com/lerocha/chinook-database) directly from a public URL, runs a SQL JOIN query across `Artist` and `Album` tables, and loads the top 50 results into a local SQLite database.

Demonstrates the remote SQLite file download capability of the Database extractor.

| Detail | Value |
|---|---|
| Source | Chinook SQLite via `https://raw.githubusercontent.com/...` |
| Query | `SELECT ArtistId, Name AS ArtistName, Title AS AlbumTitle FROM Artist JOIN Album … LIMIT 50` |
| Output table | `artist_albums` |
| Output file | `.source-watcher/chinook-artists.db` |

```bash
sqlite3 .source-watcher/chinook-artists.db "SELECT * FROM artist_albums LIMIT 10;"
```

> **Note:** Requires `allow_url_fopen = On` in the PHP container (enabled by default).

---

### `txt-to-sqlite`

**Steps:** Txt Extractor → Convert Case → Database Loader

Reads a plain text file line by line (each line becomes one row), applies Title Case to the line content, and loads into SQLite.

| Detail | Value |
|---|---|
| Source | `/var/www/html/.source-watcher/data/sample.txt` (local file inside the container) |
| Output table | `lines` |
| Output file | `.source-watcher/txt-lines.db` |

```bash
sqlite3 .source-watcher/txt-lines.db "SELECT * FROM lines;"
```

---

## File format reference

Each `.swt` file is a JSON array. Each element is a step:

```json
[
  {
    "type": "extractor",
    "name": "Csv",
    "options": { "filePath": "...", "columns": ["A", "B"] },
    "x": 80,
    "y": 100
  },
  {
    "type": "loader",
    "name": "Database",
    "options": { "driver": "pdo_sqlite", "tableName": "my_table", "path": "/path/to/output.db" },
    "x": 300,
    "y": 100
  }
]
```

| Field | Description |
|---|---|
| `type` | `extractor`, `execution-extractor`, `transformer`, or `loader` |
| `name` | Core step name (e.g. `Csv`, `Json`, `ConvertCase`, `Database`) |
| `options` | Step-specific configuration |
| `x`, `y` | Canvas position (used by the board UI; ignored by the API) |
