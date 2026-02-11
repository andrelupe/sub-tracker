#!/bin/bash

# Start the .NET API in background
cd /app/api
dotnet SubTracker.Api.dll &

# Wait for API to start
sleep 3

# Start nginx in foreground
nginx -g 'daemon off;'
