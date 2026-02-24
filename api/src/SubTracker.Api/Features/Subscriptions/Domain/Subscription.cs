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
    /// <summary>
    /// Last time a notification was sent for this subscription.
    /// Used to prevent duplicate notifications within the same billing cycle.
    /// </summary>
    public DateTime? LastNotifiedAt { get; private set; }
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

    public void Deactivate(DateTime utcNow)
    {
        IsActive = false;
        UpdatedAt = utcNow;
    }

    /// <summary>
    /// Returns true if the subscription is active and NextBillingDate is within
    /// the reminder window (today &lt;= NextBillingDate &lt;= today + ReminderDaysBefore).
    /// Excludes subscriptions with NextBillingDate in the past.
    /// </summary>
    public bool IsDueSoon(DateTime utcNow)
    {
        if (!IsActive) return false;

        var daysUntilBilling = (NextBillingDate.Date - utcNow.Date).TotalDays;
        return daysUntilBilling >= 0 && daysUntilBilling <= ReminderDaysBefore;
    }

    /// <summary>
    /// Determines if a notification should be sent for this subscription.
    /// Returns true if the subscription is due soon AND has not been notified
    /// in the current billing cycle.
    /// </summary>
    public bool NeedsNotification(DateTime utcNow)
    {
        if (!IsDueSoon(utcNow)) return false;

        if (LastNotifiedAt is null) return true;

        var cycleStart = GetCycleStartDate();
        return LastNotifiedAt.Value < cycleStart;
    }

    /// <summary>
    /// Marks this subscription as having been notified.
    /// </summary>
    public void MarkNotified(DateTime utcNow)
    {
        LastNotifiedAt = utcNow;
    }

    /// <summary>
    /// Returns true if NextBillingDate is in the past relative to utcNow.
    /// </summary>
    public bool HasPastBillingDate(DateTime utcNow) =>
        IsActive && NextBillingDate.Date < utcNow.Date;

    /// <summary>
    /// Advances NextBillingDate to the next valid future date based on the billing cycle.
    /// </summary>
    public void AdvanceNextBillingDate(DateTime utcNow)
    {
        NextBillingDate = CalculateNextBillingDate(NextBillingDate, BillingCycle, utcNow);
    }

    /// <summary>
    /// Calculates the start of the current billing cycle.
    /// If LastNotifiedAt is before this date, a new notification is needed.
    /// </summary>
    private DateTime GetCycleStartDate()
    {
        return BillingCycle switch
        {
            BillingCycle.Weekly => NextBillingDate.AddDays(-7),
            BillingCycle.Monthly => NextBillingDate.AddMonths(-1),
            BillingCycle.Quarterly => NextBillingDate.AddMonths(-3),
            BillingCycle.Yearly => NextBillingDate.AddYears(-1),
            _ => NextBillingDate.AddMonths(-1)
        };
    }

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
