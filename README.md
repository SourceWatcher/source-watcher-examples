# Source Watcher - Example Pipelines

Example pipeline JSON files for the [Source Watcher API](https://github.com/TheCocoTeam/source-watcher-api), kept under `source-watcher-api/.source-watcher/transformations/` (or `~/.source-watcher/transformations/` when the API resolves the user home directory at run time).

Each file is validated against the [pipeline schema](https://raw.githubusercontent.com/TheCocoTeam/source-watcher-api/master/pipeline.schema.json). A pipeline is a `steps` array of extractors, transformers, and loaders.

---

## Prerequisites

- Source Watcher API running locally (default: `http://localhost:8181`)
- A valid JWT token (obtain via `POST /api/v1/credentials`)

Place `.json` pipeline files in this `transformations/` directory (API container: typically mounted as `/var/www/html/.source-watcher/transformations/`), then run them from the board UI or via `curl`.

**SQLite examples:** Loader paths in JSON use `/var/www/html/.source-watcher/*.db` (container). On your host, the same files usually live at `source-watcher-api/.source-watcher/*.db`. Run `sqlite3` against those paths from the repo root or use absolute paths.

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
| Output file | `.source-watcher/csv-lower.db` |

```bash
sqlite3 .source-watcher/csv-lower.db "SELECT * FROM people LIMIT 5;"
```

---

### `csv-lower-rename-to-sqlite`

**Steps:** CSV Extractor → Convert Case → Rename Columns → Database Loader

Same source CSV as above. Converts column names to lowercase, then renames `movie` to `preferred_movie` before loading into SQLite.

| Detail | Value |
|---|---|
| Source | `https://people.sc.fsu.edu/~jburkardt/data/csv/oscar_age_female.csv` |
| Output table | `people` |
| Output file | `.source-watcher/csv-lower-rename.db` |

```bash
sqlite3 .source-watcher/csv-lower-rename.db "SELECT * FROM people LIMIT 5;"
```

---

### `csv-title-rename-to-sqlite-1`

**Steps:** CSV Extractor → Convert Case (title) → Rename Columns → Database Loader

Fetches the Oscar CSV, applies Title Case to the `Movie` column name, then renames `Movie` to `Preferred_Movie`.

| Detail | Value |
|---|---|
| Source | `https://people.sc.fsu.edu/~jburkardt/data/csv/oscar_age_female.csv` |
| Output table | `people` |
| Output file | `.source-watcher/csv-title-rename-1.db` |

> **`csv-title-rename-to-sqlite-2`** and **`csv-title-rename-to-sqlite-3`** write to `csv-title-rename-2.db` and `csv-title-rename-3.db` and use different `RenameColumns` option shapes (lowercase `movie`, and quoted keys in JSON). After the Title `ConvertCase` step, the column key is still `Movie`; variant **2** maps from `movie`, which **does not** match `Movie` unless you add a step that lowercases that column name first—treat **2** and **3** as mapping-style experiments, not guaranteed end-to-end demos.

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

Same CVE source as above, but extracts deeper nested fields - including arrays stored as JSON strings - giving a richer view of the record.

| Detail | Value |
|---|---|
| Source | `https://cveawg.mitre.org/api/cve/CVE-2026-3494` |
| Columns | `dataType`, `dataVersion`, `cveId`, `state`, `assignerShortName`, `datePublished`, `dateUpdated`, `title`, `descriptionText`, `descriptionsJson`, `affectedJson`, `metricsJson`, `referencesJson`, `problemTypesJson` |
| Output table | `cve_deep` |
| Output file | `.source-watcher/cve-json-deep.db` |

```bash
sqlite3 .source-watcher/cve-json-deep.db "SELECT cveId, title, descriptionText FROM cve_deep;"
```

---

### `chinook-artists-to-sqlite`

**Steps:** Database Extractor (remote SQLite URL) → Database Loader

Downloads the [Chinook sample database](https://github.com/lerocha/chinook-database) directly from a public URL, runs a SQL JOIN query across `Artist` and `Album` tables, and loads the top 50 results into a local SQLite database.

Demonstrates the remote SQLite file download capability of the Database extractor.

| Detail | Value |
|---|---|
| Source | `https://raw.githubusercontent.com/lerocha/chinook-database/refs/heads/master/ChinookDatabase/DataSources/Chinook_Sqlite.sqlite` |
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

Reads a plain text file line by line (each line becomes one row in the `line` column). **`ConvertCase` renames column keys, not cell values:** with `mode: title` on `line`, the attribute becomes **`Line`** (title case of the name `line`); the text on each row is unchanged. Loads into SQLite.

| Detail | Value |
|---|---|
| Source | `/var/www/html/.source-watcher/data/sample.txt` (local file inside the container) |
| Output table | `lines` |
| Output file | `.source-watcher/txt-lines.db` |

```bash
sqlite3 .source-watcher/txt-lines.db "SELECT * FROM lines;"
```

---

### `find-missing-ids`

**Steps:** CSV Extractor → Find Missing From Sequence → Database Loader

Reads a CSV file containing a numeric `id` column with intentional gaps (`1, 2, 3, 5, 6, 9, 10`), finds the missing integers in the sequence (`4, 7, 8`), and writes them to a SQLite table.

Demonstrates the `FindMissingFromSequenceExtractor`, which chains from the previous extractor's result, sorts the numeric column, and outputs any integers absent between the min and max values.

| Detail | Value |
|---|---|
| Source | `.source-watcher/data/sample-sequence.csv` (local) |
| Sequence column | `id` |
| Output table | `missing_ids` |
| Output file | `.source-watcher/find-missing-ids.db` |

```bash
sqlite3 .source-watcher/find-missing-ids.db "SELECT * FROM missing_ids;"
# Expected: rows with id = 4, 7, 8
```

---

### `guess-gender-from-names`

**Steps:** CSV Extractor → Guess Gender → Database Loader

Reads a CSV with `id`, `first_name`, and `last_name` columns, uses a name dictionary to guess the gender from the `first_name` column, adds a `gender` column to each row, and loads the enriched data into SQLite.

| Detail | Value |
|---|---|
| Source | `.source-watcher/data/sample-names.csv` (local) |
| First name column | `first_name` |
| Output gender column | `gender` |
| Country dictionary | `usa` |
| Output table | `people_with_gender` |
| Output file | `.source-watcher/guess-gender.db` |

```bash
sqlite3 .source-watcher/guess-gender.db "SELECT first_name, last_name, gender FROM people_with_gender;"
```

> The transformer only fills in the `gender` column if it is currently empty. Rows that already have a value are left unchanged.

---

### `ocr-image-to-sqlite`

**Steps:** Tesseract OCR Extractor → Database Loader

Extracts text from a local image file (PNG, JPEG, TIFF, etc.) using Tesseract. Each non-empty line of OCR output becomes one row.

| Detail | Value |
|---|---|
| Source | `/var/www/html/.source-watcher/data/image-with-text.jpg` (place your own image in `.source-watcher/data/`) |
| Output table | `ocr_lines` |
| Output file | `.source-watcher/ocr-output.db` |

**Prerequisites:** `tesseract-ocr` (and language data, e.g. `tesseract-ocr-eng`) installed in the API container.

```bash
sqlite3 .source-watcher/ocr-output.db "SELECT * FROM ocr_lines LIMIT 10;"
```

---

### `ocr-pdf-to-sqlite`

**Steps:** PDF Extractor → Database Loader

Extracts text from any PDF (text-layer, scanned, or mixed). Uses `pdftotext` when a page has enough embedded text; otherwise renders the page and runs Tesseract OCR.

| Detail | Value |
|---|---|
| Source | `/var/www/html/.source-watcher/data/sample.pdf` (replace with your PDF path) |
| Output table | `pdf_lines` |
| Output file | `.source-watcher/pdf-output.db` |
| Options | `column` (default `text`), `pageColumn` (default `page`; use `""` to omit page numbers), `language` (Tesseract code for OCR fallback, default `eng`) |

**Prerequisites:** `poppler-utils` and `tesseract-ocr` in the API container.

```bash
sqlite3 .source-watcher/pdf-output.db "SELECT page, text FROM pdf_lines LIMIT 20;"
```

---

### `test-error-reporting` (development)

Intentionally invalid pipeline (empty `filePath` on the CSV step) used to verify API/board error responses. Not a runnable example for end users.

---

## File format reference

Each pipeline file is a JSON object with a `$schema` reference and a `steps` array:

```json
{
  "$schema": "https://raw.githubusercontent.com/TheCocoTeam/source-watcher-api/master/pipeline.schema.json",
  "steps": [
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
}
```

| Field | Description |
|---|---|
| `$schema` | Points to the pipeline JSON Schema for editor validation and autocomplete |
| `type` | `extractor`, `execution-extractor`, `transformer`, or `loader` |
| `name` | Core step name (e.g. `Csv`, `Json`, `ConvertCase`, `Database`) |
| `options` | Step-specific configuration |
| `x`, `y` | Canvas position (used by the board UI; ignored by the API) |
