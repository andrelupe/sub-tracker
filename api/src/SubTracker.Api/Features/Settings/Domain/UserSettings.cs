namespace SubTracker.Api.Features.Settings.Domain;

public sealed class UserSettings
{
    public static readonly string[] SupportedCurrencies = ["EUR", "USD", "GBP"];

    public int Id { get; private set; }
    public string BaseCurrency { get; private set; } = "EUR";
    public DateTime UpdatedAt { get; private set; }

    private UserSettings() { }

    public static UserSettings CreateDefault(DateTime utcNow)
    {
        return new UserSettings
        {
            Id = 1,
            BaseCurrency = "EUR",
            UpdatedAt = utcNow
        };
    }

    public void UpdateBaseCurrency(string currency, DateTime utcNow)
    {
        var normalized = currency.ToUpperInvariant();

        if (!SupportedCurrencies.Contains(normalized))
            throw new ArgumentException($"Unsupported currency: {currency}. Must be one of: {string.Join(", ", SupportedCurrencies)}");

        BaseCurrency = normalized;
        UpdatedAt = utcNow;
    }
}
