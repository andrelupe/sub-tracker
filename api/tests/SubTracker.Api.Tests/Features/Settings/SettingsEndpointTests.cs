using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using SubTracker.Api.Database;

namespace SubTracker.Api.Tests.Features.Settings;

public sealed class SettingsEndpointTests
{
    private static (HttpClient client, SqliteConnection connection) CreateTestClient()
    {
        var connection = new SqliteConnection("DataSource=:memory:");
        connection.Open();

        var factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
        {
            builder.UseEnvironment("Production");
            builder.UseSetting("ApiKey", string.Empty);

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
    public async Task GetSettings_ShouldReturnDefaults_WhenNoSettingsExist()
    {
        // Arrange
        var (client, connection) = CreateTestClient();
        using var _ = connection;

        // Act
        var response = await client.GetAsync("/api/settings");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadFromJsonAsync<SettingsResponse>();
        Assert.NotNull(content);
        Assert.Equal("EUR", content.BaseCurrency);
    }

    [Fact]
    public async Task UpdateSettings_ShouldChangeBaseCurrency()
    {
        // Arrange
        var (client, connection) = CreateTestClient();
        using var _ = connection;

        var payload = new StringContent(
            JsonSerializer.Serialize(new { baseCurrency = "USD" }),
            Encoding.UTF8,
            "application/json");

        // Act
        var response = await client.PutAsync("/api/settings", payload);

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify via GET
        var getResponse = await client.GetFromJsonAsync<SettingsResponse>("/api/settings");
        Assert.NotNull(getResponse);
        Assert.Equal("USD", getResponse.BaseCurrency);
    }

    [Fact]
    public async Task UpdateSettings_ShouldReturn400_WhenUnsupportedCurrency()
    {
        // Arrange
        var (client, connection) = CreateTestClient();
        using var _ = connection;

        var payload = new StringContent(
            JsonSerializer.Serialize(new { baseCurrency = "JPY" }),
            Encoding.UTF8,
            "application/json");

        // Act
        var response = await client.PutAsync("/api/settings", payload);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateSettings_ShouldReturn400_WhenEmptyCurrency()
    {
        // Arrange
        var (client, connection) = CreateTestClient();
        using var _ = connection;

        var payload = new StringContent(
            JsonSerializer.Serialize(new { baseCurrency = "" }),
            Encoding.UTF8,
            "application/json");

        // Act
        var response = await client.PutAsync("/api/settings", payload);

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
        var (client, connection) = CreateTestClient();
        using var _ = connection;

        var payload = new StringContent(
            JsonSerializer.Serialize(new { baseCurrency = currency }),
            Encoding.UTF8,
            "application/json");

        // Act
        var response = await client.PutAsync("/api/settings", payload);

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    private sealed record SettingsResponse(string BaseCurrency, DateTime UpdatedAt);
}
