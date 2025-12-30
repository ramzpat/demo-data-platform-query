# Apache Polaris Setup - Correct Configuration

## Initial Issues & Resolution

###  Issue 1: Wrong Polaris Environment Variables
**Problem:** We were using incorrect Quarkus configuration variables like `POLARIS_DB_*` and `POLARIS_S3_*`
**Solution:** Use correct Quarkus naming convention: `QUARKUS_DATASOURCE_*`

```yaml
# WRONG:
POLARIS_DB_URL: jdbc:postgresql://postgres:5432/polaris
POLARIS_S3_ENDPOINT: http://minio:9000

# CORRECT:
QUARKUS_DATASOURCE_JDBC_URL: jdbc:postgresql://postgres:5432/polaris
QUARKUS_DATASOURCE_USERNAME: polaris
QUARKUS_DATASOURCE_PASSWORD: polaris
```

### Issue 2: PostgreSQL vs H2 Database
**Problem:** We configured PostgreSQL, but Polaris 1.2.0-incubating by default uses H2 in-memory database for demos
**Solution:** Use H2 in-memory database matching the official quickstart

```yaml
# Use H2 (simpler, works without extra setup):
QUARKUS_DATASOURCE_JDBC_URL: jdbc:h2:mem:polaris
QUARKUS_DATASOURCE_USERNAME: sa
QUARKUS_DATASOURCE_PASSWORD: ""

# OR use PostgreSQL (requires schema initialization):
QUARKUS_DATASOURCE_JDBC_URL: jdbc:postgresql://postgres:5432/polaris
QUARKUS_DATASOURCE_USERNAME: polaris
QUARKUS_DATASOURCE_PASSWORD: polaris
```

### Issue 3: Non-existent REST Endpoints
**Problem:** We were trying `/v1/namespaces` and `/q/health` which returned 404
**Solution:** Use correct Polaris REST API paths

```bash
# WRONG:
curl http://localhost:8181/v1/namespaces
curl http://localhost:8181/q/health

# CORRECT:
curl http://localhost:8181/api/catalog/v1/oauth/tokens
curl http://localhost:8181/api/management/v1/catalogs
curl http://localhost:8181/api/catalog/v1/config
```

### Issue 4: OAuth Token Missing Scope
**Problem:** OAuth token endpoint returned `invalid_scope` error
**Cause:** Polaris requires an explicit `scope` parameter; it doesn't have defaults
**Solution:** Always include `scope=PRINCIPAL_ROLE:ALL` in token requests

```bash
# WRONG:
curl -X POST http://localhost:8181/api/catalog/v1/oauth/tokens \
  -d "grant_type=client_credentials" \
  -d "client_id=root" \
  -d "client_secret=s3cr3t"

# CORRECT:
curl -X POST http://localhost:8181/api/catalog/v1/oauth/tokens \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=<generated_id>" \
  -d "client_secret=<generated_secret>" \
  -d "scope=PRINCIPAL_ROLE:ALL"
```

### Issue 5: Hard-coded `root:s3cr3t` Credentials Don't Work
**Problem:** Official documentation shows using `root:s3cr3t` as default credentials
**Reality:** When using H2 database, Polaris generates random credentials on startup
**Solution:** Extract generated credentials from Polaris logs

```bash
# Get credentials from logs:
docker logs demo-data-platform-query-polaris-1 2>&1 | grep "root principal credentials:"

# Output format:
# realm: POLARIS root principal credentials: <CLIENT_ID>:<CLIENT_SECRET>
```

## Corrected docker-compose.yml Configuration

```yaml
polaris:
  image: apache/polaris:1.2.0-incubating
  depends_on:
    minio:
      condition: service_started
  environment:
    # Use H2 in-memory database
    QUARKUS_DATASOURCE_JDBC_URL: jdbc:h2:mem:polaris
    QUARKUS_DATASOURCE_USERNAME: sa
    QUARKUS_DATASOURCE_PASSWORD: ""
    # Storage configuration for Iceberg
    STORAGE_LOCATION: s3://demo-warehouse/
    JAVA_TOOL_OPTIONS: "-Duser.timezone=UTC"
  ports:
    - "8181:8181"  # API port
    - "8182:8182"  # Management port
  healthcheck:
    test: ["CMD", "nc", "-z", "localhost", "8181"]
    interval: 10s
    timeout: 5s
    retries: 20
    start_period: 30s
```

## Key Learnings

1. **Polaris Quickstart uses H2, not PostgreSQL** - H2 is in-memory and requires no setup
2. **API paths use `/api/catalog/v1/` and `/api/management/v1/` prefixes** - not just `/v1/`
3. **OAuth token requests MUST include scope parameter** - `scope=PRINCIPAL_ROLE:ALL`
4. **Credentials are generated fresh on each startup** - extract from logs, don't hard-code
5. **Trino and Kyuubi depend on Polaris being started, but don't need to wait for healthy status** - use `service_started` not `service_healthy`

## Next Steps

Now that Polaris is properly configured:
1. Create a catalog with warehouse backing (MinIO S3)
2. Create namespaces and tables via Trino
3. Test data operations
4. Verify Iceberg history/lineage features
