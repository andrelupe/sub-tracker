using System.Text.Json.Serialization;

namespace SubTracker.Api.Features.ExchangeRates;

public sealed class FrankfurterClient(HttpClient httpClient)
{
    public async Task<FrankfurterResponse?> GetLatestRatesAsync(
        string baseCurrency = "EUR",
        string[]? symbols = null,
        CancellationToken ct = default)
    {
        var url = $"latest?base={baseCurrency}";

        if (symbols is { Length: > 0 })
            url += $"&symbols={string.Join(",", symbols)}";

        return await httpClient.GetFromJsonAsync<FrankfurterResponse>(url, ct);
    }
}

public sealed record FrankfurterResponse(
    [property: JsonPropertyName("base")] string Base,
    [property: JsonPropertyName("date")] DateOnly Date,
    [property: JsonPropertyName("rates")] Dictionary<string, decimal> Rates);