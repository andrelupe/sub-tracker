# SubTracker All-in-One Dockerfile
# Serves both the .NET API and Flutter web frontend

# ============================================
# Stage 1: Build Flutter Web
# ============================================
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build

WORKDIR /app

# Copy Flutter project files
COPY pubspec.yaml pubspec.lock ./
COPY lib/ lib/
COPY web/ web/
COPY .env .env

# Get dependencies and build
RUN flutter pub get
RUN dart run build_runner build --delete-conflicting-outputs
RUN flutter build web --release

# ============================================
# Stage 2: Build .NET API
# ============================================
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS dotnet-build

WORKDIR /src

# Copy API project files
COPY api/src/SubTracker.Api/*.csproj ./
RUN dotnet restore

COPY api/src/SubTracker.Api/ ./
RUN dotnet publish -c Release -o /app/publish

# ============================================
# Stage 3: Final Runtime Image
# ============================================
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final

WORKDIR /app

# Install nginx
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Copy .NET API
COPY --from=dotnet-build /app/publish ./api/

# Copy Flutter web files
COPY --from=flutter-build /app/build/web ./wwwroot/

# Copy nginx config
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copy startup script
COPY docker/start.sh ./start.sh
RUN chmod +x ./start.sh

# Expose port
EXPOSE 80

# Start both nginx and API
CMD ["./start.sh"]
