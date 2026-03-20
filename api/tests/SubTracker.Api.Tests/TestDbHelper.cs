using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Database;

namespace SubTracker.Api.Tests;

/// <summary>
/// Creates an in-memory SQLite connection with the current model schema
/// and marks all existing migrations as applied so MigrateAsync() is a no-op.
/// This is needed because the model may include changes not yet in a migration.
/// </summary>
public static class TestDbHelper
{
    private static readonly string[] ExistingMigrations =
    [
        "20260208205204_InitialCreate",
        "20260224131838_AddLastNotifiedAt",
        "20260303161731_AddExchangeRatesAndUserSettings",
        "20260316001626_AddMultiUserSupport",
        "20260316001755_MakeUserIdRequired"
    ];

    public static SqliteConnection CreateConnection()
    {
        var connection = new SqliteConnection("DataSource=:memory:");
        connection.Open();

        // Create schema from the current model
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(connection)
            .Options;

        using var db = new AppDbContext(options);
        db.Database.EnsureCreated();

        // Mark all existing migrations as applied so MigrateAsync() is a no-op
        db.Database.ExecuteSqlRaw(
            "CREATE TABLE IF NOT EXISTS __EFMigrationsHistory (MigrationId TEXT PRIMARY KEY, ProductVersion TEXT NOT NULL)");

        foreach (var migration in ExistingMigrations)
        {
            db.Database.ExecuteSqlRaw(
                "INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES ({0}, {1})",
                migration, "10.0.2");
        }

        return connection;
    }
}