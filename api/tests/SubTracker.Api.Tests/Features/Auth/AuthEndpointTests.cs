using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection.Extensions;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;
using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Tests.Features.Auth;

public sealed class AuthEndpointTests : IDisposable
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    private readonly SqliteConnection _connection;
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public AuthEndpointTests()
    {
        _connection = TestDbHelper.CreateConnection();

        _factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
        {
            builder.UseEnvironment("Production");
            builder.UseSetting("Jwt:Secret", "test-secret-key-that-is-at-least-32-characters-long");
            builder.UseSetting("Jwt:Issuer", "SubTracker");
            builder.UseSetting("Jwt:Audience", "SubTracker");
            builder.UseSetting("Jwt:AccessTokenExpirationMinutes", "15");
            builder.UseSetting("Jwt:RefreshTokenExpirationDays", "30");

            builder.ConfigureServices(services =>
            {
                services.RemoveAll<IHostedService>();

                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor is not null)
                    services.Remove(descriptor);

                services.AddDbContext<AppDbContext>(options =>
                    options.UseSqlite(_connection)
                        .ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning)));
            });
        });

        _client = _factory.CreateClient();
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
        _connection.Dispose();
    }

    private StringContent JsonContent(object obj) =>
        new(JsonSerializer.Serialize(obj), Encoding.UTF8, "application/json");

    private async Task<AuthResponseDto> RegisterUserAsync(string email = "test@example.com", string password = "password123", string? inviteCode = null)
    {
        var payload = new { email, password, inviteCode };
        var response = await _client.PostAsync("/api/auth/register", JsonContent(payload));
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();

        return JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;
    }

    private async Task<AuthResponseDto> LoginUserAsync(string email, string password)
    {
        var payload = new { email, password };
        var response = await _client.PostAsync("/api/auth/login", JsonContent(payload));
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();

        return JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;
    }

    private void SetAuthHeader(string accessToken)
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
    }

    // ─── Register ───────────────────────────────────────────────

    [Fact]
    public async Task Register_FirstUser_ShouldBeAdmin()
    {
        // Arrange — clean DB with no users (TestDbHelper seeds a placeholder user)
        // Remove placeholder user first
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        // Act
        var response = await _client.PostAsync("/api/auth/register",
            JsonContent(new { email = "admin@test.com", password = "password123" }));

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var auth = JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;

        Assert.NotEmpty(auth.AccessToken);
        Assert.NotEmpty(auth.RefreshToken);
        Assert.True(auth.ExpiresIn > 0);
        Assert.Equal("admin@test.com", auth.User.Email);
        Assert.Equal("Admin", auth.User.Role);
    }

    [Fact]
    public async Task Register_WithInviteCode_ShouldBeUser()
    {
        // Arrange — create admin and generate invite code
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        // Register first user (admin)
        var adminAuth = await RegisterAdminAsync();

        // Create invite code directly in DB
        var inviteCode = InviteCode.Create(adminAuth.User.Id, "TESTCODE", DateTime.UtcNow);
        db.InviteCodes.Add(inviteCode);
        await db.SaveChangesAsync();

        // Act
        var response = await _client.PostAsync("/api/auth/register",
            JsonContent(new { email = "user@test.com", password = "password123", inviteCode = "TESTCODE" }));

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var auth = JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;

        Assert.Equal("user@test.com", auth.User.Email);
        Assert.Equal("User", auth.User.Role);
    }

    [Fact]
    public async Task Register_DuplicateEmail_ShouldReturn409()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        await RegisterAdminAsync();

        // Act — try to register with same email
        var response = await _client.PostAsync("/api/auth/register",
            JsonContent(new { email = "admin@test.com", password = "password123" }));

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Register_MissingInviteCode_WhenUsersExist_ShouldReturn400()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        await RegisterAdminAsync();

        // Act — second user without invite code
        var response = await _client.PostAsync("/api/auth/register",
            JsonContent(new { email = "user@test.com", password = "password123" }));

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // ─── Login ──────────────────────────────────────────────────

    [Fact]
    public async Task Login_Success_ShouldReturnTokens()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        await RegisterAdminAsync();

        // Act
        var response = await _client.PostAsync("/api/auth/login",
            JsonContent(new { email = "admin@test.com", password = "password123" }));

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var auth = JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;

        Assert.NotEmpty(auth.AccessToken);
        Assert.NotEmpty(auth.RefreshToken);
        Assert.Equal("admin@test.com", auth.User.Email);
    }

    [Fact]
    public async Task Login_WrongPassword_ShouldReturn401()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        await RegisterAdminAsync();

        // Act
        var response = await _client.PostAsync("/api/auth/login",
            JsonContent(new { email = "admin@test.com", password = "wrongpassword" }));

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Login_NonExistentUser_ShouldReturn401()
    {
        // Act
        var response = await _client.PostAsync("/api/auth/login",
            JsonContent(new { email = "nobody@test.com", password = "password123" }));

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ─── Refresh ────────────────────────────────────────────────

    [Fact]
    public async Task Refresh_ValidToken_ShouldReturnNewAccessToken()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        var adminAuth = await RegisterAdminAsync();

        // Act
        var response = await _client.PostAsync("/api/auth/refresh",
            JsonContent(new { refreshToken = adminAuth.RefreshToken }));

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var refreshResponse = JsonSerializer.Deserialize<RefreshResponseDto>(content, JsonOptions)!;

        Assert.NotEmpty(refreshResponse.AccessToken);
        Assert.True(refreshResponse.ExpiresIn > 0);
    }

    [Fact]
    public async Task Refresh_InvalidToken_ShouldReturn401()
    {
        // Act
        var response = await _client.PostAsync("/api/auth/refresh",
            JsonContent(new { refreshToken = "invalid-token-value" }));

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Refresh_ExpiredToken_ShouldReturn401()
    {
        // Arrange — create user and insert an already-expired refresh token
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        var adminAuth = await RegisterAdminAsync();

        // Insert a separate expired refresh token directly via SQL
        var tokenService = scope.ServiceProvider.GetRequiredService<ITokenService>();
        var expiredRawToken = "expired-test-token-value";
        var expiredHash = tokenService.HashToken(expiredRawToken);
        var userId = adminAuth.User.Id;

        await db.Database.ExecuteSqlInterpolatedAsync(
            $"INSERT INTO RefreshTokens (Id, UserId, TokenHash, ExpiresAt, CreatedAt) VALUES ({Guid.NewGuid()}, {userId}, {expiredHash}, {DateTime.UtcNow.AddDays(-1)}, {DateTime.UtcNow.AddDays(-31)})");

        // Act
        var response = await _client.PostAsync("/api/auth/refresh",
            JsonContent(new { refreshToken = expiredRawToken }));

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ─── Logout ─────────────────────────────────────────────────

    [Fact]
    public async Task Logout_ValidToken_ShouldRevokeRefreshToken()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/logout",
            JsonContent(new { refreshToken = adminAuth.RefreshToken }));

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify refresh token is revoked — subsequent refresh should fail
        _client.DefaultRequestHeaders.Authorization = null;
        var refreshResponse = await _client.PostAsync("/api/auth/refresh",
            JsonContent(new { refreshToken = adminAuth.RefreshToken }));

        Assert.Equal(HttpStatusCode.Unauthorized, refreshResponse.StatusCode);
    }

    [Fact]
    public async Task Logout_InvalidToken_ShouldStillReturn204()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/logout",
            JsonContent(new { refreshToken = "nonexistent-token" }));

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    // ─── Me ─────────────────────────────────────────────────────

    [Fact]
    public async Task Me_Authenticated_ShouldReturnUserInfo()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.GetAsync("/api/auth/me");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var me = JsonSerializer.Deserialize<MeResponseDto>(content, JsonOptions)!;

        Assert.Equal("admin@test.com", me.Email);
        Assert.Equal("Admin", me.Role);
        Assert.NotEqual(Guid.Empty, me.Id);
    }

    [Fact]
    public async Task Me_Unauthenticated_ShouldReturn401()
    {
        // Act
        var response = await _client.GetAsync("/api/auth/me");

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ─── Helpers ────────────────────────────────────────────────

    private async Task<AuthResponseDto> RegisterAdminAsync()
    {
        var response = await _client.PostAsync("/api/auth/register",
            JsonContent(new { email = "admin@test.com", password = "password123" }));
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();

        return JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;
    }

    // ─── DTOs ───────────────────────────────────────────────────

    private sealed record AuthResponseDto(
        string AccessToken,
        string RefreshToken,
        int ExpiresIn,
        UserResponseDto User);

    private sealed record UserResponseDto(
        Guid Id,
        string Email,
        string Role);

    private sealed record RefreshResponseDto(
        string AccessToken,
        int ExpiresIn);

    private sealed record MeResponseDto(
        Guid Id,
        string Email,
        string Role,
        DateTime CreatedAt);
}