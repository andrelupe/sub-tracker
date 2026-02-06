using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Subscriptions.Shared;

namespace SubTracker.Api.Features.Subscriptions;

public sealed class GetAllEndpoint : EndpointWithoutRequest<List<SubscriptionResponse>>
{
    private readonly AppDbContext _db;

    public GetAllEndpoint(AppDbContext db) => _db = db;

    public override void Configure()
    {
        Get("/api/subscriptions");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var subscriptions = await _db.Subscriptions
            .OrderBy(s => s.NextBillingDate)
            .Select(s => s.ToResponse())
            .ToListAsync(ct);

        await Send.OkAsync(subscriptions, ct);
    }
}
