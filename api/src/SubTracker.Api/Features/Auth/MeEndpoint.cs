using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common.Extensions;
using SubTracker.Api.Database;

namespace SubTracker.Api.Features.Auth;

public sealed class MeEndpoint : EndpointWithoutRequest<MeEndpoint.Response>
{
    public new sealed class Response
    {
        public Guid Id { get; init; }
        public string Email { get; init; } = string.Empty;
        public string Role { get; init; } = string.Empty;
        public DateTime CreatedAt { get; init; }
    }

    private readonly AppDbContext _db;

    public MeEndpoint(AppDbContext db)
    {
        _db = db;
    }

    public override void Configure()
    {
        Get("/api/auth/me");
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var userId = User.GetUserId();

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.OkAsync(new Response
        {
            Id = user.Id,
            Email = user.Email,
            Role = user.Role.ToString(),
            CreatedAt = user.CreatedAt
        }, ct);
    }
}
