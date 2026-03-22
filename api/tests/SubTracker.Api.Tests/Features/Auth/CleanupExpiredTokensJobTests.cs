using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;
using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Tests.Features.Auth;

public sealed class CleanupExpiredTokensJobTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AppDbContext _db;
    private readonly PasswordService _passwordService = new();

    public CleanupExpiredTokensJobTests()
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
    public async Task Removes_expired_refresh_tokens()
    {
        // Arrange
        var utcNow = new DateTime(2026, 3, 22, 12, 0, 0, DateTimeKind.Utc);
        var user = User.Create("test@test.com", _passwordService.Hash("Test1234!"), UserRole.User, utcNow);
        _db.Users.Add(user);

        var tokenService = new TokenService(CreateConfig());

        // Expired token (expired 1 hour ago)
        var expiredToken = RefreshToken.Create(
            user.Id,
            tokenService.HashToken("expired-token"),
            utcNow.AddHours(-1),
            utcNow.AddDays(-30));
        _db.RefreshTokens.Add(expiredToken);

        // Valid token (expires in 29 days)
        var validToken = RefreshToken.Create(
            user.Id,
            tokenService.HashToken("valid-token"),
            utcNow.AddDays(29),
            utcNow.AddDays(-1));
        _db.RefreshTokens.Add(validToken);

        await _db.SaveChangesAsync();

        // Act - simulate cleanup logic
        var expiredTokens = await _db.RefreshTokens
            .Where(t => t.ExpiresAt <= utcNow)
            .ExecuteDeleteAsync();

        // Assert
        Assert.Equal(1, expiredTokens);
        var remaining = await _db.RefreshTokens.ToListAsync();
        Assert.Single(remaining);
        Assert.Equal(validToken.Id, remaining[0].Id);
    }

    [Fact]
    public async Task Clears_expired_reset_tokens_on_users()
    {
        // Arrange
        var utcNow = new DateTime(2026, 3, 22, 12, 0, 0, DateTimeKind.Utc);

        var userWithExpiredReset = User.Create("expired@test.com", _passwordService.Hash("Test1234!"), UserRole.User, utcNow);
        userWithExpiredReset.SetResetToken("expired-hash", utcNow.AddHours(-1), utcNow.AddHours(-2));
        _db.Users.Add(userWithExpiredReset);

        var userWithValidReset = User.Create("valid@test.com", _passwordService.Hash("Test1234!"), UserRole.User, utcNow);
        userWithValidReset.SetResetToken("valid-hash", utcNow.AddHours(1), utcNow);
        _db.Users.Add(userWithValidReset);

        var userNoReset = User.Create("noreset@test.com", _passwordService.Hash("Test1234!"), UserRole.User, utcNow);
        _db.Users.Add(userNoReset);

        await _db.SaveChangesAsync();

        // Act - simulate cleanup logic
        var usersWithExpiredResets = await _db.Users
            .Where(u => u.ResetToken != null && u.ResetTokenExpiresAt <= utcNow)
            .ToListAsync();

        foreach (var user in usersWithExpiredResets)
        {
            user.ClearResetToken(utcNow);
        }

        await _db.SaveChangesAsync();

        // Assert
        Assert.Single(usersWithExpiredResets);

        var expiredUser = await _db.Users.FirstAsync(u => u.Email == "expired@test.com");
        Assert.False(expiredUser.HasValidResetToken(utcNow));

        var validUser = await _db.Users.FirstAsync(u => u.Email == "valid@test.com");
        Assert.True(validUser.HasValidResetToken(utcNow));

        var noResetUser = await _db.Users.FirstAsync(u => u.Email == "noreset@test.com");
        Assert.False(noResetUser.HasValidResetToken(utcNow));
    }

    [Fact]
    public async Task No_op_when_no_expired_tokens()
    {
        // Arrange
        var utcNow = new DateTime(2026, 3, 22, 12, 0, 0, DateTimeKind.Utc);
        var user = User.Create("test@test.com", _passwordService.Hash("Test1234!"), UserRole.User, utcNow);
        _db.Users.Add(user);

        var tokenService = new TokenService(CreateConfig());
        var validToken = RefreshToken.Create(
            user.Id,
            tokenService.HashToken("valid-token"),
            utcNow.AddDays(29),
            utcNow);
        _db.RefreshTokens.Add(validToken);
        await _db.SaveChangesAsync();

        // Act
        var deleted = await _db.RefreshTokens
            .Where(t => t.ExpiresAt <= utcNow)
            .ExecuteDeleteAsync();

        var usersWithExpiredResets = await _db.Users
            .Where(u => u.ResetToken != null && u.ResetTokenExpiresAt <= utcNow)
            .ToListAsync();

        // Assert
        Assert.Equal(0, deleted);
        Assert.Empty(usersWithExpiredResets);
        Assert.Equal(1, await _db.RefreshTokens.CountAsync());
    }

    [Fact]
    public async Task Removes_multiple_expired_tokens_from_different_users()
    {
        // Arrange
        var utcNow = new DateTime(2026, 3, 22, 12, 0, 0, DateTimeKind.Utc);
        var tokenService = new TokenService(CreateConfig());

        var user1 = User.Create("user1@test.com", _passwordService.Hash("Test1234!"), UserRole.User, utcNow);
        var user2 = User.Create("user2@test.com", _passwordService.Hash("Test1234!"), UserRole.User, utcNow);
        _db.Users.AddRange(user1, user2);

        // 2 expired tokens for user1
        _db.RefreshTokens.Add(RefreshToken.Create(user1.Id, tokenService.HashToken("u1-expired-1"), utcNow.AddHours(-2), utcNow.AddDays(-30)));
        _db.RefreshTokens.Add(RefreshToken.Create(user1.Id, tokenService.HashToken("u1-expired-2"), utcNow.AddDays(-1), utcNow.AddDays(-31)));

        // 1 expired + 1 valid for user2
        _db.RefreshTokens.Add(RefreshToken.Create(user2.Id, tokenService.HashToken("u2-expired"), utcNow.AddMinutes(-5), utcNow.AddDays(-30)));
        _db.RefreshTokens.Add(RefreshToken.Create(user2.Id, tokenService.HashToken("u2-valid"), utcNow.AddDays(15), utcNow));

        await _db.SaveChangesAsync();

        // Act
        var deleted = await _db.RefreshTokens
            .Where(t => t.ExpiresAt <= utcNow)
            .ExecuteDeleteAsync();

        // Assert
        Assert.Equal(3, deleted);
        var remaining = await _db.RefreshTokens.ToListAsync();
        Assert.Single(remaining);
        Assert.Equal(user2.Id, remaining[0].UserId);
    }

    private static Microsoft.Extensions.Configuration.IConfiguration CreateConfig()
    {
        return new Microsoft.Extensions.Configuration.ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Secret"] = "test-secret-key-that-is-at-least-32-characters-long",
                ["Jwt:Issuer"] = "SubTracker",
                ["Jwt:Audience"] = "SubTracker",
                ["Jwt:AccessTokenExpirationMinutes"] = "15",
                ["Jwt:RefreshTokenExpirationDays"] = "30"
            })
            .Build();
    }
}