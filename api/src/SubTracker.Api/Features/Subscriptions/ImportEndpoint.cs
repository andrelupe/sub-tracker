using FastEndpoints;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Features.Subscriptions;

public sealed class ImportEndpoint : Endpoint<ImportEndpoint.Request, ImportEndpoint.Response>
{
    public sealed class Request
    {
        public List<SubscriptionImportDto> Subscriptions { get; init; } = [];
    }

    public sealed class SubscriptionImportDto
    {
        public string Name { get; init; } = string.Empty;
        public string? Description { get; init; }
        public decimal Amount { get; init; }
        public string Currency { get; init; } = "EUR";
        public string BillingCycle { get; init; } = "Monthly";
        public string Category { get; init; } = "Other";
        public DateTime StartDate { get; init; }
        public string? Url { get; init; }
        public int ReminderDaysBefore { get; init; } = 2;
        public bool IsActive { get; init; } = true;
    }

    public new sealed class Response
    {
        public int Imported { get; init; }
        public List<ImportError> Errors { get; init; } = [];
    }

    public sealed class ImportError
    {
        public int Index { get; init; }
        public string Message { get; init; } = string.Empty;
    }

    private static readonly HashSet<string> ValidCurrencies = ["EUR", "USD", "GBP"];

    private readonly AppDbContext _db;
    private readonly IDateTimeProvider _dateTime;

    public ImportEndpoint(AppDbContext db, IDateTimeProvider dateTime)
    {
        _db = db;
        _dateTime = dateTime;
    }

    public override void Configure()
    {
        Post("/api/subscriptions/import");
        AllowAnonymous();
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var errors = new List<ImportError>();
        var subscriptionsToCreate = new List<Subscription>();

        // 1. Validate all items first
        for (var i = 0; i < req.Subscriptions.Count; i++)
        {
            var dto = req.Subscriptions[i];

            var validationError = Validate(dto);
            if (validationError is not null)
            {
                errors.Add(new ImportError { Index = i, Message = validationError });
                continue;
            }

            // Create entity (but don't add to DbContext yet)
            var subscription = Subscription.Create(
                dto.Name,
                dto.Description,
                dto.Amount,
                dto.Currency,
                Enum.Parse<Domain.BillingCycle>(dto.BillingCycle),
                Enum.Parse<SubscriptionCategory>(dto.Category),
                dto.StartDate,
                dto.Url,
                dto.ReminderDaysBefore,
                _dateTime.UtcNow
            );

            if (!dto.IsActive)
                subscription.Deactivate(_dateTime.UtcNow);

            subscriptionsToCreate.Add(subscription);
        }

        // 2. If there are errors, fail all (atomic operation)
        if (errors.Count > 0)
        {
            await Send.OkAsync(new Response
            {
                Imported = 0,
                Errors = errors
            }, ct);
            return;
        }

        // 3. If all valid, insert all
        _db.Subscriptions.AddRange(subscriptionsToCreate);
        await _db.SaveChangesAsync(ct);

        await Send.OkAsync(new Response
        {
            Imported = subscriptionsToCreate.Count,
            Errors = []
        }, ct);
    }

    private string? Validate(SubscriptionImportDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
            return "Name is required";

        if (dto.Name.Length > 100)
            return "Name must not exceed 100 characters";

        if (dto.Amount <= 0)
            return "Amount must be greater than 0";

        if (!ValidCurrencies.Contains(dto.Currency))
            return $"Invalid currency: {dto.Currency}. Must be one of: EUR, USD, GBP";

        if (!Enum.TryParse<Domain.BillingCycle>(dto.BillingCycle, out _))
            return $"Invalid billing cycle: {dto.BillingCycle}. Must be one of: Weekly, Monthly, Quarterly, Yearly";

        if (!Enum.TryParse<SubscriptionCategory>(dto.Category, out _))
            return $"Invalid category: {dto.Category}. Must be one of: {string.Join(", ", Enum.GetNames<SubscriptionCategory>())}";

        if (dto.StartDate == default)
            return "Start date is required";

        if (dto.StartDate > _dateTime.UtcNow.AddYears(1))
            return "Start date cannot be more than 1 year in the future";

        if (dto.ReminderDaysBefore < 0 || dto.ReminderDaysBefore > 30)
            return "Reminder days before must be between 0 and 30";

        return null;
    }
}
