using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SubTracker.Api.Database;

namespace SubTracker.Api.Tests.Common.Middleware;

public sealed class ApiKeyMiddlewareTests : IDisposable
{
    private const string TestApiKey = "test-api-key-12345";

    private readonly SqliteConnection _connection;

    public ApiKeyMiddlewareTests()
    {
        // Shared in-memory SQLite connection — stays open for the lifetime of the test
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();
    }

    public void Dispose()
    {
        _connection.Close();
        _connection.Dispose();
    }

    private HttpClient CreateClient(string? apiKey)
    {
        var factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
        {
            builder.UseEnvironment("Production");

            builder.UseSetting("ApiKey", apiKey ?? string.Empty);

            builder.ConfigureServices(services =>
            {
                // Remove the existing AppDbContext registration
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                if (descriptor is not null)
                    services.Remove(descriptor);

                // Register AppDbContext with the shared in-memory connection
                services.AddDbContext<AppDbContext>(options =>
                    options.UseSqlite(_connection));
            });
        });

        // Ensure database schema is created
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.Database.EnsureCreated();

        return factory.CreateClient();
    }

    [Fact]
    public async Task Request_WithoutHeader_WhenKeyConfigured_Returns401()
    {
        // Arrange
        var client = CreateClient(TestApiKey);

        // Act
        var response = await client.GetAsync("/api/subscriptions");

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("Invalid API key", content);
    }

    [Fact]
    public async Task Request_WithWrongKey_WhenKeyConfigured_Returns401()
    {
        // Arrange
        var client = CreateClient(TestApiKey);
        client.DefaultRequestHeaders.Add("X-Api-Key", "wrong-key");

        // Act
        var response = await client.GetAsync("/api/subscriptions");

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("Invalid API key", content);
    }

    [Fact]
    public async Task Request_WithCorrectKey_WhenKeyConfigured_ReturnsSuccess()
    {
        // Arrange
        var client = CreateClient(TestApiKey);
        client.DefaultRequestHeaders.Add("X-Api-Key", TestApiKey);

        // Act
        var response = await client.GetAsync("/api/subscriptions");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Request_WithoutHeader_WhenKeyNotConfigured_ReturnsSuccess()
    {
        // Arrange — empty ApiKey means API is open
        var client = CreateClient(string.Empty);

        // Act
        var response = await client.GetAsync("/api/subscriptions");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Request_WithoutHeader_WhenKeyNull_ReturnsSuccess()
    {
        // Arrange — null ApiKey means API is open
        var client = CreateClient(null);

        // Act
        var response = await client.GetAsync("/api/subscriptions");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Swagger_WithoutHeader_WhenKeyConfigured_ReturnsSuccess()
    {
        // Arrange
        var client = CreateClient(TestApiKey);

        // Act
        var response = await client.GetAsync("/swagger");

        // Assert — swagger should be excluded from auth
        Assert.NotEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
