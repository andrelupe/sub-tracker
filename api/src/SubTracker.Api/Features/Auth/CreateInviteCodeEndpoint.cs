using System.Security.Cryptography;
using FastEndpoints;
using SubTracker.Api.Common;
using SubTracker.Api.Common.Extensions;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Features.Auth;

public sealed class CreateInviteCodeEndpoint(AppDbContext db, IDateTimeProvider dateTime, ILogger<CreateInviteCodeEndpoint> logger)
    : EndpointWithoutRequest<CreateInviteCodeEndpoint.Response>
{
    public new sealed class Response
    {
        public string Code { get; init; } = string.Empty;
        public DateTime CreatedAt { get; init; }
    }

    // Unambiguous characters: exclude 0/O/I/1/L
    private const string AllowedChars = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

    public override void Configure()
    {
        Post("/api/auth/invite-codes");
        Roles(UserRole.Admin.ToString());
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var utcNow = dateTime.UtcNow;
        var userId = User.GetUserId();

        var code = GenerateCode(8);

        var inviteCode = InviteCode.Create(userId, code, utcNow);
        db.InviteCodes.Add(inviteCode);
        await db.SaveChangesAsync(ct);

        logger.LogInformation("Invite code created by {UserId}: {Code}", userId, code);

        await HttpContext.Response.SendAsync(new Response
        {
            Code = code,
            CreatedAt = utcNow
        }, 201, cancellation: ct);
    }

    private static string GenerateCode(int length)
    {
        return string.Create<object?>(length, null, (span, _) =>
        {
            Span<byte> randomBytes = stackalloc byte[length];
            RandomNumberGenerator.Fill(randomBytes);

            for (var i = 0; i < length; i++)
            {
                span[i] = AllowedChars[randomBytes[i] % AllowedChars.Length];
            }
        });
    }
}