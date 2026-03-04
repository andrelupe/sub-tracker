#!/bin/bash

# ============================================
# Generate Flutter .env from environment vars
# ============================================
# Flutter Web reads .env as a bundled asset.
# This overwrites it at runtime so the container
# can be configured via environment variables
# without rebuilding the image.

ENV_FILE=""

if [ -f /app/wwwroot/assets/.env ]; then
  ENV_FILE="/app/wwwroot/assets/.env"
elif [ -f /app/wwwroot/assets/assets/.env ]; then
  ENV_FILE="/app/wwwroot/assets/assets/.env"
fi

if [ -n "$ENV_FILE" ]; then
  echo "Generating Flutter .env at $ENV_FILE"
  cat > "$ENV_FILE" <<EOF
API_BASE_URL=${API_BASE_URL:-/api}
API_KEY=${SUBTRACKER_API_KEY:-}
EOF
else
  echo "WARNING: Flutter .env asset not found. API_KEY will not be injected."
fi

# ============================================
# Start the .NET API in background
# ============================================
cd /app/api
dotnet SubTracker.Api.dll &

# Wait for API to start
sleep 3

# ============================================
# Start nginx in foreground
# ============================================
nginx -g 'daemon off;'