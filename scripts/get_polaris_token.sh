#!/bin/bash
#
# Helper script to extract Polaris credentials and obtain OAuth token
# Usage: ./scripts/get_polaris_token.sh
#
# This script:
# 1. Extracts the generated root credentials from Polaris logs
# 2. Obtains an OAuth2 access token
# 3. Exports the token for use in other API calls
#

set -e

POLARIS_HOST="${POLARIS_HOST:-localhost}"
POLARIS_PORT="${POLARIS_PORT:-8181}"
CONTAINER_NAME="demo-data-platform-query-polaris-1"

echo "========================================="
echo "Polaris Credential & Token Extraction"
echo "========================================="
echo ""

# Extract generated credentials from Polaris logs
echo "Extracting Polaris credentials from container logs..."
CREDENTIALS=$(docker logs "$CONTAINER_NAME" 2>&1 | grep "root principal credentials:" | head -1 | awk -F': ' '{print $NF}')

if [ -z "$CREDENTIALS" ]; then
  echo "ERROR: Could not find credentials in Polaris logs"
  echo "Make sure the container is running: docker compose up -d"
  exit 1
fi

# Parse client ID and secret
CLIENT_ID=$(echo "$CREDENTIALS" | cut -d: -f1)
CLIENT_SECRET=$(echo "$CREDENTIALS" | cut -d: -f2-)

echo "✓ Credentials found:"
echo "  CLIENT_ID: $CLIENT_ID"
echo "  CLIENT_SECRET: $CLIENT_SECRET"
echo ""

# Obtain OAuth token
echo "Obtaining OAuth2 access token..."
TOKEN_RESPONSE=$(curl -s -X POST "http://${POLARIS_HOST}:${POLARIS_PORT}/api/catalog/v1/oauth/tokens" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "scope=PRINCIPAL_ROLE:ALL")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token // empty')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "ERROR: Failed to obtain access token"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "✓ Access token obtained successfully"
echo ""

# Export environment variables for use in other scripts
export CLIENT_ID CLIENT_SECRET ACCESS_TOKEN

# Save to a shell-sourceable file
cat > .polaris-env << EOF
#!/bin/bash
# Polaris credentials and token (auto-generated)
export CLIENT_ID="$CLIENT_ID"
export CLIENT_SECRET="$CLIENT_SECRET"
export ACCESS_TOKEN="$ACCESS_TOKEN"
export POLARIS_HOST="$POLARIS_HOST"
export POLARIS_PORT="$POLARIS_PORT"
EOF

chmod +x .polaris-env

echo "Environment variables saved to .polaris-env"
echo ""
echo "To use these credentials in future scripts, run:"
echo "  source .polaris-env"
echo ""
echo "API Examples:"
echo "  # Get server config"
echo "  curl -H \"Authorization: Bearer \$ACCESS_TOKEN\" \\"
echo "    http://${POLARIS_HOST}:${POLARIS_PORT}/api/catalog/v1/config"
echo ""
echo "  # List catalogs (requires ADMIN role)"
echo "  curl -H \"Authorization: Bearer \$ACCESS_TOKEN\" \\"
echo "    http://${POLARIS_HOST}:${POLARIS_PORT}/api/management/v1/catalogs"
echo ""
