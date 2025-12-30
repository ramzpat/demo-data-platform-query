# Data Platform Demo (MinIO + Polaris + Trino + Kyuubi)

This guide spins up a local, air-gapped demo to explore an Iceberg-based lakehouse with Polaris as the REST catalog, Trino for interactive SQL, Kyuubi/Spark for notebooks or JDBC/ODBC, and MinIO as the object store. It also shows where to find audit/lineage metadata and includes a PySpark sample.
d
> Images are pinned to reasonable defaults. If a tag 404s (especially Polaris), pull the latest available tag and update `docker-compose.yml` accordingly.

## 1) Bring the stack up

```bash
# from the repo root
# 1) start services
docker compose up -d

# 2) verify health (Trino & Polaris)
curl -s http://localhost:8080/v1/info | jq .nodeVersion
curl -s http://localhost:8181/health
```

Services/ports:
- MinIO API: http://localhost:9000
- MinIO Console: http://localhost:9001
- Polaris REST: http://localhost:8181
- Trino: http://localhost:8080 (CLI/jdbc)
- Kyuubi Thrift: localhost:10009

## 2) Bootstrap storage

Create the warehouse bucket that Iceberg will use.

```bash
# install mc if needed: https://min.io/docs/minio/linux/reference/minio-mc.html
mc alias set local http://localhost:9000 minioadmin minioadmin
mc mb local/demo-warehouse
```

## 3) First table via Trino (Iceberg REST -> Polaris)

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

## 4) Explore with Kyuubi (Spark SQL server)

Any JDBC/ODBC tool that speaks HiveServer2 can connect to `localhost:10009` with user/password left blank (or choose your own). For quick testing use Beeline from any Spark distro:

```bash
beeline -u 'jdbc:hive2://localhost:10009/' -n user
> SHOW TABLES;
> SELECT * FROM demo.default.orders;
```

The Kyuubi image is configured to start Spark locally with Iceberg + Polaris (see `config/kyuubi/spark-defaults.conf`).

## 5) PySpark demo (Spark -> Polaris -> MinIO)

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

## 6) Audit and lineage

- Iceberg keeps immutable metadata snapshots. Query `$history`, `$snapshots`, and `$refs` tables from Trino, Spark, or Kyuubi to see commits, operations, and timestamped lineage.
- Polaris REST backs the catalog in Postgres; the `metadata_log.json` inside each Iceberg table (stored in MinIO) provides a full commit log with file-level diffs.
- For access auditing, enable MinIO server logs or bucket notifications (e.g., to a webhook) and tie them to query/user identities from Trino/Kyuubi logs.

## 7) Useful endpoints & files

- MinIO console UI: create buckets, browse objects, view server logs.
- Polaris REST OpenAPI: http://localhost:8181/swagger if exposed by the image/tag you pull.
- Configuration you can tweak:
  - Trino: `config/trino/etc/catalog/iceberg.properties` for catalog settings.
  - Spark/Kyuubi: `config/kyuubi/spark-defaults.conf` for Iceberg + S3A.

## 8) Teardown

```bash
docker compose down -v
```

## Troubleshooting
- If Polaris fails to start, pull the latest tag from `ghcr.io/apache/polaris` and update the compose file.
- Trino 404 on `/v1/info`: wait for the healthcheck or increase container memory; 2–4 CPU + 6–8 GB RAM is comfortable.
- S3 auth errors: re-run `mc alias set` and ensure `spark-defaults.conf` and `iceberg.properties` share the same MinIO creds and endpoint.
