using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Database;

namespace SubTracker.Api.Features.Subscriptions;

public sealed class DeleteEndpoint : Endpoint<DeleteEndpoint.Request>
{
    public sealed class Request
    {
        public Guid Id { get; init; }
    }

    private readonly AppDbContext _db;

    public DeleteEndpoint(AppDbContext db) => _db = db;

    public override void Configure()
    {
        Delete("/api/subscriptions/{Id}");
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

        _db.Subscriptions.Remove(subscription);
        await _db.SaveChangesAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
