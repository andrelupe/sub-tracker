using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Features.Auth;

public sealed class ListPendingResetsEndpoint(AppDbContext db, IDateTimeProvider dateTime) : EndpointWithoutRequest<List<ListPendingResetsEndpoint.PendingResetResponse>>
{
    public sealed class PendingResetResponse
    {
        public string Email { get; init; } = string.Empty;
        public DateTime ExpiresAt { get; init; }
    }

    public override void Configure()
    {
        Get("/api/auth/pending-resets");
        Roles(nameof(UserRole.Admin));
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var utcNow = dateTime.UtcNow;

        var pendingResets = await db.Users
            .Where(u => u.ResetToken != null && u.ResetTokenExpiresAt > utcNow)
            .OrderByDescending(u => u.ResetTokenExpiresAt)
            .Select(u => new PendingResetResponse
            {
                Email = u.Email,
                ExpiresAt = u.ResetTokenExpiresAt!.Value
            })
            .ToListAsync(ct);

        await Send.OkAsync(pendingResets, ct);
    }
}