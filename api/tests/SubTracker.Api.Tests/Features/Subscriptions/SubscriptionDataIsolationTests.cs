using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection.Extensions;
using SubTracker.Api.Database;

namespace SubTracker.Api.Tests.Features.Subscriptions;

public sealed class SubscriptionDataIsolationTests : IDisposable
{
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    private readonly SqliteConnection _connection;
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public SubscriptionDataIsolationTests()
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

    private async Task<string> CreateInviteCode(string adminAccessToken)
    {
        TestAuthHelper.SetAuthHeader(_client, adminAccessToken);
        var response = await _client.PostAsync("/api/auth/invite-codes", null);
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonSerializer.Deserialize<JsonElement>(content);

        return json.GetProperty("code").GetString()!;
    }

    private async Task<Guid> CreateSubscription(string name = "Test Sub", decimal amount = 9.99m)
    {
        var payload = JsonContent(new
        {
            name,
            amount,
            currency = "EUR",
            billingCycle = 1, // Monthly
            category = 0, // Entertainment
            startDate = "2026-01-15",
            reminderDaysBefore = 2
        });

        var response = await _client.PostAsync("/api/subscriptions", payload);
        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        var json = JsonSerializer.Deserialize<JsonElement>(content);

        return json.GetProperty("id").GetGuid();
    }

    // ─── Unauthenticated Access ─────────────────────────────────

