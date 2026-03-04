using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.ExchangeRates.Domain;

namespace SubTracker.Api.Features.ExchangeRates;

public sealed class ExchangeRateService : IExchangeRateService
{
    private static readonly string[] SupportedCurrencies = ["EUR", "USD", "GBP"];

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly FrankfurterClient _frankfurter;
    private readonly IDateTimeProvider _dateTime;
    private readonly ILogger<ExchangeRateService> _logger;

    public ExchangeRateService(
        IServiceScopeFactory scopeFactory,
        FrankfurterClient frankfurter,
        IDateTimeProvider dateTime,
        ILogger<ExchangeRateService> logger)
    {
        _scopeFactory = scopeFactory;
        _frankfurter = frankfurter;
        _dateTime = dateTime;
        _logger = logger;
    }

    public async Task<Dictionary<string, decimal>> GetRatesAsync(
        string baseCurrency,
        CancellationToken ct = default)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var utcNow = _dateTime.UtcNow;

        var cachedRates = await db.ExchangeRates
            .Where(r => r.BaseCurrency == baseCurrency)
            .ToListAsync(ct);

        // Return cached rates if fresh
        if (cachedRates.Count > 0 && cachedRates.All(r => !r.IsStale(utcNow)))
        {
            return cachedRates.ToDictionary(r => r.TargetCurrency, r => r.Rate);
        }

        // Fallback to API
        try
        {
            var symbols = SupportedCurrencies.Where(c => c != baseCurrency).ToArray();
            var response = await _frankfurter.GetLatestRatesAsync(baseCurrency, symbols, ct);

            if (response is not null)
            {
                await PersistRatesAsync(db, baseCurrency, response.Rates, response.Date, utcNow, ct);
                return response.Rates;
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to fetch rates from Frankfurter API for {BaseCurrency}, using cached rates", baseCurrency);
        }

        // Return stale cached rates as last resort
        return cachedRates.ToDictionary(r => r.TargetCurrency, r => r.Rate);
    }

    public async Task<decimal> ConvertAsync(
        decimal amount,
        string from,
        string to,
        CancellationToken ct = default)
    {
        if (from == to) return amount;

        var rates = await GetRatesAsync(from, ct);

        if (rates.TryGetValue(to, out var directRate))
            return amount * directRate;

        // Transitive conversion via EUR
        if (from != "EUR" && to != "EUR")
        {
            var fromEurRates = await GetRatesAsync("EUR", ct);
            if (fromEurRates.TryGetValue(from, out var eurToFrom) &&
                fromEurRates.TryGetValue(to, out var eurToTo) &&
                eurToFrom > 0)
            {
                return amount / eurToFrom * eurToTo;
            }
        }

        _logger.LogWarning("No exchange rate found for {From} -> {To}, returning original amount", from, to);
        return amount;
    }

    public async Task RefreshRatesAsync(CancellationToken ct = default)
    {
        _logger.LogInformation("Refreshing exchange rates");
        var utcNow = _dateTime.UtcNow;

        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        foreach (var baseCurrency in SupportedCurrencies)
        {
            try
            {
                var symbols = SupportedCurrencies.Where(c => c != baseCurrency).ToArray();
                var response = await _frankfurter.GetLatestRatesAsync(baseCurrency, symbols, ct);

                if (response is not null)
                {
                    await PersistRatesAsync(db, baseCurrency, response.Rates, response.Date, utcNow, ct);

                    _logger.LogInformation(
                        "Updated rates for {BaseCurrency}: {Rates}",
                        baseCurrency,
                        string.Join(", ", response.Rates.Select(r => $"{r.Key}={r.Value}")));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to refresh rates for {BaseCurrency}", baseCurrency);
            }
        }
    }

    private static async Task PersistRatesAsync(
        AppDbContext db,
        string baseCurrency,
        Dictionary<string, decimal> rates,
        DateOnly date,
        DateTime utcNow,
        CancellationToken ct)
    {
        foreach (var (targetCurrency, rate) in rates)
        {
            var existing = await db.ExchangeRates
                .FirstOrDefaultAsync(r =>
                    r.BaseCurrency == baseCurrency &&
                    r.TargetCurrency == targetCurrency, ct);

            if (existing is not null)
            {
                existing.Update(rate, date, utcNow);
            }
            else
            {
                db.ExchangeRates.Add(ExchangeRate.Create(baseCurrency, targetCurrency, rate, date, utcNow));
            }
        }

        await db.SaveChangesAsync(ct);
    }
}
