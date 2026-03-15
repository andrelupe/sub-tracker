---
name: gen-test-csharp
description: Generate .NET/C# xUnit tests following the project's testing patterns
user-invocable: true
disable-model-invocation: false
---

# Generate C# Tests

Generate tests for .NET/C# source files following this project's conventions.

## Arguments

The user specifies source files or features to test.

## Steps

1. Read the source file(s) to understand the code
2. Read 1-2 existing test files of the same type (domain, integration, service) to match patterns
3. Generate the test file
4. Run `cd api && dotnet test --filter "FullyQualifiedName~NewTestClass"` to verify it passes

## Test File Location

All tests under `api/tests/SubTracker.Api.Tests/`, mirroring source structure, append `Tests.cs`:
- `src/.../Features/Settings/Domain/UserSettings.cs` → `tests/.../Features/Settings/UserSettingsTests.cs`

## Conventions

### Imports

Global usings handle `Xunit`, `System.*`, `Microsoft.*`. Only add project-specific usings:

```csharp
using SubTracker.Api.Features.YourFeature.Domain;
```

### Method Naming

Pattern: `MethodName_Condition_ExpectedBehavior`
- `Create_ShouldSetAllProperties()`
- `IsDueSoon_ShouldReturnTrue_WhenWithinReminderDays()`

### Unit Tests (Domain)

- Factory methods for instantiation (e.g., `Subscription.Create(...)`)
- Private `DateTime _utcNow` field for deterministic time
- `[Fact]` for single cases, `[Theory]` + `[InlineData]` for parameterized

```csharp
public class SubscriptionTests
{
    private readonly DateTime _utcNow = new(2025, 1, 15, 10, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Create_ShouldSetAllProperties()
    {
        var subscription = Subscription.Create("Netflix", ...);
        Assert.NotEqual(Guid.Empty, subscription.Id);
    }
}
```

### Service Tests (in-memory DB)

- `IDisposable` for cleanup
- SQLite in-memory: `new SqliteConnection("DataSource=:memory:")`
- `_db.Database.OpenConnection()` + `EnsureCreated()`

### Integration Tests (HTTP)

- `WebApplicationFactory<Program>` with `WithWebHostBuilder`
- Environment: `"Production"`
- Remove background jobs: `services.RemoveAll<IHostedService>()`
- Replace DB with in-memory SQLite
- Cleanup: `using var _ = connection;`

### Test Doubles

Sealed private inner classes only:

```csharp
private sealed class FakeDateTimeProvider(DateTime utcNow) : IDateTimeProvider
{
    public DateTime UtcNow => utcNow;
}
```

### Rules

- Do NOT use Moq — manual sealed fakes only
- xUnit assertions only (`Assert.Equal`, `Assert.True`, `Assert.NotNull`)
- Always remove `IHostedService` in integration tests
- Realistic domain data (Netflix, Spotify, etc.)
- AAA pattern: Arrange → Act → Assert
