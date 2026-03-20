using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common.Extensions;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Features.Subscriptions;

public sealed class DeleteEndpoint : Endpoint<DeleteEndpoint.Request>
{
    public sealed class Request
    {
        public Guid Id { get; init; }
    }

    private readonly AppDbContext _db;
    private readonly ILogger<DeleteEndpoint> _logger;

    public DeleteEndpoint(AppDbContext db, ILogger<DeleteEndpoint> logger)
    {
        _db = db;
        _logger = logger;
    }

    public override void Configure()
    {
        Delete("/api/subscriptions/{Id}");
        Roles(UserRole.Admin.ToString(), UserRole.User.ToString());
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var userId = User.GetUserId();

        var subscription = await _db.Subscriptions
            .FirstOrDefaultAsync(s => s.Id == req.Id && s.UserId == userId, ct);

        if (subscription is null)
        {
            await Send.NotFoundAsync(ct);

            return;
        }

        _db.Subscriptions.Remove(subscription);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation(
            "Subscription deleted: {SubscriptionId}",
            req.Id);

        await Send.NoContentAsync(ct);
    }
}