using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Tests.Features.Subscriptions;

public class SubscriptionTests
{
    private readonly DateTime _utcNow = new(2026, 2, 6, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Create_ShouldSetAllProperties()
    {
        // Arrange & Act
        var subscription = Subscription.Create(
            name: "Netflix",
            description: "Streaming service",
            amount: 15.99m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Entertainment,
            startDate: new DateTime(2026, 1, 1),
            url: "https://netflix.com",
            reminderDaysBefore: 3,
            utcNow: _utcNow
        );

        // Assert
        Assert.NotEqual(Guid.Empty, subscription.Id);
        Assert.Equal("Netflix", subscription.Name);
        Assert.Equal("Streaming service", subscription.Description);
        Assert.Equal(15.99m, subscription.Amount);
        Assert.Equal("EUR", subscription.Currency);
        Assert.Equal(BillingCycle.Monthly, subscription.BillingCycle);
        Assert.Equal(SubscriptionCategory.Entertainment, subscription.Category);
        Assert.True(subscription.IsActive);
        Assert.Equal("https://netflix.com", subscription.Url);
        Assert.Equal(3, subscription.ReminderDaysBefore);
    }

    [Fact]
    public void Create_ShouldCalculateNextBillingDate_Monthly()
    {
        // Arrange
        var startDate = new DateTime(2026, 1, 15);

        // Act
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 10m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Other,
            startDate: startDate,
            url: null,
            reminderDaysBefore: 2,
            utcNow: _utcNow
        );

        // Assert - next billing should be Feb 15, 2026
        Assert.Equal(new DateTime(2026, 2, 15), subscription.NextBillingDate);
    }

    [Fact]
    public void Create_ShouldCalculateNextBillingDate_Weekly()
    {
        // Arrange
        var startDate = new DateTime(2026, 2, 1);

        // Act
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 5m,
            currency: "EUR",
            billingCycle: BillingCycle.Weekly,
            category: SubscriptionCategory.Other,
            startDate: startDate,
            url: null,
            reminderDaysBefore: 1,
            utcNow: _utcNow
        );

        // Assert - Feb 1 + 7 = Feb 8
        Assert.Equal(new DateTime(2026, 2, 8), subscription.NextBillingDate);
    }

    [Fact]
    public void Create_ShouldCalculateNextBillingDate_Yearly()
    {
        // Arrange
        var startDate = new DateTime(2025, 3, 1);

        // Act
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 99m,
            currency: "EUR",
            billingCycle: BillingCycle.Yearly,
            category: SubscriptionCategory.Other,
            startDate: startDate,
            url: null,
            reminderDaysBefore: 7,
            utcNow: _utcNow
        );

        // Assert - next billing should be March 1, 2026
        Assert.Equal(new DateTime(2026, 3, 1), subscription.NextBillingDate);
    }

    [Fact]
    public void Update_ShouldModifyProperties()
    {
        // Arrange
        var subscription = Subscription.Create(
            name: "Old Name",
            description: null,
            amount: 10m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2026, 1, 1),
            url: null,
            reminderDaysBefore: 2,
            utcNow: _utcNow
        );

        // Act
        subscription.Update(
            name: "New Name",
            description: "New description",
            amount: 20m,
            currency: "USD",
            billingCycle: BillingCycle.Yearly,
            category: SubscriptionCategory.Music,
            startDate: new DateTime(2026, 2, 1),
            url: "https://example.com",
            reminderDaysBefore: 5,
            isActive: false,
            utcNow: _utcNow
        );

        // Assert
        Assert.Equal("New Name", subscription.Name);
        Assert.Equal("New description", subscription.Description);
        Assert.Equal(20m, subscription.Amount);
        Assert.Equal("USD", subscription.Currency);
        Assert.Equal(BillingCycle.Yearly, subscription.BillingCycle);
        Assert.Equal(SubscriptionCategory.Music, subscription.Category);
        Assert.Equal("https://example.com", subscription.Url);
        Assert.Equal(5, subscription.ReminderDaysBefore);
        Assert.False(subscription.IsActive);
    }

    [Fact]
    public void IsDueSoon_ShouldReturnTrue_WhenWithinReminderDays()
    {
        // Arrange - subscription due in 2 days, reminder is 3 days
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 10m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2026, 1, 8), // Next billing Feb 8
            url: null,
            reminderDaysBefore: 3,
            utcNow: _utcNow // Feb 6
        );

        // Act & Assert - Feb 8 - Feb 6 = 2 days, which is <= 3
        Assert.True(subscription.IsDueSoon(_utcNow));
    }

    [Fact]
    public void IsDueSoon_ShouldReturnFalse_WhenOutsideReminderDays()
    {
        // Arrange - subscription due in 10 days, reminder is 3 days
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 10m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2026, 1, 16), // Next billing Feb 16
            url: null,
            reminderDaysBefore: 3,
            utcNow: _utcNow // Feb 6
        );

        // Act & Assert - Feb 16 - Feb 6 = 10 days, which is > 3
        Assert.False(subscription.IsDueSoon(_utcNow));
    }

    [Fact]
    public void IsDueSoon_ShouldReturnFalse_WhenInactive()
    {
        // Arrange
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 10m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2026, 1, 8), // Next billing Feb 8
            url: null,
            reminderDaysBefore: 3,
            utcNow: _utcNow
        );

        // Deactivate
        subscription.Update(
            subscription.Name,
            subscription.Description,
            subscription.Amount,
            subscription.Currency,
            subscription.BillingCycle,
            subscription.Category,
            subscription.StartDate,
            subscription.Url,
            subscription.ReminderDaysBefore,
            isActive: false,
            utcNow: _utcNow
        );

        // Act & Assert
        Assert.False(subscription.IsDueSoon(_utcNow));
    }
}
