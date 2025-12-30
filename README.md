# Data Platform Demo

A complete, self-contained demo of a modern lakehouse architecture using Apache Iceberg, Polaris, Trino, Kyuubi, and MinIO.

## 🚀 Quick Start (2 minutes)

```bash
# 1. Start all services
docker compose up -d

# 2. Extract Polaris credentials
bash scripts/get_polaris_token.sh

# 3. Verify everything works
source .polaris-env
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8181/api/catalog/v1/config | jq .
```

## 📚 Documentation

Start here based on your needs:

| Document | Purpose | Time |
|----------|---------|------|
| **[QUICKSTART.md](docs/QUICKSTART.md)** | Common tasks & commands | 5 min |
| **[TUTORIAL.md](docs/TUTORIAL.md)** | Complete step-by-step guide | 30 min |
| **[SETUP_NOTES.md](docs/SETUP_NOTES.md)** | Configuration details & fixes | 15 min |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Your Laptop                       │
├─────────────────────────────────────────────────────┤
│  Trino (SQL)          Kyuubi (Spark SQL)            │
│  localhost:8080       localhost:10009               │
│         │                     │                      │
│         └──────────┬──────────┘                      │
│                    ▼                                 │
│         ┌──────────────────────┐                    │
│         │  Polaris REST Catalog│ (H2 in-memory)    │
│         │  localhost:8181      │                    │
│         └──────────┬───────────┘                    │
│                    ▼                                │
│         ┌──────────────────────┐                    │
│         │  MinIO S3-compatible │                    │
│         │  localhost:9000      │                    │
│         │  console:9001        │                    │
│         └──────────────────────┘                    │
└─────────────────────────────────────────────────────┘
```

## 📁 Folder Structure

```
demo-data-platform-query/
├── docker-compose.yml          # Services definition
├── README.md                   # This file
├── .gitignore                  # Git exclusions
│
├── docs/                       # Documentation
│   ├── QUICKSTART.md          # Fast reference
│   ├── TUTORIAL.md            # Complete guide
│   ├── SETUP_NOTES.md         # Configuration details
│   └── UPDATES_SUMMARY.md     # What was fixed
│
├── scripts/                    # Helper scripts
│   ├── get_polaris_token.sh   # Extract credentials
│   └── pyspark_demo.py        # Spark example
│
├── config/                     # Service configurations
│   ├── trino/etc/             # Trino config
│   └── kyuubi/                # Kyuubi/Spark config
│
├── data/                       # Runtime data (git-ignored)
│   ├── minio/                 # Object store data
│   └── (auto-created)
│
└── .polaris-env               # Generated credentials (git-ignored)
```

## 🔧 Services & Ports

| Service | Port | Purpose |
|---------|------|---------|
| **MinIO** | 9000 | S3-compatible object store |
| **MinIO Console** | 9001 | Web UI (user: minioadmin) |
| **Polaris** | 8181 | Iceberg REST catalog API |
| **Trino** | 8080 | Interactive SQL engine |
| **Kyuubi** | 10009 | Spark SQL over HiveServer2 |

## ✨ Key Features

- **Iceberg Tables** - ACID transactions, time-travel queries, schema evolution
- **Polaris Catalog** - REST-based metadata management, namespace/table governance
- **Trino** - SQL engine for interactive queries
- **Kyuubi** - Spark SQL server for notebook/JDBC connections
- **MinIO** - S3-compatible object storage for data files
- **Audit & Lineage** - Full query history via Iceberg `$history` and `$snapshots`

## 🎯 First Steps

### Step 1: Start the Stack
```bash
docker compose up -d
```
Wait ~30 seconds for services to be ready.

### Step 2: Get Credentials
```bash
bash scripts/get_polaris_token.sh
```
This extracts the auto-generated Polaris credentials and obtains an OAuth token.

### Step 3: Create a Warehouse Bucket
```bash
docker exec demo-data-platform-query-minio-1 /usr/bin/mc alias set local http://localhost:9000 minioadmin minioadmin
docker exec demo-data-platform-query-minio-1 /usr/bin/mc mb local/demo-warehouse
```

### Step 4: Create Your First Table
Follow the **[TUTORIAL.md](docs/TUTORIAL.md)** for detailed examples using Trino, Kyuubi, or PySpark.

## 🔍 Verify Everything Works

```bash
# Check services are running
docker compose ps

# Extract and load credentials
bash scripts/get_polaris_token.sh
source .polaris-env

# Test Polaris API
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8181/api/catalog/v1/config | jq .

# Test Trino
trino --server localhost:8080 --catalog iceberg --schema default \
  -c "SELECT 1"
```

## 📖 Learning Path

1. **Understand the basics** (5 min)
   - Read this README
   - Check the architecture diagram

2. **Run the quick start** (5 min)
   - Run commands in "Quick Start" section above
   - Access web UIs

3. **Follow the tutorial** (30 min)
   - See [TUTORIAL.md](docs/TUTORIAL.md)
   - Create tables with Trino
   - Query with Kyuubi
   - Explore with PySpark

4. **Explore advanced features** (ongoing)
   - Query Iceberg `$history` for audit trails
   - Test time-travel queries
   - Set up notifications
   - Create custom workflows

## 🐛 Troubleshooting

### Services won't start
```bash
# Check logs
docker compose logs polaris
docker compose logs trino

# Restart everything
docker compose down && docker compose up -d
```

### Can't extract credentials
```bash
# Wait longer and try again
sleep 30
bash scripts/get_polaris_token.sh
```

### Trino can't create tables
- See **Troubleshooting** section in [TUTORIAL.md](docs/TUTORIAL.md)
- Key points: warehouse bucket must exist, Polaris must be accessible

For more detailed help, see [TUTORIAL.md](docs/TUTORIAL.md#troubleshooting).

## 🧹 Cleanup

```bash
# Stop and remove containers
docker compose down -v
```

This removes volumes and data. Configurations stay in the repo.

## 📚 Additional Resources

- **Apache Iceberg**: https://iceberg.apache.org
- **Polaris Catalog**: https://polaris.apache.org
- **Trino**: https://trino.io
- **Kyuubi**: https://kyuubi.apache.org
- **MinIO**: https://min.io

## 💡 Tips

- Credentials are auto-generated fresh on each startup
- Extract them immediately after `docker compose up -d`
- Store `.polaris-env` locally but don't commit it (it's in .gitignore)
- All data is stored in `./data/` which is ignored by git
- Use `docker logs <container>` to debug any service

## 🤝 Contributing

Found an issue or have a suggestion? Feel free to:
1. Check [SETUP_NOTES.md](docs/SETUP_NOTES.md) for context
2. Review [UPDATES_SUMMARY.md](docs/UPDATES_SUMMARY.md) for recent changes
3. File an issue or submit a PR

---

**Ready?** Start with `docker compose up -d` and run the credential script! 🚀
