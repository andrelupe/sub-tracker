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

public sealed class InviteCodeEndpointTests : IDisposable
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    private readonly SqliteConnection _connection;
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public InviteCodeEndpointTests()
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

    private async Task<AuthResponseDto> RegisterUserWithInviteCodeAsync(string inviteCode)
    {
        var response = await _client.PostAsync("/api/auth/register",
            JsonContent(new { email = "user@test.com", password = "password123", inviteCode }));
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();

        return JsonSerializer.Deserialize<AuthResponseDto>(content, JsonOptions)!;
    }

    // ─── CreateInviteCode ───────────────────────────────────────

    [Fact]
    public async Task CreateInviteCode_Admin_ShouldReturnCode()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act
        var response = await _client.PostAsync("/api/auth/invite-codes", null);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<InviteCodeCreatedDto>(content, JsonOptions)!;

        Assert.NotEmpty(result.Code);
        Assert.Equal(8, result.Code.Length);
    }

    [Fact]
    public async Task CreateInviteCode_CodeFormat_ShouldBeUnambiguous()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Act — generate several codes
        var codes = new List<string>();

        for (var i = 0; i < 5; i++)
        {
            var response = await _client.PostAsync("/api/auth/invite-codes", null);
            response.EnsureSuccessStatusCode();
            var content = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize<InviteCodeCreatedDto>(content, JsonOptions)!;
            codes.Add(result.Code);
        }

        // Assert — no ambiguous characters (0, O, I, 1, L)
        const string ambiguous = "0OI1L";

        foreach (var code in codes)
        {
            Assert.Equal(8, code.Length);
            Assert.All(code.ToCharArray(), c =>
                Assert.DoesNotContain(c, ambiguous));
            Assert.All(code.ToCharArray(), c =>
                Assert.True(char.IsLetterOrDigit(c)));
        }
    }

    [Fact]
    public async Task CreateInviteCode_NonAdmin_ShouldReturn403()
    {
        // Arrange — register admin, create invite code, register regular user
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        var createResponse = await _client.PostAsync("/api/auth/invite-codes", null);
        createResponse.EnsureSuccessStatusCode();
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var inviteResult = JsonSerializer.Deserialize<InviteCodeCreatedDto>(createContent, JsonOptions)!;

        // Register regular user
        _client.DefaultRequestHeaders.Authorization = null;
        var userAuth = await RegisterUserWithInviteCodeAsync(inviteResult.Code);
        SetAuthHeader(userAuth.AccessToken);

        // Act — regular user tries to create invite code
        var response = await _client.PostAsync("/api/auth/invite-codes", null);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task CreateInviteCode_Unauthenticated_ShouldReturn401()
    {
        // Act
        var response = await _client.PostAsync("/api/auth/invite-codes", null);

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ─── ListInviteCodes ────────────────────────────────────────

    [Fact]
    public async Task ListInviteCodes_Admin_ShouldReturnCodes()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Create two codes
        await _client.PostAsync("/api/auth/invite-codes", null);
        await _client.PostAsync("/api/auth/invite-codes", null);

        // Act
        var response = await _client.GetAsync("/api/auth/invite-codes");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var codes = JsonSerializer.Deserialize<List<InviteCodeListDto>>(content, JsonOptions)!;

        Assert.Equal(2, codes.Count);
        Assert.All(codes, c => Assert.NotEmpty(c.Code));
        Assert.All(codes, c => Assert.Null(c.UsedByEmail)); // Not used yet
        Assert.All(codes, c => Assert.Null(c.UsedAt));
    }

    [Fact]
    public async Task ListInviteCodes_ShouldShowUsedByEmail_WhenUsed()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        // Create invite code
        var createResponse = await _client.PostAsync("/api/auth/invite-codes", null);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var inviteResult = JsonSerializer.Deserialize<InviteCodeCreatedDto>(createContent, JsonOptions)!;

        // Use it to register a user
        _client.DefaultRequestHeaders.Authorization = null;
        await RegisterUserWithInviteCodeAsync(inviteResult.Code);

        // Act — admin lists codes
        SetAuthHeader(adminAuth.AccessToken);
        var response = await _client.GetAsync("/api/auth/invite-codes");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var codes = JsonSerializer.Deserialize<List<InviteCodeListDto>>(content, JsonOptions)!;

        var usedCode = codes.Single(c => c.Code == inviteResult.Code);
        Assert.Equal("user@test.com", usedCode.UsedByEmail);
        Assert.NotNull(usedCode.UsedAt);
    }

    [Fact]
    public async Task ListInviteCodes_NonAdmin_ShouldReturn403()
    {
        // Arrange
        var adminAuth = await RegisterAdminAsync();
        SetAuthHeader(adminAuth.AccessToken);

        var createResponse = await _client.PostAsync("/api/auth/invite-codes", null);
        var createContent = await createResponse.Content.ReadAsStringAsync();
        var inviteResult = JsonSerializer.Deserialize<InviteCodeCreatedDto>(createContent, JsonOptions)!;

        _client.DefaultRequestHeaders.Authorization = null;
        var userAuth = await RegisterUserWithInviteCodeAsync(inviteResult.Code);
        SetAuthHeader(userAuth.AccessToken);

        // Act
        var response = await _client.GetAsync("/api/auth/invite-codes");

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

    private sealed record InviteCodeListDto(
        string Code,
        DateTime CreatedAt,
        string? UsedByEmail,
        DateTime? UsedAt);
}