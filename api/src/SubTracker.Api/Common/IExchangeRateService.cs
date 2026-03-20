namespace SubTracker.Api.Common;

public interface IExchangeRateService
{
    Task<Dictionary<string, decimal>> GetRatesAsync(string baseCurrency, CancellationToken ct = default);
    Task<decimal> ConvertAsync(decimal amount, string from, string to, CancellationToken ct = default);
    Task RefreshRatesAsync(CancellationToken ct = default);
}