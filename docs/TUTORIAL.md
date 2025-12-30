# Data Platform Demo (MinIO + Polaris + Trino + Kyuubi)

This guide spins up a local, air-gapped demo to explore an Iceberg-based lakehouse with Polaris as the REST catalog, Trino for interactive SQL, Kyuubi/Spark for notebooks or JDBC/ODBC, and MinIO as the object store. It also shows where to find audit/lineage metadata and includes a PySpark sample.

> **Note:** Polaris uses H2 in-memory database for this demo. Credentials are randomly generated on startup and must be extracted from logs (see step 2).

## 1) Bring the stack up

```bash
# from the repo root
docker compose up -d

# Verify services are running
docker compose ps

# Expected status: all containers running
# - polaris (health: starting)
# - minio (healthy)
# - trino (health: starting)
# - kyuubi (health: starting)
```

Services/ports:
- MinIO API: http://localhost:9000
- MinIO Console: http://localhost:9001 (user: minioadmin, pass: minioadmin)
- Polaris REST API: http://localhost:8181
- Trino SQL: http://localhost:8080
- Kyuubi Thrift: localhost:10009

## 2) Extract Polaris credentials

Polaris generates random credentials on startup. Extract them automatically:

```bash
# Extract credentials and obtain OAuth token
bash scripts/get_polaris_token.sh

# This creates .polaris-env with environment variables:
# - CLIENT_ID
# - CLIENT_SECRET
# - ACCESS_TOKEN
# - POLARIS_HOST
# - POLARIS_PORT

# Source for use in subsequent API calls
source .polaris-env

# Verify token works
curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8181/api/catalog/v1/config | jq .
```

## 3) Bootstrap storage

Create the warehouse bucket that Iceberg will use.

```bash
# Access MinIO within the Docker network
docker exec demo-data-platform-query-minio-1 /usr/bin/mc alias set local http://localhost:9000 minioadmin minioadmin

# Create the demo warehouse bucket
docker exec demo-data-platform-query-minio-1 /usr/bin/mc mb local/demo-warehouse

# Verify bucket exists
docker exec demo-data-platform-query-minio-1 /usr/bin/mc ls local
```

## 4) First table via Trino (Iceberg REST -> Polaris)

```bash
# download Trino CLI: https://trino.io/download.html
trino --server localhost:8080 --catalog iceberg --schema default <<'SQL'
CREATE TABLE IF NOT EXISTS iceberg.default.customers (
  id bigint,
  name varchar,
  created_at timestamp
) WITH (
  format = 'PARQUET',
  partitioning = ARRAY['days(created_at)']
);

INSERT INTO iceberg.default.customers VALUES (1, 'Jane', current_timestamp);
SELECT * FROM iceberg.default.customers;

-- lineage/audit: Iceberg history
SELECT * FROM iceberg.default.customers$history;
SELECT * FROM iceberg.default.customers$snapshots;
SQL
```

## 5) Explore with Kyuubi (Spark SQL server)

Any JDBC/ODBC tool that speaks HiveServer2 can connect to `localhost:10009` with user/password left blank (or choose your own). For quick testing use Beeline from any Spark distro:

```bash
beeline -u 'jdbc:hive2://localhost:10009/' -n user
> SHOW TABLES;
> SELECT * FROM demo.default.orders;
```

The Kyuubi image is configured to start Spark locally with Iceberg + Polaris (see `config/kyuubi/spark-defaults.conf`).

## 6) PySpark demo (Spark -> Polaris -> MinIO)

The demo script mirrors the Kyuubi Spark settings and prints the table history for audit/lineage.

```bash
# run inside the compose network so hostnames resolve
# assumes you have Python + PySpark (3.5.x) locally
pip install pyspark
python scripts/pyspark_demo.py
```

If you prefer a containerized run:

```bash
docker run --rm -it \
  --network data-platform-net \
  -v "$PWD/scripts:/app" \
  -w /app \
  tabulario/spark-iceberg:3.5_1.5.1 \
  spark-submit pyspark_demo.py
```

## 7) Audit and lineage

- Iceberg keeps immutable metadata snapshots. Query `$history`, `$snapshots`, and `$refs` tables from Trino, Spark, or Kyuubi to see commits, operations, and timestamped lineage.
- Polaris REST backs the catalog (using H2 in-memory database in this demo); the `metadata_log.json` inside each Iceberg table (stored in MinIO) provides a full commit log with file-level diffs.
- For access auditing, enable MinIO server logs or bucket notifications (e.g., to a webhook) and tie them to query/user identities from Trino/Kyuubi logs.

## 8) Useful endpoints & files

**MinIO:**
- Console UI: http://localhost:9001 (user: minioadmin, pass: minioadmin)
- Create buckets, browse objects, view server logs

**Polaris REST API:**
- OAuth Token: `POST /api/catalog/v1/oauth/tokens` (requires `scope=PRINCIPAL_ROLE:ALL`)
- Get Config: `GET /api/catalog/v1/config`
- List Catalogs: `GET /api/management/v1/catalogs` (requires valid token)
- Create Catalog: `POST /api/management/v1/catalogs` (requires valid token)

Example:
```bash
# After running scripts/get_polaris_token.sh
source .polaris-env

curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8181/api/catalog/v1/config | jq .
```

**Configuration files:**
- Trino: `config/trino/etc/catalog/iceberg.properties` for Iceberg REST catalog settings
- Kyuubi/Spark: `config/kyuubi/spark-defaults.conf` for Iceberg + MinIO S3A settings

## 9) Teardown

```bash
docker compose down -v
```

## Troubleshooting

**Polaris won't start or healthcheck fails:**
- Polaris uses H2 in-memory database; no external database needed
- Credentials are randomly generated on startup; extract with `bash scripts/get_polaris_token.sh`
- Check logs: `docker logs demo-data-platform-query-polaris-1`

**Polaris OAuth token fails with "invalid_scope":**
- Always include `scope=PRINCIPAL_ROLE:ALL` in token requests
- Without explicit scope parameter, Polaris returns 400 error

**Polaris REST endpoints return 404:**
- Use correct API paths: `/api/catalog/v1/...` and `/api/management/v1/...` (not just `/v1/...`)
- Example: `GET /api/catalog/v1/config` works, `GET /v1/config` does not

**Trino table creation fails:**
- Ensure warehouse bucket exists in MinIO: `docker exec demo-data-platform-query-minio-1 /usr/bin/mc ls local`
- Verify Polaris REST catalog is configured: check `config/trino/etc/catalog/iceberg.properties`
- Restart Trino if configuration changed: `docker compose restart trino`

**Bucket creation returns "Access Denied":**
- Re-initialize the mc alias inside the MinIO container
- Run: `docker exec demo-data-platform-query-minio-1 /usr/bin/mc alias set local http://localhost:9000 minioadmin minioadmin`

**S3 connection errors in Spark/Kyuubi:**
- Verify `config/kyuubi/spark-defaults.conf` has correct MinIO endpoint and credentials
- Restart Kyuubi: `docker compose restart kyuubi`
- Check Spark logs: `docker logs demo-data-platform-query-kyuubi-1`
