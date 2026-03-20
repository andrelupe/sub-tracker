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
using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Tests.Features.Auth;

public sealed class PasswordResetEndpointTests : IDisposable
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    private readonly SqliteConnection _connection;
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public PasswordResetEndpointTests()
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

    private async Task<AuthResponseDto> RegisterUserAsync(string inviteCode)
    {
        var response = await _client.PostAsync("/api/auth/register",
            JsonContent(new { email = "user@test.com", password = "password123", inviteCode }));
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();

        return JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;
    }

    private async Task<string> CreateInviteCodeAsync(string adminAccessToken)
    {
        SetAuthHeader(adminAccessToken);
        var response = await _client.PostAsync("/api/auth/invite-codes", null);
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<InviteCodeCreatedDto>(content, JsonOptions)!;

        return result.Code;
    }

    // ─── RequestPasswordReset ───────────────────────────────────

    [Fact]
    public async Task RequestPasswordReset_Admin_ShouldReturnToken()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        var inviteCode = await CreateInviteCodeAsync(adminAuth.AccessToken);

        _client.DefaultRequestHeaders.Authorization = null;
        await RegisterUserAsync(inviteCode);

        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/request-password-reset",
            JsonContent(new { email = "user@test.com" }));

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<ResetTokenResponseDto>(content, JsonOptions)!;

        Assert.Equal("user@test.com", result.Email);
        Assert.NotEmpty(result.Token);
        Assert.Equal(32, result.Token.Length);
        Assert.True(result.ExpiresAt > DateTime.UtcNow);
    }

    [Fact]
    public async Task RequestPasswordReset_NonExistentUser_ShouldReturn404()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/request-password-reset",
            JsonContent(new { email = "nobody@test.com" }));

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task RequestPasswordReset_NonAdmin_ShouldReturn403()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        var inviteCode = await CreateInviteCodeAsync(adminAuth.AccessToken);

        _client.DefaultRequestHeaders.Authorization = null;
        var userAuth = await RegisterUserAsync(inviteCode);
        SetAuthHeader(userAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/request-password-reset",
            JsonContent(new { email = "admin@test.com" }));

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ─── ResetPassword ──────────────────────────────────────────

    [Fact]
    public async Task ResetPassword_ValidToken_ShouldSucceed()
    {
        // Arrange — admin requests reset for user
        var adminAuth = await RegisterAdminAsync();
        var inviteCode = await CreateInviteCodeAsync(adminAuth.AccessToken);

        _client.DefaultRequestHeaders.Authorization = null;
        await RegisterUserAsync(inviteCode);

        SetAuthHeader(adminAuth.AccessToken);
        var resetResponse = await _client.PostAsync("/api/auth/request-password-reset",
            JsonContent(new { email = "user@test.com" }));
        var resetContent = await resetResponse.Content.ReadAsStringAsync();
        var resetResult = JsonSerializer.Deserialize<ResetTokenResponseDto>(resetContent, JsonOptions)!;

        // Act — user resets password (anonymous)
        _client.DefaultRequestHeaders.Authorization = null;
        var response = await _client.PostAsync("/api/auth/reset-password",
            JsonContent(new { email = "user@test.com", token = resetResult.Token, newPassword = "newpassword456" }));

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Verify login with new password works
        var loginResponse = await _client.PostAsync("/api/auth/login",
            JsonContent(new { email = "user@test.com", password = "newpassword456" }));
        Assert.Equal(HttpStatusCode.OK, loginResponse.StatusCode);

        // Verify old password no longer works
        var oldLoginResponse = await _client.PostAsync("/api/auth/login",
            JsonContent(new { email = "user@test.com", password = "password123" }));
        Assert.Equal(HttpStatusCode.Unauthorized, oldLoginResponse.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_ExpiredToken_ShouldReturn400()
    {
        // Arrange — create user and set an expired reset token directly in DB
        var adminAuth = await RegisterAdminAsync();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var tokenService = scope.ServiceProvider.GetRequiredService<ITokenService>();

        var user = await db.Users.FirstAsync(u => u.Email == "admin@test.com");
        var rawToken = "test-expired-reset-token-value-32";
        var tokenHash = tokenService.HashToken(rawToken);
        user.SetResetToken(tokenHash, DateTime.UtcNow.AddHours(-1), DateTime.UtcNow.AddHours(-2));
        await db.SaveChangesAsync();

        // Act
        _client.DefaultRequestHeaders.Authorization = null;
        var response = await _client.PostAsync("/api/auth/reset-password",
            JsonContent(new { email = "admin@test.com", token = rawToken, newPassword = "newpassword456" }));

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_InvalidToken_ShouldReturn400()
    {
        // Arrange — admin requests reset, but user uses wrong token
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        await _client.PostAsync("/api/auth/request-password-reset",
            JsonContent(new { email = "admin@test.com" }));

        // Act
        _client.DefaultRequestHeaders.Authorization = null;
        var response = await _client.PostAsync("/api/auth/reset-password",
            JsonContent(new { email = "admin@test.com", token = "wrong-token-value-that-is-invalid", newPassword = "newpassword456" }));

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_WrongEmail_ShouldReturn400()
    {
        // Arrange — admin requests reset for admin user
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        var resetResponse = await _client.PostAsync("/api/auth/request-password-reset",
            JsonContent(new { email = "admin@test.com" }));
        var resetContent = await resetResponse.Content.ReadAsStringAsync();
        var resetResult = JsonSerializer.Deserialize<ResetTokenResponseDto>(resetContent, JsonOptions)!;

        // Act — try to use the token with wrong email
        _client.DefaultRequestHeaders.Authorization = null;
        var response = await _client.PostAsync("/api/auth/reset-password",
            JsonContent(new { email = "wrong@test.com", token = resetResult.Token, newPassword = "newpassword456" }));

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // ─── ListPendingResets ──────────────────────────────────────

    [Fact]
    public async Task ListPendingResets_Admin_ShouldReturnPendingResets()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Request a password reset for admin user
        await _client.PostAsync("/api/auth/request-password-reset",
            JsonContent(new { email = "admin@test.com" }));

        // Act
        var response = await _client.GetAsync("/api/auth/pending-resets");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var resets = JsonSerializer.Deserialize<List<PendingResetDto>>(content, JsonOptions)!;

        Assert.Single(resets);
        Assert.Equal("admin@test.com", resets[0].Email);
        Assert.True(resets[0].ExpiresAt > DateTime.UtcNow);
    }

    [Fact]
    public async Task ListPendingResets_ShouldNotIncludeUsedTokens()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Request reset and use it
        var resetResponse = await _client.PostAsync("/api/auth/request-password-reset",
            JsonContent(new { email = "admin@test.com" }));
        var resetContent = await resetResponse.Content.ReadAsStringAsync();
        var resetResult = JsonSerializer.Deserialize<ResetTokenResponseDto>(resetContent, JsonOptions)!;

        _client.DefaultRequestHeaders.Authorization = null;
        await _client.PostAsync("/api/auth/reset-password",
            JsonContent(new { email = "admin@test.com", token = resetResult.Token, newPassword = "newpassword456" }));

        // Login with new password to get new token
        var loginResponse = await _client.PostAsync("/api/auth/login",
            JsonContent(new { email = "admin@test.com", password = "newpassword456" }));
        var loginContent = await loginResponse.Content.ReadAsStringAsync();
        var loginResult = JsonSerializer.Deserialize<AuthResponseDto>(loginContent, JsonOptions)!;
        SetAuthHeader(loginResult.AccessToken);

        // Act
        var response = await _client.GetAsync("/api/auth/pending-resets");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var resets = JsonSerializer.Deserialize<List<PendingResetDto>>(content, JsonOptions)!;

        Assert.Empty(resets);
    }

    [Fact]
    public async Task ListPendingResets_NonAdmin_ShouldReturn403()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        var inviteCode = await CreateInviteCodeAsync(adminAuth.AccessToken);

        _client.DefaultRequestHeaders.Authorization = null;
        var userAuth = await RegisterUserAsync(inviteCode);
        SetAuthHeader(userAuth.AccessToken);

        // Act
        var response = await _client.GetAsync("/api/auth/pending-resets");

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
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

    private sealed record InviteCodeCreatedDto(
        string Code,
        DateTime CreatedAt);

    private sealed record ResetTokenResponseDto(
        string Email,
        string Token,
        DateTime ExpiresAt);

    private sealed record PendingResetDto(
        string Email,
        DateTime ExpiresAt);
}