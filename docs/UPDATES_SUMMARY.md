# Documentation & Script Updates

## New Files Created

### 1. **QUICKSTART.md** - Fast reference guide
Quick 60-second setup guide with common tasks and web UI links.

**Use this when:** You want to get running quickly without reading detailed docs.

### 2. **scripts/get_polaris_token.sh** - Automatic credential extraction
Bash script that:
- Extracts generated Polaris credentials from container logs
- Obtains OAuth2 access token with correct scope (`PRINCIPAL_ROLE:ALL`)
- Exports credentials to `.polaris-env` file for use in other scripts
- Shows example API calls

**Usage:**
```bash
bash scripts/get_polaris_token.sh
source .polaris-env  # Load credentials into shell
```

**What it does:**
1. Reads Polaris logs for `root principal credentials: <ID>:<SECRET>`
2. Calls `/api/catalog/v1/oauth/tokens` with correct parameters
3. Creates `.polaris-env` with environment variables:
   - `CLIENT_ID`
   - `CLIENT_SECRET`
   - `ACCESS_TOKEN`
   - `POLARIS_HOST` and `POLARIS_PORT`

### 3. **SETUP_NOTES.md** - Configuration documentation
Detailed explanation of 5 critical issues found and how they were fixed:
1. Wrong environment variable names
2. PostgreSQL vs H2 database selection
3. Incorrect REST API endpoints
4. Missing OAuth scope parameter
5. Hard-coded credentials vs generated credentials

## Updated Files

### 1. **TUTORIAL.md** - Complete rewrite with correct setup
- Step 1: Stack startup (simplified)
- Step 2: Credential extraction using the new script
- Step 3: MinIO bucket setup (corrected commands using docker exec)
- Steps 4-9: Trino, Kyuubi, PySpark, audit/lineage, endpoints
- Enhanced troubleshooting section with correct Polaris paths

**Key improvements:**
- Correct Polaris API paths: `/api/catalog/v1/...` and `/api/management/v1/...`
- Automatic credential extraction instead of manual lookup
- Clear distinction between H2 database (what we use) vs PostgreSQL
- Correct OAuth scope requirement
- Better organized endpoints section
- Expanded troubleshooting with real solutions

### 2. **.gitignore** - Added credentials file
- Added `.polaris-env` to prevent accidentally committing credentials

## Key Documentation Files

| File | Purpose |
|------|---------|
| **QUICKSTART.md** | 60-second setup, common tasks, UI links |
| **TUTORIAL.md** | Complete step-by-step walkthrough |
| **SETUP_NOTES.md** | Technical details of configuration fixes |
| **POLARIS_CREDENTIALS.txt** | Reference for Polaris authentication |

## How to Use the Updated Setup

### For new users:
1. Read `QUICKSTART.md` first (2 minutes)
2. Run `docker compose up -d`
3. Run `bash scripts/get_polaris_token.sh`
4. Credentials are automatically extracted and available in `.polaris-env`

### For detailed learning:
1. Follow `TUTORIAL.md` step-by-step
2. Reference `SETUP_NOTES.md` for why things are configured a certain way
3. Check `QUICKSTART.md` for quick task references

### For API testing:
1. Extract credentials: `bash scripts/get_polaris_token.sh`
2. Source environment: `source .polaris-env`
3. Use provided curl examples or write your own with `$ACCESS_TOKEN`

## Tested & Verified

✅ Polaris OAuth token endpoint working
✅ Credential extraction script working
✅ All services running and healthy
✅ Documentation matches actual configuration
