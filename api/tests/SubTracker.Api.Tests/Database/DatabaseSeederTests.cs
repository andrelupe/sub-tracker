using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;
using SubTracker.Api.Features.Auth.Services;
using SubTracker.Api.Features.Settings.Domain;
using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Tests.Database;

public sealed class DatabaseSeederTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AppDbContext _db;

    public DatabaseSeederTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(_connection)
            .Options;

        _db = new AppDbContext(options);
        _db.Database.EnsureCreated();
    }

    public void Dispose()
    {
        _db.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public async Task EnsureDefaultAdmin_creates_admin_when_no_users_exist()
    {
        // Act
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);

        // Assert
        var users = await _db.Users.ToListAsync();
        Assert.Single(users);
        Assert.Equal(UserRole.Admin, users[0].Role);
        Assert.Equal("admin@subtracker.local", users[0].Email);
    }

    [Fact]
    public async Task EnsureDefaultAdmin_does_not_create_duplicate_admin()
    {
        // Arrange — run twice
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);

        // Assert
        var users = await _db.Users.ToListAsync();
        Assert.Single(users);
    }

    [Fact]
    public async Task EnsureDefaultAdmin_creates_valid_bcrypt_password()
    {
        // Act
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);

        // Assert
        var admin = await _db.Users.SingleAsync();
        Assert.StartsWith("$2", admin.PasswordHash);
    }

    [Fact]
    public async Task EnsureDefaultAdmin_creates_default_settings_for_admin()
    {
        // Act
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);

        // Assert
        var admin = await _db.Users.SingleAsync();
        var settings = await _db.UserSettings.SingleOrDefaultAsync(s => s.UserId == admin.Id);
        Assert.NotNull(settings);
        Assert.Equal("EUR", settings.BaseCurrency);
    }

    [Fact]
    public async Task EnsureDefaultAdmin_migrates_orphaned_subscriptions()
    {
        // Arrange — insert orphaned subscription via raw SQL to bypass FK check
        // This simulates the state after migration but before seeder runs
        await _db.Database.ExecuteSqlRawAsync("PRAGMA foreign_keys = OFF");
        var subId = Guid.NewGuid();
        var emptyGuid = Guid.Empty;
        await _db.Database.ExecuteSqlRawAsync(
            """
            INSERT INTO Subscriptions (Id, Name, Description, Amount, Currency, BillingCycle, Category, StartDate, NextBillingDate, IsActive, Url, ReminderDaysBefore, LastNotifiedAt, UserId, CreatedAt, UpdatedAt)
            VALUES ({0}, 'Orphaned Sub', NULL, 9.99, 'EUR', 'Monthly', 'Entertainment', '2026-01-01', '2026-04-01', 1, NULL, 2, NULL, {1}, '2026-01-01', '2026-01-01')
            """, subId, emptyGuid);
        await _db.Database.ExecuteSqlRawAsync("PRAGMA foreign_keys = ON");

        // Act
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);

        // Assert — use raw SQL to read back since ExecuteUpdateAsync bypasses change tracker
        var admin = await _db.Users.SingleAsync();

        // Re-create context to avoid stale cache
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(_connection)
            .Options;
        await using var freshDb = new AppDbContext(options);
        var subscription = await freshDb.Subscriptions.AsNoTracking().SingleAsync(s => s.Id == subId);
        Assert.Equal(admin.Id, subscription.UserId);
    }

    [Fact]
    public async Task EnsureDefaultAdmin_migrates_orphaned_settings()
    {
        // Arrange — insert orphaned settings via raw SQL to bypass FK check
        await _db.Database.ExecuteSqlRawAsync("PRAGMA foreign_keys = OFF");
        var emptyGuid = Guid.Empty;
        await _db.Database.ExecuteSqlRawAsync(
            """
            INSERT INTO UserSettings (UserId, BaseCurrency, UpdatedAt)
            VALUES ({0}, 'EUR', '2026-01-01')
            """, emptyGuid);
        await _db.Database.ExecuteSqlRawAsync("PRAGMA foreign_keys = ON");

        // Act
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);

        // Assert — use fresh context to avoid stale cache
        var admin = await _db.Users.SingleAsync();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(_connection)
            .Options;
        await using var freshDb = new AppDbContext(options);
        var settingsUserIds = await freshDb.UserSettings.AsNoTracking()
            .Select(s => s.UserId)
            .ToListAsync();
        Assert.Contains(admin.Id, settingsUserIds);
    }

    [Fact]
    public async Task EnsureDefaultAdmin_does_not_migrate_subscriptions_with_valid_userId()
    {
        // Arrange
        var utcNow = DateTime.UtcNow;
        var passwordService = new PasswordService();
        var existingUser = User.Create("existing@test.com", passwordService.Hash("Test1234!"), UserRole.Admin, utcNow);
        _db.Users.Add(existingUser);

        var subscription = Subscription.Create(
            name: "Existing Sub",
            description: null,
            amount: 9.99m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Entertainment,
            startDate: utcNow.AddMonths(-1),
            url: null,
            reminderDaysBefore: 2,
            userId: existingUser.Id,
            utcNow: utcNow);
        _db.Subscriptions.Add(subscription);
        await _db.SaveChangesAsync();

        // Act
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);

        // Assert — subscription still belongs to existing user
        var sub = await _db.Subscriptions.SingleAsync();
        Assert.Equal(existingUser.Id, sub.UserId);
    }

    [Fact]
    public async Task SeedDemoData_creates_subscriptions_in_dev()
    {
        // Arrange
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);

        // Act
        await DatabaseSeeder.SeedDemoDataAsync(_db);

        // Assert
        var count = await _db.Subscriptions.CountAsync();
        Assert.True(count > 0, "Demo subscriptions should be seeded");

        // All subscriptions belong to the admin
        var admin = await _db.Users.SingleAsync();
        var allBelongToAdmin = await _db.Subscriptions.AllAsync(s => s.UserId == admin.Id);
        Assert.True(allBelongToAdmin);
    }

    [Fact]
    public async Task SeedDemoData_is_idempotent()
    {
        // Arrange
        await DatabaseSeeder.EnsureDefaultAdminAsync(_db);

        // Act
        await DatabaseSeeder.SeedDemoDataAsync(_db);
        var countAfterFirst = await _db.Subscriptions.CountAsync();

        await DatabaseSeeder.SeedDemoDataAsync(_db);
        var countAfterSecond = await _db.Subscriptions.CountAsync();

        // Assert
        Assert.Equal(countAfterFirst, countAfterSecond);
    }
}