    [Fact]
    public async Task GetAll_Unauthenticated_ShouldReturn401()
    {
        var response = await _client.GetAsync("/api/subscriptions");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Create_Unauthenticated_ShouldReturn401()
    {
        var payload = JsonContent(new
        {
            name = "Test",
            amount = 10m,
            currency = "EUR",
            billingCycle = 1,
            category = 0,
            startDate = "2026-01-15"
        });

        var response = await _client.PostAsync("/api/subscriptions", payload);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ─── Data Isolation ─────────────────────────────────────────

    [Fact]
    public async Task UserA_ShouldNotSee_UserB_Subscriptions()
    {
        // Arrange — User A (admin)
        var userA = await TestAuthHelper.RegisterAndLogin(_client, "usera@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);

        // User A creates a subscription
        await CreateSubscription("User A - Netflix");

        // Register User B via invite code
        var inviteCode = await CreateInviteCode(userA.AccessToken);
        var userB = await TestAuthHelper.RegisterWithInviteCode(_client, inviteCode, "userb@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userB.AccessToken);

        // Act — User B gets subscriptions
        var response = await _client.GetAsync("/api/subscriptions");
        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        var subscriptions = JsonSerializer.Deserialize<List<JsonElement>>(content, JsonOptions)!;

        // Assert — User B should see 0 subscriptions
        Assert.Empty(subscriptions);
    }

    [Fact]
    public async Task UserA_ShouldNotAccess_UserB_SubscriptionById()
    {
        // Arrange — User A creates subscription
        var userA = await TestAuthHelper.RegisterAndLogin(_client, "usera-getbyid@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);

        var subId = await CreateSubscription("User A - Spotify");

        // Register User B
        var inviteCode = await CreateInviteCode(userA.AccessToken);
        var userB = await TestAuthHelper.RegisterWithInviteCode(_client, inviteCode, "userb-getbyid@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userB.AccessToken);

        // Act — User B tries to get User A's subscription
        var response = await _client.GetAsync($"/api/subscriptions/{subId}");

        // Assert — should be 404 (not found for this user)
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UserA_ShouldNotUpdate_UserB_Subscription()
    {
        // Arrange — User A creates subscription
        var userA = await TestAuthHelper.RegisterAndLogin(_client, "usera-update@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);

        var subId = await CreateSubscription("User A - Disney+");

        // Register User B
        var inviteCode = await CreateInviteCode(userA.AccessToken);
        var userB = await TestAuthHelper.RegisterWithInviteCode(_client, inviteCode, "userb-update@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userB.AccessToken);

        // Act — User B tries to update User A's subscription
        var payload = JsonContent(new
        {
            id = subId,
            name = "HACKED",
            amount = 999m,
            currency = "EUR",
            billingCycle = 1,
            category = 0,
            startDate = "2026-01-15",
            reminderDaysBefore = 2,
            isActive = true
        });

        var response = await _client.PutAsync($"/api/subscriptions/{subId}", payload);

        // Assert — should be 404
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UserA_ShouldNotDelete_UserB_Subscription()
    {
        // Arrange — User A creates subscription
        var userA = await TestAuthHelper.RegisterAndLogin(_client, "usera-delete@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);

        var subId = await CreateSubscription("User A - HBO");

        // Register User B
        var inviteCode = await CreateInviteCode(userA.AccessToken);
        var userB = await TestAuthHelper.RegisterWithInviteCode(_client, inviteCode, "userb-delete@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userB.AccessToken);

        // Act — User B tries to delete User A's subscription
        var response = await _client.DeleteAsync($"/api/subscriptions/{subId}");

        // Assert — should be 404
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        // Verify — User A can still see their subscription
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);
        var getResponse = await _client.GetAsync($"/api/subscriptions/{subId}");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
    }

    [Fact]
    public async Task EachUser_ShouldOnlySee_OwnSubscriptions()
    {
        // Arrange — User A (admin)
        var userA = await TestAuthHelper.RegisterAndLogin(_client, "usera-both@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);

        await CreateSubscription("User A - Sub 1");
        await CreateSubscription("User A - Sub 2");

        // Register User B
        var inviteCode = await CreateInviteCode(userA.AccessToken);
        var userB = await TestAuthHelper.RegisterWithInviteCode(_client, inviteCode, "userb-both@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userB.AccessToken);

        await CreateSubscription("User B - Sub 1");

        // Act — User A gets their subscriptions
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);
        var responseA = await _client.GetAsync("/api/subscriptions");
        responseA.EnsureSuccessStatusCode();
        var subsA = JsonSerializer.Deserialize<List<JsonElement>>(await responseA.Content.ReadAsStringAsync(), JsonOptions)!;

        // Act — User B gets their subscriptions
        TestAuthHelper.SetAuthHeader(_client, userB.AccessToken);
        var responseB = await _client.GetAsync("/api/subscriptions");
        responseB.EnsureSuccessStatusCode();
        var subsB = JsonSerializer.Deserialize<List<JsonElement>>(await responseB.Content.ReadAsStringAsync(), JsonOptions)!;

        // Assert
        Assert.Equal(2, subsA.Count);
        Assert.All(subsA, s => Assert.StartsWith("User A", s.GetProperty("name").GetString()!));

        Assert.Single(subsB);
        Assert.StartsWith("User B", subsB[0].GetProperty("name").GetString()!);
    }

    [Fact]
    public async Task Import_ShouldAssociateToCurrentUser()
    {
        // Arrange — User A (admin)
        var userA = await TestAuthHelper.RegisterAndLogin(_client, "usera-import@test.com", "TestPassword123!");
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);

        // Create invite code for User B
        var inviteCode = await CreateInviteCode(userA.AccessToken);
        var userB = await TestAuthHelper.RegisterWithInviteCode(_client, inviteCode, "userb-import@test.com", "TestPassword123!");

        // User B imports subscriptions
        TestAuthHelper.SetAuthHeader(_client, userB.AccessToken);
        var importPayload = JsonContent(new
        {
            subscriptions = new[]
            {
                new
                {
                    name = "Imported Sub 1",
                    amount = 5.99m,
                    currency = "EUR",
                    billingCycle = "Monthly",
                    category = "Entertainment",
                    startDate = "2026-01-15"
                },
                new
                {
                    name = "Imported Sub 2",
                    amount = 12.99m,
                    currency = "USD",
                    billingCycle = "Yearly",
                    category = "Music",
                    startDate = "2026-02-01"
                }
            }
        });

        var importResponse = await _client.PostAsync("/api/subscriptions/import", importPayload);
        importResponse.EnsureSuccessStatusCode();

        // Act — User A should not see imported subs
        TestAuthHelper.SetAuthHeader(_client, userA.AccessToken);
        var responseA = await _client.GetAsync("/api/subscriptions");
        responseA.EnsureSuccessStatusCode();
        var subsA = JsonSerializer.Deserialize<List<JsonElement>>(await responseA.Content.ReadAsStringAsync(), JsonOptions)!;

        // User B should see the 2 imported subs
        TestAuthHelper.SetAuthHeader(_client, userB.AccessToken);
        var responseB = await _client.GetAsync("/api/subscriptions");
        responseB.EnsureSuccessStatusCode();
        var subsB = JsonSerializer.Deserialize<List<JsonElement>>(await responseB.Content.ReadAsStringAsync(), JsonOptions)!;

        // Assert
        Assert.Empty(subsA);
        Assert.Equal(2, subsB.Count);
    }
}