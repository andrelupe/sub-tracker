using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Features.Subscriptions.Shared;

public static class SubscriptionMapper
{
    public static SubscriptionResponse ToResponse(this Subscription s) => new()
    {
        Id = s.Id,
        Name = s.Name,
        Description = s.Description,
        Amount = s.Amount,
        Currency = s.Currency,
        BillingCycle = s.BillingCycle,
        Category = s.Category,
        StartDate = s.StartDate,
        NextBillingDate = s.NextBillingDate,
        IsActive = s.IsActive,
        Url = s.Url,
        ReminderDaysBefore = s.ReminderDaysBefore,
        CreatedAt = s.CreatedAt,
        UpdatedAt = s.UpdatedAt
    };
}
