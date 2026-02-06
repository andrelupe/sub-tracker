namespace SubTracker.Api.Features.Subscriptions.Domain;

public sealed class Subscription
{
    public Guid Id { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string? Description { get; private set; }
    public decimal Amount { get; private set; }
    public string Currency { get; private set; } = "EUR";
    public BillingCycle BillingCycle { get; private set; }
    public SubscriptionCategory Category { get; private set; }
    public DateTime StartDate { get; private set; }
    public DateTime NextBillingDate { get; private set; }
    public bool IsActive { get; private set; } = true;
    public string? Url { get; private set; }
    public int ReminderDaysBefore { get; private set; } = 2;
    public DateTime CreatedAt { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    private Subscription() { }

    public static Subscription Create(
        string name,
        string? description,
        decimal amount,
        string currency,
        BillingCycle billingCycle,
        SubscriptionCategory category,
        DateTime startDate,
        string? url,
        int reminderDaysBefore,
        DateTime utcNow)
    {
        return new Subscription
        {
            Id = Guid.NewGuid(),
            Name = name,
            Description = description,
            Amount = amount,
            Currency = currency,
            BillingCycle = billingCycle,
            Category = category,
            StartDate = startDate,
            NextBillingDate = CalculateNextBillingDate(startDate, billingCycle, utcNow),
            Url = url,
            ReminderDaysBefore = reminderDaysBefore,
            CreatedAt = utcNow,
            UpdatedAt = utcNow
        };
    }

    public void Update(
        string name,
        string? description,
        decimal amount,
        string currency,
        BillingCycle billingCycle,
        SubscriptionCategory category,
        DateTime startDate,
        string? url,
        int reminderDaysBefore,
        bool isActive,
        DateTime utcNow)
    {
        Name = name;
        Description = description;
        Amount = amount;
        Currency = currency;
        BillingCycle = billingCycle;
        Category = category;
        StartDate = startDate;
        NextBillingDate = CalculateNextBillingDate(startDate, billingCycle, utcNow);
        Url = url;
        ReminderDaysBefore = reminderDaysBefore;
        IsActive = isActive;
        UpdatedAt = utcNow;
    }

    public bool IsDueSoon(DateTime utcNow) =>
        IsActive && (NextBillingDate - utcNow).TotalDays <= ReminderDaysBefore;

    private static DateTime CalculateNextBillingDate(
        DateTime startDate,
        BillingCycle cycle,
        DateTime utcNow)
    {
        var next = startDate;
        while (next <= utcNow)
        {
            next = cycle switch
            {
                BillingCycle.Weekly => next.AddDays(7),
                BillingCycle.Monthly => next.AddMonths(1),
                BillingCycle.Quarterly => next.AddMonths(3),
                BillingCycle.Yearly => next.AddYears(1),
                _ => next.AddMonths(1)
            };
        }
        return next;
    }
}
