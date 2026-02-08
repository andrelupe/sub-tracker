# SubTracker

Complete subscription management system with Flutter frontend and .NET backend.

## Components

| Component    | Technology                   | Status      |
| ------------ | ---------------------------- | ----------- |
| **Frontend** | Flutter (Web/Mobile/Desktop) | ✅ Complete |
| **Backend**  | .NET 10 + FastEndpoints      | ✅ v2.0.0   |

---

## 🎯 Frontend (Flutter)

### Getting Started

```bash
# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run on Chrome (use fixed port for data persistence)
flutter run -d chrome --web-port=3000

# Run on macOS (requires Xcode)
flutter run -d macos
```

### Features

- Track subscriptions with name, amount, and billing cycle
- View monthly and yearly spending totals
- See subscriptions due soon
- Swipe to pause or delete subscriptions

### Architecture

Vertical Slices with Riverpod for state management.

```
lib/
├── core/
│   ├── extensions/
│   ├── router/
│   └── theme/
├── features/
│   └── subscriptions/
│       ├── models/
│       ├── providers/
│       ├── screens/
│       └── widgets/
└── main.dart
```

---

## 🚀 Backend (.NET API)

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
│   ├── Common/                 # Shared services
│   ├── Database/               # EF Core DbContext
│   ├── Features/
│   │   ├── Subscriptions/      # Complete feature
│   │   │   ├── Domain/         # Entities + domain logic
│   │   │   ├── Shared/         # DTOs + Mappers
│   │   │   ├── GetAllEndpoint.cs
│   │   │   ├── CreateEndpoint.cs
│   │   │   └── ...
│   │   └── Notifications/      # Pushover + Background Jobs
│   ├── Program.cs
│   └── appsettings.json
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
cd api

# First run - create migration
cd src/SubTracker.Api
dotnet ef migrations add InitialCreate

# Run API
dotnet run

# Run tests
cd ../..
dotnet test

# Docker
docker-compose up -d
```

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

- ✅ **Complete CRUD** with FluentValidation
- ✅ **Domain logic** encapsulated (next billing date calculation)
- ✅ **Background job** checks due subscriptions (hourly)
- ✅ **Pushover notifications** automatic
- ✅ **Unit tests** (8 tests passing)
- ✅ **Docker** production ready
- ✅ **Auto-migration** on startup

---

## 🔄 Integration

### Local Development

1. **Backend**: `cd api && dotnet run` (port 5000)
2. **Frontend**: `flutter run -d chrome --web-port=3000`

### Production

```bash
# API
cd api
docker-compose up -d

# Frontend
flutter build web
# Deploy to static hosting
```

---

## 📂 Project Structure

```
sub-tracker/
├── lib/                        # Flutter frontend
├── api/                        # .NET backend
│   ├── src/SubTracker.Api/
│   ├── tests/
│   └── docker-compose.yml
├── README.md
└── AGENTS.md
```

## Data Persistence

- **Frontend**: Hive (local storage, IndexedDB on web)
- **Backend**: SQLite (local) → PostgreSQL (production)
