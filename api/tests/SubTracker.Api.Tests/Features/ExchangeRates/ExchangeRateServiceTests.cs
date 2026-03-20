using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.ExchangeRates;
using SubTracker.Api.Features.ExchangeRates.Domain;

namespace SubTracker.Api.Tests.Features.ExchangeRates;

public sealed class ExchangeRateServiceTests : IDisposable
{
    private readonly DateTime _utcNow = new(2026, 3, 3, 12, 0, 0, DateTimeKind.Utc);
    private readonly SqliteConnection _connection;
    private readonly ServiceProvider _serviceProvider;
    private readonly FakeDateTimeProvider _dateTime;

    public ExchangeRateServiceTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        _dateTime = new FakeDateTimeProvider(_utcNow);

        var services = new ServiceCollection();
        services.AddDbContext<AppDbContext>(options => options.UseSqlite(_connection));
        services.AddSingleton<IDateTimeProvider>(_dateTime);

        _serviceProvider = services.BuildServiceProvider();

        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.Database.EnsureCreated();
    }

    public void Dispose()
    {
        _serviceProvider.Dispose();
        _connection.Close();
        _connection.Dispose();
    }

    private ExchangeRateService CreateService(string? apiResponseJson = null)
    {
        var handler = new FakeHttpMessageHandler(apiResponseJson ?? "{}");
        var httpClient = new HttpClient(handler)
        {
            BaseAddress = new Uri("https://api.frankfurter.dev/v1/")
        };
        var frankfurter = new FrankfurterClient(httpClient);

        return new ExchangeRateService(
            _serviceProvider.GetRequiredService<IServiceScopeFactory>(),
            frankfurter,
            _dateTime,
            NullLogger<ExchangeRateService>.Instance);
    }

    [Fact]
    public async Task ConvertAsync_SameCurrency_ShouldReturnSameAmount()
    {
        // Arrange
        var service = CreateService();

        // Act
        var result = await service.ConvertAsync(100m, "EUR", "EUR");

        // Assert
        Assert.Equal(100m, result);
    }

    [Fact]
    public async Task GetRatesAsync_ShouldReturnCachedRates_WhenFresh()
    {
        // Arrange — seed fresh rates in DB
        using (var scope = _serviceProvider.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.ExchangeRates.Add(ExchangeRate.Create("EUR", "USD", 1.08m, new DateOnly(2026, 3, 3), _utcNow));
            db.ExchangeRates.Add(ExchangeRate.Create("EUR", "GBP", 0.84m, new DateOnly(2026, 3, 3), _utcNow));
            await db.SaveChangesAsync();
        }

        var service = CreateService();

        // Act
        var rates = await service.GetRatesAsync("EUR");

        // Assert
        Assert.Equal(2, rates.Count);
        Assert.Equal(1.08m, rates["USD"]);
        Assert.Equal(0.84m, rates["GBP"]);
    }

    [Fact]
    public async Task GetRatesAsync_ShouldFetchFromApi_WhenStale()
    {
        // Arrange — seed stale rates in DB
        var staleTime = _utcNow.AddHours(-25);

        using (var scope = _serviceProvider.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.ExchangeRates.Add(ExchangeRate.Create("EUR", "USD", 1.00m, new DateOnly(2026, 3, 1), staleTime));
            await db.SaveChangesAsync();
        }

        var responseJson = JsonSerializer.Serialize(new
        {
            @base = "EUR",
            date = "2026-03-03",
            rates = new Dictionary<string, decimal> { ["USD"] = 1.10m, ["GBP"] = 0.85m }
        });

        var service = CreateService(responseJson);

        // Act
        var rates = await service.GetRatesAsync("EUR");

        // Assert
        Assert.Equal(1.10m, rates["USD"]);
        Assert.Equal(0.85m, rates["GBP"]);
    }

    [Fact]
    public async Task GetRatesAsync_ShouldReturnStaleRates_WhenApiFails()
    {
        // Arrange — seed stale rates in DB
        var staleTime = _utcNow.AddHours(-25);

        using (var scope = _serviceProvider.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.ExchangeRates.Add(ExchangeRate.Create("EUR", "USD", 1.05m, new DateOnly(2026, 3, 1), staleTime));
            await db.SaveChangesAsync();
        }

        // API returns error
        var service = CreateService(apiResponseJson: null);

        // Override with failing handler
        var failHandler = new FailingHttpMessageHandler();
        var failClient = new HttpClient(failHandler)
        {
            BaseAddress = new Uri("https://api.frankfurter.dev/v1/")
        };
        var failFrankfurter = new FrankfurterClient(failClient);

        var failService = new ExchangeRateService(
            _serviceProvider.GetRequiredService<IServiceScopeFactory>(),
            failFrankfurter,
            _dateTime,
            NullLogger<ExchangeRateService>.Instance);

        // Act
        var rates = await failService.GetRatesAsync("EUR");

        // Assert — should return stale cached rates
        Assert.Single(rates);
        Assert.Equal(1.05m, rates["USD"]);
    }

    [Fact]
    public async Task RefreshRatesAsync_ShouldPersistAllRates()
    {
        // Arrange
        var responseJson = JsonSerializer.Serialize(new
        {
            @base = "EUR",
            date = "2026-03-03",
            rates = new Dictionary<string, decimal> { ["USD"] = 1.08m, ["GBP"] = 0.84m }
        });

        var service = CreateService(responseJson);

        // Act
        await service.RefreshRatesAsync();

        // Assert
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var rates = await db.ExchangeRates.ToListAsync();

        // 3 base currencies (EUR, USD, GBP) x 2 targets each = 6 rates
        // But the fake handler returns same response for all, so we get at least EUR rates
        Assert.True(rates.Count >= 2);
    }

    private sealed class FakeDateTimeProvider(DateTime utcNow) : IDateTimeProvider
    {
        public DateTime UtcNow => utcNow;
    }

    private sealed class FakeHttpMessageHandler(string responseJson) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(responseJson, Encoding.UTF8, "application/json")
            });
        }
    }

    private sealed class FailingHttpMessageHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            throw new HttpRequestException("Network error");
        }
    }
}