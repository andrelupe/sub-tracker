using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Features.Auth;

public sealed class ListInviteCodesEndpoint(AppDbContext db) : EndpointWithoutRequest<List<ListInviteCodesEndpoint.InviteCodeResponse>>
{
    public sealed class InviteCodeResponse
    {
        public string Code { get; init; } = string.Empty;
        public DateTime CreatedAt { get; init; }
        public string? UsedByEmail { get; init; }
        public DateTime? UsedAt { get; init; }
    }

    public override void Configure()
    {
        Get("/api/auth/invite-codes");
        Roles(nameof(UserRole.Admin));
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var codes = await db.InviteCodes
            .Include(c => c.UsedByUser)
            .OrderByDescending(c => c.CreatedAt)
            .Select(c => new InviteCodeResponse
            {
                Code = c.Code,
                CreatedAt = c.CreatedAt,
                UsedByEmail = c.UsedByUser != null ? c.UsedByUser.Email : null,
                UsedAt = c.UsedAt
            })
            .ToListAsync(ct);

        await Send.OkAsync(codes, ct);
    }
}