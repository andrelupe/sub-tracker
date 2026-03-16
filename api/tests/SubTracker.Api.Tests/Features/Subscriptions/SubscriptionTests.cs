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
            userId: Guid.NewGuid(),
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
            userId: Guid.NewGuid(),
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
            userId: Guid.NewGuid(),
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
            userId: Guid.NewGuid(),
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
            userId: Guid.NewGuid(),
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
            userId: Guid.NewGuid(),
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
            userId: Guid.NewGuid(),
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
            userId: Guid.NewGuid(),
            utcNow: _utcNow
        );

        // Deactivate
        subscription.Deactivate(_utcNow);

        // Act & Assert
        Assert.False(subscription.IsDueSoon(_utcNow));
    }

    [Fact]
    public void IsDueSoon_ShouldReturnFalse_WhenNextBillingDateIsInPast()
    {
        // Arrange - subscription with NextBillingDate in the past
        // Start date Jan 1 2025, monthly -> next billing would be Feb 1 2025
        // but utcNow is Feb 6 2026, so CalculateNextBillingDate advances it
        // We need to simulate a past date scenario.
        // Create with a start date that produces a future NextBillingDate,
        // then advance time past it.
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
            userId: Guid.NewGuid(),
            utcNow: _utcNow // Feb 6
        );

        // Act & Assert - on Feb 10, NextBillingDate (Feb 8) is in the past
        var futureNow = new DateTime(2026, 2, 10, 12, 0, 0, DateTimeKind.Utc);
        Assert.False(subscription.IsDueSoon(futureNow));
    }

    [Fact]
    public void IsDueSoon_ShouldReturnTrue_WhenNextBillingDateIsToday()
    {
        // Arrange - subscription due today
        // startDate Jan 8, monthly, utcNow Feb 6 12:00 -> NextBillingDate = Feb 8
        // We check IsDueSoon at Feb 8 00:00 -> Feb 8 - Feb 8 = 0 days, which is <= 2
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 10m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2026, 1, 8), // Next billing Feb 8
            url: null,
            reminderDaysBefore: 2,
            userId: Guid.NewGuid(),
            utcNow: _utcNow // Feb 6
        );

        // Act & Assert - check on Feb 8 (the billing date itself)
        var feb8 = new DateTime(2026, 2, 8, 10, 0, 0, DateTimeKind.Utc);
        Assert.True(subscription.IsDueSoon(feb8));
    }

    [Fact]
    public void NeedsNotification_ShouldReturnTrue_WhenDueSoonAndNeverNotified()
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
            userId: Guid.NewGuid(),
            utcNow: _utcNow // Feb 6
        );

        // Act & Assert - due soon, never notified
        Assert.True(subscription.NeedsNotification(_utcNow));
    }

    [Fact]
    public void NeedsNotification_ShouldReturnFalse_WhenAlreadyNotifiedThisCycle()
    {
        // Arrange - Monthly subscription, NextBillingDate = Feb 8
        // Cycle start = Feb 8 - 1 month = Jan 8
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
            userId: Guid.NewGuid(),
            utcNow: _utcNow // Feb 6
        );

        // Mark as notified on Feb 5 (which is after cycle start Jan 8)
        subscription.MarkNotified(new DateTime(2026, 2, 5, 10, 0, 0, DateTimeKind.Utc));

        // Act & Assert - already notified this cycle
        Assert.False(subscription.NeedsNotification(_utcNow));
    }

    [Fact]
    public void NeedsNotification_ShouldReturnTrue_WhenNotifiedInPreviousCycle()
    {
        // Arrange - Monthly subscription, NextBillingDate = Feb 8
        // Cycle start = Feb 8 - 1 month = Jan 8
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
            userId: Guid.NewGuid(),
            utcNow: _utcNow // Feb 6
        );

        // Mark as notified on Jan 7 (which is before cycle start Jan 8)
        subscription.MarkNotified(new DateTime(2026, 1, 7, 10, 0, 0, DateTimeKind.Utc));

        // Act & Assert - notified in previous cycle, needs new notification
        Assert.True(subscription.NeedsNotification(_utcNow));
    }

    [Fact]
    public void NeedsNotification_ShouldReturnFalse_WhenNotDueSoon()
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
            userId: Guid.NewGuid(),
            utcNow: _utcNow // Feb 6
        );

        // Act & Assert - not due soon, regardless of notification status
        Assert.False(subscription.NeedsNotification(_utcNow));
    }

    [Fact]
    public void MarkNotified_ShouldSetLastNotifiedAt()
    {
        // Arrange
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 10m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2026, 1, 8),
            url: null,
            reminderDaysBefore: 3,
            userId: Guid.NewGuid(),
            utcNow: _utcNow
        );

        Assert.Null(subscription.LastNotifiedAt);

        // Act
        subscription.MarkNotified(_utcNow);

        // Assert
        Assert.Equal(_utcNow, subscription.LastNotifiedAt);
    }

    [Fact]
    public void HasPastBillingDate_ShouldReturnTrue_WhenNextBillingDateIsBeforeToday()
    {
        // Arrange - create subscription with next billing Feb 8
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
            userId: Guid.NewGuid(),
            utcNow: _utcNow
        );

        // Act & Assert - on Feb 10, Feb 8 is in the past
        var futureNow = new DateTime(2026, 2, 10, 12, 0, 0, DateTimeKind.Utc);
        Assert.True(subscription.HasPastBillingDate(futureNow));
    }

    [Fact]
    public void HasPastBillingDate_ShouldReturnFalse_WhenNextBillingDateIsInFuture()
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
            userId: Guid.NewGuid(),
            utcNow: _utcNow // Feb 6
        );

        // Act & Assert - Feb 8 is still in the future relative to Feb 6
        Assert.False(subscription.HasPastBillingDate(_utcNow));
    }

    [Fact]
    public void HasPastBillingDate_ShouldReturnFalse_WhenInactive()
    {
        // Arrange
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 10m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2026, 1, 8),
            url: null,
            reminderDaysBefore: 3,
            userId: Guid.NewGuid(),
            utcNow: _utcNow
        );
        subscription.Deactivate(_utcNow);

        // Act & Assert - inactive subscriptions should not be flagged
        var futureNow = new DateTime(2026, 2, 10, 12, 0, 0, DateTimeKind.Utc);
        Assert.False(subscription.HasPastBillingDate(futureNow));
    }

    [Fact]
    public void AdvanceNextBillingDate_Monthly_ShouldAdvanceToFutureDate()
    {
        // Arrange - next billing was Feb 8, now it's Feb 10
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
            userId: Guid.NewGuid(),
            utcNow: _utcNow
        );

        Assert.Equal(new DateTime(2026, 2, 8), subscription.NextBillingDate);

        // Act - advance from Feb 10 perspective
        var futureNow = new DateTime(2026, 2, 10, 12, 0, 0, DateTimeKind.Utc);
        subscription.AdvanceNextBillingDate(futureNow);

        // Assert - should advance to Mar 8
        Assert.Equal(new DateTime(2026, 3, 8), subscription.NextBillingDate);
    }

    [Fact]
    public void AdvanceNextBillingDate_Weekly_ShouldAdvanceToFutureDate()
    {
        // Arrange
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 5m,
            currency: "EUR",
            billingCycle: BillingCycle.Weekly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2026, 2, 1), // Next billing Feb 8
            url: null,
            reminderDaysBefore: 1,
            userId: Guid.NewGuid(),
            utcNow: _utcNow
        );

        Assert.Equal(new DateTime(2026, 2, 8), subscription.NextBillingDate);

        // Act - advance from Feb 20 perspective (missed multiple weeks)
        var futureNow = new DateTime(2026, 2, 20, 12, 0, 0, DateTimeKind.Utc);
        subscription.AdvanceNextBillingDate(futureNow);

        // Assert - should skip Feb 15, and land on Feb 22
        Assert.Equal(new DateTime(2026, 2, 22), subscription.NextBillingDate);
    }

    [Fact]
    public void AdvanceNextBillingDate_Yearly_ShouldAdvanceToFutureDate()
    {
        // Arrange
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 99m,
            currency: "EUR",
            billingCycle: BillingCycle.Yearly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2025, 3, 1), // Next billing Mar 1 2026
            url: null,
            reminderDaysBefore: 7,
            userId: Guid.NewGuid(),
            utcNow: _utcNow
        );

        Assert.Equal(new DateTime(2026, 3, 1), subscription.NextBillingDate);

        // Act - advance from Apr 2026 perspective
        var futureNow = new DateTime(2026, 4, 1, 12, 0, 0, DateTimeKind.Utc);
        subscription.AdvanceNextBillingDate(futureNow);

        // Assert - should advance to Mar 1 2027
        Assert.Equal(new DateTime(2027, 3, 1), subscription.NextBillingDate);
    }

    [Fact]
    public void Create_ShouldCalculateNextBillingDate_Biannual()
    {
        // Arrange - start date Aug 1 2025, biannual (6 months)
        var startDate = new DateTime(2025, 8, 1);

        // Act
        var subscription = Subscription.Create(
            name: "Car Insurance",
            description: "Biannual vehicle insurance",
            amount: 450m,
            currency: "EUR",
            billingCycle: BillingCycle.Biannual,
            category: SubscriptionCategory.Utilities,
            startDate: startDate,
            url: null,
            reminderDaysBefore: 14,
            userId: Guid.NewGuid(),
            utcNow: _utcNow // Feb 6 2026
        );

        // Assert - Aug 1 2025 + 6 months = Feb 1 2026, which is <= Feb 6,
        // so advance again: Feb 1 + 6 = Aug 1 2026
        Assert.Equal(new DateTime(2026, 8, 1), subscription.NextBillingDate);
    }

    [Fact]
    public void IsDueSoon_Biannual_ShouldReturnTrue_WhenWithinReminderDays()
    {
        // Arrange - start date Aug 6 2025, biannual → NextBillingDate = Feb 6 2026 + 6m = Aug 6 2026
        // Actually: Aug 6 2025 + 6m = Feb 6 2026, which is <= Feb 6 utcNow,
        // so advance: Feb 6 + 6m = Aug 6 2026. That's too far.
        // Instead, use a start date that lands NextBillingDate within reminder window.
        // Start: Aug 8 2025 → +6m = Feb 8 2026 (> Feb 6) → NextBillingDate = Feb 8
        var subscription = Subscription.Create(
            name: "Car Insurance",
            description: null,
            amount: 450m,
            currency: "EUR",
            billingCycle: BillingCycle.Biannual,
            category: SubscriptionCategory.Utilities,
            startDate: new DateTime(2025, 8, 8), // Next billing Feb 8 2026
            url: null,
            reminderDaysBefore: 3,
            userId: Guid.NewGuid(),
            utcNow: _utcNow // Feb 6
        );

        // Act & Assert - Feb 8 - Feb 6 = 2 days, which is <= 3
        Assert.Equal(new DateTime(2026, 2, 8), subscription.NextBillingDate);
        Assert.True(subscription.IsDueSoon(_utcNow));
    }

    [Fact]
    public void AdvanceNextBillingDate_Biannual_ShouldAdvanceToFutureDate()
    {
        // Arrange - biannual, NextBillingDate = Feb 8 2026
        var subscription = Subscription.Create(
            name: "Car Insurance",
            description: null,
            amount: 450m,
            currency: "EUR",
            billingCycle: BillingCycle.Biannual,
            category: SubscriptionCategory.Utilities,
            startDate: new DateTime(2025, 8, 8), // Next billing Feb 8 2026
            url: null,
            reminderDaysBefore: 14,
            userId: Guid.NewGuid(),
            utcNow: _utcNow
        );

        Assert.Equal(new DateTime(2026, 2, 8), subscription.NextBillingDate);

        // Act - advance from Mar 1 2026 perspective (Feb 8 is in the past)
        var futureNow = new DateTime(2026, 3, 1, 12, 0, 0, DateTimeKind.Utc);
        subscription.AdvanceNextBillingDate(futureNow);

        // Assert - should advance to Aug 8 2026 (Feb 8 + 6 months)
        Assert.Equal(new DateTime(2026, 8, 8), subscription.NextBillingDate);
    }

    [Fact]
    public void NeedsNotification_Yearly_ShouldReturnTrue_WhenNotifiedInPreviousYearlyCycle()
    {
        // Arrange - Yearly subscription, NextBillingDate = Mar 1 2026
        // Cycle start = Mar 1 2025
        var subscription = Subscription.Create(
            name: "Test",
            description: null,
            amount: 99m,
            currency: "EUR",
            billingCycle: BillingCycle.Yearly,
            category: SubscriptionCategory.Other,
            startDate: new DateTime(2025, 3, 1), // Next billing Mar 1 2026
            url: null,
            reminderDaysBefore: 7,
            userId: Guid.NewGuid(),
            utcNow: _utcNow
        );

        // Mark as notified in previous yearly cycle (Feb 2025 < Mar 1 2025 cycle start)
        subscription.MarkNotified(new DateTime(2025, 2, 28, 10, 0, 0, DateTimeKind.Utc));

        // Act & Assert - Feb 27 is within 7 days of Mar 1
        var feb27 = new DateTime(2026, 2, 27, 12, 0, 0, DateTimeKind.Utc);
        Assert.True(subscription.NeedsNotification(feb27));
    }
}
