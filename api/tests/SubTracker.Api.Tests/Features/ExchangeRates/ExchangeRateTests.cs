using SubTracker.Api.Features.ExchangeRates.Domain;

namespace SubTracker.Api.Tests.Features.ExchangeRates;

public sealed class ExchangeRateTests
{
    private readonly DateTime _utcNow = new(2026, 3, 3, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Create_ShouldSetAllProperties()
    {
        // Arrange & Act
        var rate = ExchangeRate.Create("EUR", "USD", 1.08m, new DateOnly(2026, 3, 3), _utcNow);

        // Assert
        Assert.Equal("EUR", rate.BaseCurrency);
        Assert.Equal("USD", rate.TargetCurrency);
        Assert.Equal(1.08m, rate.Rate);
        Assert.Equal(new DateOnly(2026, 3, 3), rate.Date);
        Assert.Equal(_utcNow, rate.UpdatedAt);
    }

    [Fact]
    public void Create_ShouldNormalizeCurrencyToUpperCase()
    {
        // Act
        var rate = ExchangeRate.Create("eur", "usd", 1.08m, new DateOnly(2026, 3, 3), _utcNow);

        // Assert
        Assert.Equal("EUR", rate.BaseCurrency);
        Assert.Equal("USD", rate.TargetCurrency);
    }

    [Fact]
    public void Update_ShouldModifyRateAndDate()
    {
        // Arrange
        var rate = ExchangeRate.Create("EUR", "USD", 1.08m, new DateOnly(2026, 3, 3), _utcNow);
        var newDate = new DateOnly(2026, 3, 4);
        var newUtcNow = _utcNow.AddDays(1);

        // Act
        rate.Update(1.10m, newDate, newUtcNow);

        // Assert
        Assert.Equal(1.10m, rate.Rate);
        Assert.Equal(newDate, rate.Date);
        Assert.Equal(newUtcNow, rate.UpdatedAt);
    }

    [Fact]
    public void IsStale_ShouldReturnFalse_WhenFresh()
    {
        // Arrange
        var rate = ExchangeRate.Create("EUR", "USD", 1.08m, new DateOnly(2026, 3, 3), _utcNow);

        // Act & Assert
        Assert.False(rate.IsStale(_utcNow.AddHours(23)));
    }

    [Fact]
    public void IsStale_ShouldReturnTrue_WhenOlderThan24Hours()
    {
        // Arrange
        var rate = ExchangeRate.Create("EUR", "USD", 1.08m, new DateOnly(2026, 3, 3), _utcNow);

        // Act & Assert
        Assert.True(rate.IsStale(_utcNow.AddHours(25)));
    }
}