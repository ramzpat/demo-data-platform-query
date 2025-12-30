# Quick Start Guide

## 60-Second Setup

```bash
# 1. Start all services
docker compose up -d

# 2. Extract Polaris credentials and get OAuth token
bash scripts/get_polaris_token.sh

# 3. Verify Polaris is accessible
source .polaris-env
curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8181/api/catalog/v1/config | jq .
```

## Common Tasks

### Create MinIO warehouse bucket
```bash
docker exec demo-data-platform-query-minio-1 /usr/bin/mc alias set local http://localhost:9000 minioadmin minioadmin
docker exec demo-data-platform-query-minio-1 /usr/bin/mc mb local/demo-warehouse
```

### Get fresh credentials (after container restart)
```bash
bash scripts/get_polaris_token.sh
source .polaris-env
```

### Test Polaris API
```bash
# After sourcing .polaris-env

# Get server config
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8181/api/catalog/v1/config | jq .

# List catalogs
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8181/api/management/v1/catalogs | jq .
```

### Test Trino connection
```bash
trino --server localhost:8080 --catalog iceberg --schema default \
  -c "SELECT 1"
```

### Check service health
```bash
docker compose ps

# Detailed logs
docker logs demo-data-platform-query-polaris-1
docker logs demo-data-platform-query-trino-1
docker logs demo-data-platform-query-kyuubi-1
```

## Web UIs

- MinIO Console: http://localhost:9001 (user: minioadmin, pass: minioadmin)
- Trino UI: http://localhost:8080/ui/

## Key Files

- `docker-compose.yml` - Stack definition
- `TUTORIAL.md` - Detailed walkthrough
- `SETUP_NOTES.md` - Configuration details and fixes
- `scripts/get_polaris_token.sh` - Credential extraction script
- `config/trino/etc/catalog/iceberg.properties` - Trino Iceberg catalog config
- `config/kyuubi/spark-defaults.conf` - Kyuubi Spark configuration

## Documentation

For detailed instructions, see [TUTORIAL.md](TUTORIAL.md)
For configuration details, see [SETUP_NOTES.md](SETUP_NOTES.md)
