namespace SubTracker.Api.Features.ExchangeRates.Domain;

public sealed class ExchangeRate
{
    public int Id { get; private set; }
    public string BaseCurrency { get; private set; } = string.Empty;
    public string TargetCurrency { get; private set; } = string.Empty;
    public decimal Rate { get; private set; }
    public DateOnly Date { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    private ExchangeRate() { }

    public static ExchangeRate Create(
        string baseCurrency,
        string targetCurrency,
        decimal rate,
        DateOnly date,
        DateTime utcNow)
    {
        return new ExchangeRate
        {
            BaseCurrency = baseCurrency.ToUpperInvariant(),
            TargetCurrency = targetCurrency.ToUpperInvariant(),
            Rate = rate,
            Date = date,
            UpdatedAt = utcNow
        };
    }

    public void Update(decimal rate, DateOnly date, DateTime utcNow)
    {
        Rate = rate;
        Date = date;
        UpdatedAt = utcNow;
    }

    public bool IsStale(DateTime utcNow) =>
        (utcNow - UpdatedAt).TotalHours >= 24;
}
