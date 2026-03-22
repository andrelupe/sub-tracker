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

namespace SubTracker.Api.Tests.Features.Auth;

public sealed class ChangePasswordEndpointTests : IDisposable
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    private readonly SqliteConnection _connection;
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public ChangePasswordEndpointTests()
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
            builder.UseSetting("SkipSeeding", "true");

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

    private void SetAuthHeader(string accessToken) =>
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

    private async Task<AuthResponseDto> RegisterAdminAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Users.ExecuteDeleteAsync();

        var response = await _client.PostAsync("/api/auth/register",
            JsonContent(new { email = "admin@test.com", password = "password123" }));
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();

        return JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;
    }

    // ─── ChangePassword ─────────────────────────────────────────

    [Fact]
    public async Task ChangePassword_ValidCurrentPassword_ShouldSucceed()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/change-password",
            JsonContent(new { currentPassword = "password123", newPassword = "newpassword456" }));

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Verify login with new password
        _client.DefaultRequestHeaders.Authorization = null;
        var loginResponse = await _client.PostAsync("/api/auth/login",
            JsonContent(new { email = "admin@test.com", password = "newpassword456" }));
        Assert.Equal(HttpStatusCode.OK, loginResponse.StatusCode);

        // Verify old password no longer works
        var oldLoginResponse = await _client.PostAsync("/api/auth/login",
            JsonContent(new { email = "admin@test.com", password = "password123" }));
        Assert.Equal(HttpStatusCode.Unauthorized, oldLoginResponse.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_WrongCurrentPassword_ShouldReturn400()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/change-password",
            JsonContent(new { currentPassword = "wrongpassword", newPassword = "newpassword456" }));

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_ShouldRevokeRefreshTokens()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/change-password",
            JsonContent(new { currentPassword = "password123", newPassword = "newpassword456" }));
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Assert — old refresh token should be revoked
        _client.DefaultRequestHeaders.Authorization = null;
        var refreshResponse = await _client.PostAsync("/api/auth/refresh",
            JsonContent(new { refreshToken = adminAuth.RefreshToken }));
        Assert.Equal(HttpStatusCode.Unauthorized, refreshResponse.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_Unauthenticated_ShouldReturn401()
    {
        // Act
        var response = await _client.PostAsync("/api/auth/change-password",
            JsonContent(new { currentPassword = "password123", newPassword = "newpassword456" }));

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_ShortNewPassword_ShouldReturn400()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/change-password",
            JsonContent(new { currentPassword = "password123", newPassword = "short" }));

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
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
}