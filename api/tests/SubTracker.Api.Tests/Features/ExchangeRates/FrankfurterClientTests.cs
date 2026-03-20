using System.Net;
using System.Text;
using System.Text.Json;
using SubTracker.Api.Features.ExchangeRates;

namespace SubTracker.Api.Tests.Features.ExchangeRates;

public sealed class FrankfurterClientTests
{
    [Fact]
    public async Task GetLatestRatesAsync_ShouldReturnRates()
    {
        // Arrange
        var responseJson = JsonSerializer.Serialize(new
        {
            @base = "EUR",
            date = "2026-03-03",
            rates = new Dictionary<string, decimal> { ["USD"] = 1.08m, ["GBP"] = 0.84m }
        });

        var handler = new FakeHttpMessageHandler(responseJson);
        var httpClient = new HttpClient(handler)
        {
            BaseAddress = new Uri("https://api.frankfurter.dev/v1/")
        };

        var client = new FrankfurterClient(httpClient);

        // Act
        var result = await client.GetLatestRatesAsync("EUR", ["USD", "GBP"]);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("EUR", result.Base);
        Assert.Equal(new DateOnly(2026, 3, 3), result.Date);
        Assert.Equal(2, result.Rates.Count);
        Assert.Equal(1.08m, result.Rates["USD"]);
        Assert.Equal(0.84m, result.Rates["GBP"]);
    }

    [Fact]
    public async Task GetLatestRatesAsync_ShouldBuildCorrectUrl_WithSymbols()
    {
        // Arrange
        var responseJson = JsonSerializer.Serialize(new
        {
            @base = "USD",
            date = "2026-03-03",
            rates = new Dictionary<string, decimal> { ["EUR"] = 0.93m }
        });

        var handler = new FakeHttpMessageHandler(responseJson);
        var httpClient = new HttpClient(handler)
        {
            BaseAddress = new Uri("https://api.frankfurter.dev/v1/")
        };

        var client = new FrankfurterClient(httpClient);

        // Act
        await client.GetLatestRatesAsync("USD", ["EUR"]);

        // Assert
        Assert.NotNull(handler.LastRequestUri);
        Assert.Contains("base=USD", handler.LastRequestUri.ToString());
        Assert.Contains("symbols=EUR", handler.LastRequestUri.ToString());
    }

    [Fact]
    public async Task GetLatestRatesAsync_WithoutSymbols_ShouldNotIncludeSymbolsParam()
    {
        // Arrange
        var responseJson = JsonSerializer.Serialize(new
        {
            @base = "EUR",
            date = "2026-03-03",
            rates = new Dictionary<string, decimal> { ["USD"] = 1.08m }
        });

        var handler = new FakeHttpMessageHandler(responseJson);
        var httpClient = new HttpClient(handler)
        {
            BaseAddress = new Uri("https://api.frankfurter.dev/v1/")
        };

        var client = new FrankfurterClient(httpClient);

        // Act
        await client.GetLatestRatesAsync("EUR");

        // Assert
        Assert.NotNull(handler.LastRequestUri);
        Assert.DoesNotContain("symbols", handler.LastRequestUri.ToString());
    }

    private sealed class FakeHttpMessageHandler(string responseJson) : HttpMessageHandler
    {
        public Uri? LastRequestUri { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            LastRequestUri = request.RequestUri;

            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(responseJson, Encoding.UTF8, "application/json")
            });
        }
    }
}