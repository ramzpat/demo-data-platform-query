# Apache Polaris Official Quickstart Documentation

## Overview

This directory contains the official Apache Polaris docker-compose configuration and initialization scripts from the Apache Polaris GitHub repository (github.com/apache/polaris).

## Files

1. **polaris-official-docker-compose.yml** - Official Docker Compose file for running Polaris with MinIO storage
2. **polaris-bootstrap.sh** - Bootstrap script to initialize Polaris
3. **polaris-obtain-token.sh** - Script to obtain OAuth access tokens from Polaris
4. **polaris-create-catalog.sh** - Script to create a catalog and principals in Polaris

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- curl and jq installed (for scripts)

### Start Polaris

```bash
docker compose -f polaris-official-docker-compose.yml up -d
```

This will start:
- **Polaris Server** on http://localhost:8181 (API port 8181, metrics 8182)
- **MinIO Storage** on http://localhost:9000 (UI: http://localhost:9001)

### Initialize Polaris

1. **Wait for services to be ready:**
   ```bash
   bash polaris-bootstrap.sh
   ```

2. **Obtain an access token:**
   ```bash
   export CLIENT_ID=root
   export CLIENT_SECRET=s3cr3t
   bash polaris-obtain-token.sh
   ```

3. **Create a catalog:**
   ```bash
   export STORAGE_LOCATION="s3://polaris-warehouse"
   export MINIO_ENDPOINT="http://minio:9000"
   bash polaris-create-catalog.sh default
   ```

## Environment Variables

The scripts support the following environment variables:

- `CLIENT_ID` - OAuth client ID (default: root)
- `CLIENT_SECRET` - OAuth client secret (default: s3cr3t)
- `POLARIS_HOST` - Polaris server hostname (default: localhost)
- `POLARIS_PORT` - Polaris server port (default: 8181)
- `STORAGE_LOCATION` - S3 storage location (default: s3://polaris-warehouse)
- `MINIO_ENDPOINT` - MinIO endpoint (default: http://minio:9000)

## Example Usage

```bash
# Start Polaris
docker compose -f polaris-official-docker-compose.yml up -d

# Wait for it to be ready
sleep 10

# Get token
export TOKEN=$(curl -s -X POST "http://localhost:8181/api/catalog/v1/oauth/tokens" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=root" \
  -d "client_secret=s3cr3t" | jq -r '.access_token')

# List catalogs
curl -X GET "http://localhost:8181/api/management/v1/catalogs" \
  -H "Authorization: Bearer ${TOKEN}"

# Create a catalog
curl -X POST "http://localhost:8181/api/management/v1/catalogs" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "catalog": {
      "name": "my_catalog",
      "type": "INTERNAL",
      "properties": {
        "default-base-location": "s3://my-bucket/data"
      }
    }
  }'
```

## Cleanup

To stop and remove all containers:

```bash
docker compose -f polaris-official-docker-compose.yml down -v
```

## API Endpoints

| Service | Endpoint | Port |
|---------|----------|------|
| Polaris API | http://localhost:8181/api | 8181 |
| Polaris Metrics | http://localhost:8182/q | 8182 |
| MinIO S3 | http://localhost:9000 | 9000 |
| MinIO UI | http://localhost:9001 | 9001 |

## OAuth Token Endpoint

```
POST http://localhost:8181/api/catalog/v1/oauth/tokens
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&client_id=<CLIENT_ID>&client_secret=<CLIENT_SECRET>
```

## Management API Base

```
http://localhost:8181/api/management/v1
```

Key endpoints:
- `GET /catalogs` - List catalogs
- `POST /catalogs` - Create catalog
- `GET /principals` - List principals
- `POST /principals` - Create principal

## Catalog API Base

```
http://localhost:8181/api/catalog
```

Key endpoints:
- `GET /catalogs` - List catalogs with REST metadata
- `GET /catalogs/{catalog}/namespaces` - List namespaces
- `POST /catalogs/{catalog}/namespaces` - Create namespace

## Storage Configuration

The default docker-compose uses MinIO for S3-compatible storage:

- **Endpoint:** http://minio:9000 (internal) / http://localhost:9000 (external)
- **Access Key:** minio
- **Secret Key:** miniosecret

## Notes

- The Polaris image uses the h2 in-memory database by default (not suitable for production)
- For production, configure PostgreSQL or another JDBC-compatible database
- MinIO is used for S3-compatible storage in this example
- Default credentials are printed to logs on startup

## Reference

For more information and advanced configurations, see:
- https://github.com/apache/polaris/tree/main/getting-started/quickstart
- https://polaris.apache.org/in-dev/unreleased/getting-started/quick-start/
