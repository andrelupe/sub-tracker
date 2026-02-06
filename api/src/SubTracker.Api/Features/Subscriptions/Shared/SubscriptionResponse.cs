using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Features.Subscriptions.Shared;

public sealed class SubscriptionResponse
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string? Description { get; init; }
    public decimal Amount { get; init; }
    public string Currency { get; init; } = string.Empty;
    public BillingCycle BillingCycle { get; init; }
    public SubscriptionCategory Category { get; init; }
    public DateTime StartDate { get; init; }
    public DateTime NextBillingDate { get; init; }
    public bool IsActive { get; init; }
    public string? Url { get; init; }
    public int ReminderDaysBefore { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
}
