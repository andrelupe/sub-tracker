using SubTracker.Api.Features.Settings.Domain;

namespace SubTracker.Api.Tests.Features.Settings;

public sealed class UserSettingsTests
{
    private readonly DateTime _utcNow = new(2026, 3, 3, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void CreateDefault_ShouldSetEurAsBaseCurrency()
    {
        // Act
        var settings = UserSettings.CreateDefault(_utcNow);

        // Assert
        Assert.Equal(1, settings.Id);
        Assert.Equal("EUR", settings.BaseCurrency);
        Assert.Equal(_utcNow, settings.UpdatedAt);
    }

    [Fact]
    public void UpdateBaseCurrency_ShouldChangeToUsd()
    {
        // Arrange
        var settings = UserSettings.CreateDefault(_utcNow);
        var newUtcNow = _utcNow.AddHours(1);

        // Act
        settings.UpdateBaseCurrency("USD", newUtcNow);

        // Assert
        Assert.Equal("USD", settings.BaseCurrency);
        Assert.Equal(newUtcNow, settings.UpdatedAt);
    }

    [Fact]
    public void UpdateBaseCurrency_ShouldNormalizeToUpperCase()
    {
        // Arrange
        var settings = UserSettings.CreateDefault(_utcNow);

        // Act
        settings.UpdateBaseCurrency("gbp", _utcNow);

        // Assert
        Assert.Equal("GBP", settings.BaseCurrency);
    }

    [Fact]
    public void UpdateBaseCurrency_ShouldThrow_WhenUnsupportedCurrency()
    {
        // Arrange
        var settings = UserSettings.CreateDefault(_utcNow);

        // Act & Assert
        var ex = Assert.Throws<ArgumentException>(() =>
            settings.UpdateBaseCurrency("JPY", _utcNow));

        Assert.Contains("Unsupported currency", ex.Message);
        Assert.Contains("JPY", ex.Message);
    }

    [Theory]
    [InlineData("EUR")]
    [InlineData("USD")]
    [InlineData("GBP")]
    public void UpdateBaseCurrency_AllSupportedCurrencies_ShouldSucceed(string currency)
    {
        // Arrange
        var settings = UserSettings.CreateDefault(_utcNow);

        // Act
        settings.UpdateBaseCurrency(currency, _utcNow);

        // Assert
        Assert.Equal(currency, settings.BaseCurrency);
    }
}
