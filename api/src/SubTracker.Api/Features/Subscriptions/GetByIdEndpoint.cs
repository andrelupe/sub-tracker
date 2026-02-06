using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Subscriptions.Shared;

namespace SubTracker.Api.Features.Subscriptions;

public sealed class GetByIdEndpoint : Endpoint<GetByIdEndpoint.Request, SubscriptionResponse>
{
    public sealed class Request
    {
        public Guid Id { get; init; }
    }

    private readonly AppDbContext _db;

    public GetByIdEndpoint(AppDbContext db) => _db = db;

    public override void Configure()
    {
        Get("/api/subscriptions/{Id}");
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

        await Send.OkAsync(subscription.ToResponse(), ct);
    }
}
