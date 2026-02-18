using FastEndpoints;
using FluentValidation;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Features.Subscriptions;

public sealed class CreateEndpoint : Endpoint<CreateEndpoint.Request, CreateEndpoint.Response>
{
    public sealed class Request
    {
        public string Name { get; init; } = string.Empty;
        public string? Description { get; init; }
        public decimal Amount { get; init; }
        public string Currency { get; init; } = "EUR";
        public BillingCycle BillingCycle { get; init; }
        public SubscriptionCategory Category { get; init; }
        public DateTime StartDate { get; init; }
        public string? Url { get; init; }
        public int ReminderDaysBefore { get; init; } = 2;
    }

    public new sealed class Response
    {
        public Guid Id { get; init; }
    }

    public sealed class Validator : Validator<Request>
    {
        public Validator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required")
                .MaximumLength(100);

            RuleFor(x => x.Amount)
                .GreaterThan(0).WithMessage("Amount must be greater than 0");

            RuleFor(x => x.Currency)
                .NotEmpty()
                .Length(3).WithMessage("Currency must be 3 characters");

            RuleFor(x => x.StartDate)
                .NotEmpty().WithMessage("Start date is required");

            RuleFor(x => x.ReminderDaysBefore)
                .InclusiveBetween(0, 30);
        }
    }

    private readonly AppDbContext _db;
    private readonly IDateTimeProvider _dateTime;
    private readonly ILogger<CreateEndpoint> _logger;

    public CreateEndpoint(AppDbContext db, IDateTimeProvider dateTime, ILogger<CreateEndpoint> logger)
    {
        _db = db;
        _dateTime = dateTime;
        _logger = logger;
    }

    public override void Configure()
    {
        Post("/api/subscriptions");
        AllowAnonymous();
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var subscription = Subscription.Create(
            req.Name,
            req.Description,
            req.Amount,
            req.Currency,
            req.BillingCycle,
            req.Category,
            req.StartDate,
            req.Url,
            req.ReminderDaysBefore,
            _dateTime.UtcNow
        );

        _db.Subscriptions.Add(subscription);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation(
            "Subscription created: {SubscriptionId} ({SubscriptionName})",
            subscription.Id,
            subscription.Name);

        await Send.CreatedAtAsync<GetByIdEndpoint>(
            new { id = subscription.Id },
            new Response { Id = subscription.Id },
            cancellation: ct
        );
    }
}
