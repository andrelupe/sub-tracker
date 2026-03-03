using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using SubTracker.Api.Database;

namespace SubTracker.Api.Tests.Common.Middleware;

public sealed class ApiKeyMiddlewareTests
{
    private const string TestApiKey = "test-api-key-12345";

    private static (HttpClient client, SqliteConnection connection) CreateTestClient(string? apiKey)
    {
        var connection = new SqliteConnection("DataSource=:memory:");
        connection.Open();

        var factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
        {
            builder.UseEnvironment("Production");
            builder.UseSetting("ApiKey", apiKey ?? string.Empty);

            builder.ConfigureServices(services =>
            {
                // Remove background jobs to avoid race conditions with DB
                services.RemoveAll<IHostedService>();

                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor is not null)
                    services.Remove(descriptor);

                services.AddDbContext<AppDbContext>(options =>
                    options.UseSqlite(connection));
            });
        });

        return (factory.CreateClient(), connection);
    }

    [Fact]
    public async Task Request_WithoutHeader_WhenKeyConfigured_Returns401()
    {
        var (client, connection) = CreateTestClient(TestApiKey);
        using var _ = connection;

        var response = await client.GetAsync("/api/subscriptions");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("Invalid API key", content);
    }

    [Fact]
    public async Task Request_WithWrongKey_WhenKeyConfigured_Returns401()
    {
        var (client, connection) = CreateTestClient(TestApiKey);
        using var _ = connection;
        client.DefaultRequestHeaders.Add("X-Api-Key", "wrong-key");

        var response = await client.GetAsync("/api/subscriptions");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("Invalid API key", content);
    }

    [Fact]
    public async Task Request_WithCorrectKey_WhenKeyConfigured_ReturnsSuccess()
    {
        var (client, connection) = CreateTestClient(TestApiKey);
        using var _ = connection;
        client.DefaultRequestHeaders.Add("X-Api-Key", TestApiKey);

        var response = await client.GetAsync("/api/subscriptions");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Request_WithoutHeader_WhenKeyNotConfigured_ReturnsSuccess()
    {
        var (client, connection) = CreateTestClient(string.Empty);
        using var _ = connection;

        var response = await client.GetAsync("/api/subscriptions");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Request_WithoutHeader_WhenKeyNull_ReturnsSuccess()
    {
        var (client, connection) = CreateTestClient(null);
        using var _ = connection;

        var response = await client.GetAsync("/api/subscriptions");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Swagger_WithoutHeader_WhenKeyConfigured_ReturnsSuccess()
    {
        var (client, connection) = CreateTestClient(TestApiKey);
        using var _ = connection;

        var response = await client.GetAsync("/swagger");

        Assert.NotEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
