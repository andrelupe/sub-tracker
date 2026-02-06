using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Features.Subscriptions;

public sealed class UpdateEndpoint : Endpoint<UpdateEndpoint.Request>
{
    public sealed class Request
    {
        public Guid Id { get; init; }
        public string Name { get; init; } = string.Empty;
        public string? Description { get; init; }
        public decimal Amount { get; init; }
        public string Currency { get; init; } = "EUR";
        public BillingCycle BillingCycle { get; init; }
        public SubscriptionCategory Category { get; init; }
        public DateTime StartDate { get; init; }
        public string? Url { get; init; }
        public int ReminderDaysBefore { get; init; } = 2;
        public bool IsActive { get; init; } = true;
    }

    public sealed class Validator : Validator<Request>
    {
        public Validator()
        {
            RuleFor(x => x.Id).NotEmpty();

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

    public UpdateEndpoint(AppDbContext db, IDateTimeProvider dateTime)
    {
        _db = db;
        _dateTime = dateTime;
    }

    public override void Configure()
    {
        Put("/api/subscriptions/{Id}");
        AllowAnonymous();
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var subscription = await _db.Subscriptions
            .FirstOrDefaultAsync(s => s.Id == req.Id, ct);

        if (subscription is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        subscription.Update(
            req.Name,
            req.Description,
            req.Amount,
            req.Currency,
            req.BillingCycle,
            req.Category,
            req.StartDate,
            req.Url,
            req.ReminderDaysBefore,
            req.IsActive,
            _dateTime.UtcNow
        );

        await _db.SaveChangesAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
