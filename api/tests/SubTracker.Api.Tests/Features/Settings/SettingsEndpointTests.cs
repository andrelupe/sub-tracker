using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection.Extensions;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Tests.Features.Settings;

public sealed class SettingsEndpointTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public SettingsEndpointTests()
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

    private async Task<TestAuthHelper.AuthResult> SetupAuthenticatedUser()
    {
        var auth = await TestAuthHelper.RegisterAndLogin(_client, "settings-user@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, auth.AccessToken);

        return auth;
    }

    [Fact]
    public async Task GetSettings_Authenticated_ShouldReturnDefaults_WhenNoSettingsExist()
    {
        // Arrange
        await SetupAuthenticatedUser();

        // Act
        var response = await _client.GetAsync("/api/settings");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<SettingsResponse>();
        Assert.NotNull(content);
        Assert.Equal("EUR", content.BaseCurrency);
    }

    [Fact]
    public async Task GetSettings_Unauthenticated_ShouldReturn401()
    {
        // Act
        var response = await _client.GetAsync("/api/settings");

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task UpdateSettings_Authenticated_ShouldChangeBaseCurrency()
    {
        // Arrange
        await SetupAuthenticatedUser();

        var payload = new StringContent(
            JsonSerializer.Serialize(new { baseCurrency = "USD" }),
            Encoding.UTF8,
            "application/json");

        // Act
        var response = await _client.PutAsync("/api/settings", payload);

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify via GET
        var getResponse = await _client.GetFromJsonAsync<SettingsResponse>("/api/settings");
        Assert.NotNull(getResponse);
        Assert.Equal("USD", getResponse.BaseCurrency);
    }

    [Fact]
    public async Task UpdateSettings_ShouldReturn400_WhenUnsupportedCurrency()
    {
        // Arrange
        await SetupAuthenticatedUser();

        var payload = new StringContent(
            JsonSerializer.Serialize(new { baseCurrency = "JPY" }),
            Encoding.UTF8,
            "application/json");

        // Act
        var response = await _client.PutAsync("/api/settings", payload);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateSettings_ShouldReturn400_WhenEmptyCurrency()
    {
        // Arrange
        await SetupAuthenticatedUser();

        var payload = new StringContent(
            JsonSerializer.Serialize(new { baseCurrency = "" }),
            Encoding.UTF8,
            "application/json");

        // Act
        var response = await _client.PutAsync("/api/settings", payload);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Theory]
    [InlineData("EUR")]
    [InlineData("USD")]
    [InlineData("GBP")]
    public async Task UpdateSettings_AllSupportedCurrencies_ShouldSucceed(string currency)
    {
        // Arrange
        await SetupAuthenticatedUser();

        var payload = new StringContent(
            JsonSerializer.Serialize(new { baseCurrency = currency }),
            Encoding.UTF8,
            "application/json");

        // Act
        var response = await _client.PutAsync("/api/settings", payload);

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task Settings_ShouldBeIsolatedPerUser()
    {
        // Arrange — register User A (admin) and set their currency to USD
        var userA = await TestAuthHelper.RegisterAndLogin(_client, "usera-settings@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);

        var payload = new StringContent(
            JsonSerializer.Serialize(new { baseCurrency = "USD" }),
            Encoding.UTF8,
            "application/json");
        await _client.PutAsync("/api/settings", payload);

        // Register User B via invite code
        var inviteCode = await CreateInviteCode(userA.AccessToken);
        var userB = await TestAuthHelper.RegisterWithInviteCode(_client, inviteCode, "userb-settings@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userB.AccessToken);

        // Act — User B gets their own settings (should be default EUR)
        var response = await _client.GetFromJsonAsync<SettingsResponse>("/api/settings");

        // Assert
        Assert.NotNull(response);
        Assert.Equal("EUR", response.BaseCurrency);

        // Switch back to User A — should still be USD
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);
        var responseA = await _client.GetFromJsonAsync<SettingsResponse>("/api/settings");
        Assert.NotNull(responseA);
        Assert.Equal("USD", responseA.BaseCurrency);
    }

    private async Task<string> CreateInviteCode(string adminAccessToken)
    {
        TestAuthHelper.SetAuthHeader(_client, adminAccessToken);
        var response = await _client.PostAsync("/api/auth/invite-codes", null);
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonSerializer.Deserialize<JsonElement>(content);

        return json.GetProperty("code").GetString()!;
    }

    private sealed record SettingsResponse(string BaseCurrency, DateTime UpdatedAt);
}
