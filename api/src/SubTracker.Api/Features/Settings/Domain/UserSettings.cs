namespace SubTracker.Api.Features.Settings.Domain;

public sealed class UserSettings
{
    public static readonly string[] SupportedCurrencies = ["EUR", "USD", "GBP"];

    public int Id { get; private set; }
    public Guid UserId { get; private set; }
    public string BaseCurrency { get; private set; } = "EUR";
    public DateTime UpdatedAt { get; private set; }

    private UserSettings() { }

    public static UserSettings CreateDefault(Guid userId, DateTime utcNow)
    {
        return new UserSettings
        {
            UserId = userId,
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