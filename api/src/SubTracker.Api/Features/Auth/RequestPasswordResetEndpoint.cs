using System.Security.Cryptography;
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;
using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Features.Auth;

public sealed class RequestPasswordResetEndpoint(AppDbContext db, ITokenService tokens, IDateTimeProvider dateTime, ILogger<RequestPasswordResetEndpoint> logger)
    : Endpoint<RequestPasswordResetEndpoint.Request, RequestPasswordResetEndpoint.Response>
{
    public sealed class Request
    {
        public string Email { get; init; } = string.Empty;
    }

    public new sealed class Response
    {
        public string Email { get; init; } = string.Empty;
        public string Token { get; init; } = string.Empty;
        public DateTime ExpiresAt { get; init; }
    }

    public sealed class Validator : Validator<Request>
    {
        public Validator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Invalid email format");
        }
    }

    public override void Configure()
    {
        Post("/api/auth/request-password-reset");
        Roles(UserRole.Admin.ToString());
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var utcNow = dateTime.UtcNow;
        var normalizedEmail = req.Email.ToLowerInvariant().Trim();

        var user = await db.Users.FirstOrDefaultAsync(u => u.Email == normalizedEmail, ct);

        if (user is null)
        {
            await Send.NotFoundAsync(ct);

            return;
        }

        // Generate random 32-char token
        var rawToken = GenerateResetToken(32);
        var tokenHash = tokens.HashToken(rawToken);
        var expiresAt = utcNow.AddHours(1);

        user.SetResetToken(tokenHash, expiresAt, utcNow);
        await db.SaveChangesAsync(ct);

        logger.LogInformation("Password reset token for {Email}: {Token}. Expires at {ExpiresAt}", normalizedEmail, rawToken, expiresAt);

        await Send.OkAsync(new Response
        {
            Email = normalizedEmail,
            Token = rawToken,
            ExpiresAt = expiresAt
        }, ct);
    }

    private static string GenerateResetToken(int length)
    {
        const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

        return string.Create<object?>(length, null, (span, _) =>
        {
            Span<byte> randomBytes = stackalloc byte[length];
            RandomNumberGenerator.Fill(randomBytes);

            for (var i = 0; i < length; i++)
            {
                span[i] = chars[randomBytes[i] % chars.Length];
            }
        });
    }
}