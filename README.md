# SubTracker

Complete subscription management system with Flutter frontend and .NET backend.

## Components

| Component    | Technology                  | Version |
| ------------ | --------------------------- | ------- |
| **Frontend** | Flutter (Web/Mobile/Desktop) | v2.0.0  |
| **Backend**  | .NET 10 + FastEndpoints      | v2.0.0  |

---

## Frontend (Flutter)

### Getting Started

```bash
# Install dependencies
flutter pub get

# Generate Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# Create .env file from template
cp .env.example .env

# Run on Chrome
flutter run -d chrome

# Run on macOS
flutter run -d macos
```

### Features

- Track subscriptions with name, amount, and billing cycle
- View monthly and yearly spending totals
- See subscriptions due soon
- Swipe to pause or delete subscriptions
- Loading states and error handling for all API operations
- Search and filter subscriptions by category

### Architecture

Vertical Slices with Riverpod (async) for state management, HTTP API client for data.

```
lib/
├── core/
│   ├── constants/          # App constants + env config
│   ├── extensions/         # DateTime extensions
│   ├── providers/          # API service providers
│   ├── router/             # GoRouter configuration
│   ├── services/           # HTTP API client
│   └── theme/              # Material 3 theming
├── features/
│   └── subscriptions/
│       ├── models/         # Subscription, BillingCycle, Category
│       ├── providers/      # Async Riverpod state management
│       ├── screens/        # HomeScreen, SubscriptionFormScreen
│       ├── services/       # Subscription API service
│       └── widgets/        # ListTile, SummaryCard, FilterBar
└── main.dart
```

### Environment Configuration

The API base URL is configured via a `.env` file (loaded at runtime with `flutter_dotenv`):

```env
API_BASE_URL=http://localhost:5270/api
```

For Docker deployments, mount a different `.env` file:
```yaml
volumes:
  - ./production.env:/app/.env
```

---

## Backend (.NET API)

### Technologies

- **.NET 10** (ASP.NET Core)
- **FastEndpoints** (structured endpoints + validation)
- **Entity Framework Core** + SQLite
- **Serilog** (structured logging)
- **Pushover** (push notifications)

### Architecture

**Vertical Slice Architecture** with domain encapsulation:

```
api/
├── src/SubTracker.Api/
│   ├── Common/                 # Shared services (DateTime, Notifications)
│   ├── Database/               # EF Core DbContext + DatabaseSeeder
│   ├── Features/
│   │   ├── Subscriptions/      # Complete feature
│   │   │   ├── Domain/         # Entities + domain logic
│   │   │   ├── Shared/         # DTOs + Mappers
│   │   │   ├── GetAllEndpoint.cs
│   │   │   ├── CreateEndpoint.cs
│   │   │   └── ...
│   │   └── Notifications/      # Pushover + Background Jobs
│   ├── Migrations/             # EF Core migrations
│   └── Program.cs
└── tests/SubTracker.Api.Tests/
```

### Endpoints

| Method | Endpoint                  | Description   |
| ------ | ------------------------- | ------------- |
| GET    | `/api/subscriptions`      | List all      |
| GET    | `/api/subscriptions/{id}` | Get by ID     |
| POST   | `/api/subscriptions`      | Create new    |
| PUT    | `/api/subscriptions/{id}` | Update        |
| DELETE | `/api/subscriptions/{id}` | Delete        |
| GET    | `/swagger`                | Documentation |

### Quick Start

```bash
cd api/src/SubTracker.Api

# Run API (auto-migrates + seeds dummy data in Development)
dotnet run

# Run tests
cd ../..
dotnet test

# Docker
docker-compose up -d
```

### Dummy Data

In **Development** mode, the API automatically seeds 12 realistic subscriptions (Netflix, Spotify, GitHub Pro, etc.) on first run. The seed only runs when the database is empty.

### Configuration

**appsettings.json:**

```json
{
  "ConnectionStrings": {
    "Default": "Data Source=subtracker.db"
  },
  "Pushover": {
    "ApiToken": "YOUR_APP_TOKEN",
    "UserKey": "YOUR_USER_KEY"
  }
}
```

### Features

- Complete CRUD with FluentValidation
- Domain logic encapsulated (next billing date calculation)
- Background job checks due subscriptions (hourly)
- Pushover notifications (automatic)
- Development data seeder (12 subscriptions)
- Unit tests (8 tests passing)
- Docker production ready
- Auto-migration on startup

---

## Local Development

1. **Backend**: `cd api/src/SubTracker.Api && dotnet run` (port 5270)
2. **Frontend**: `flutter run -d chrome`

Both must be running simultaneously. The frontend reads the API URL from `.env`.

---

## Project Structure

```
sub-tracker/
├── lib/                        # Flutter frontend
├── api/                        # .NET backend
│   ├── src/SubTracker.Api/
│   ├── tests/
│   └── docker-compose.yml
├── .env.example                # Environment template
├── AGENTS.md                   # AI agent guidelines
├── CLAUDE.md                   # Claude Code guidelines
└── README.md
```

## Data Flow

```
Flutter UI → Riverpod Providers → HTTP API Service → .NET Backend → SQLite
```

All data is managed by the API. The Flutter app is a pure frontend client with no local storage.
