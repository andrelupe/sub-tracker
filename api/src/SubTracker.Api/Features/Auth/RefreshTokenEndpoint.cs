using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Features.Auth;

public sealed class RefreshTokenEndpoint : Endpoint<RefreshTokenEndpoint.Request, RefreshTokenEndpoint.Response>
{
    public sealed class Request
    {
        public string RefreshToken { get; init; } = string.Empty;
    }

    public new sealed class Response
    {
        public string AccessToken { get; init; } = string.Empty;
        public int ExpiresIn { get; init; }
    }

    public sealed class Validator : Validator<Request>
    {
        public Validator()
        {
            RuleFor(x => x.RefreshToken)
                .NotEmpty().WithMessage("Refresh token is required");
        }
    }

    private readonly AppDbContext _db;
    private readonly ITokenService _tokens;
    private readonly IDateTimeProvider _dateTime;
    private readonly IConfiguration _config;

    public RefreshTokenEndpoint(
        AppDbContext db,
        ITokenService tokens,
        IDateTimeProvider dateTime,
        IConfiguration config)
    {
        _db = db;
        _tokens = tokens;
        _dateTime = dateTime;
        _config = config;
    }

    public override void Configure()
    {
        Post("/api/auth/refresh");
        AllowAnonymous();
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var utcNow = _dateTime.UtcNow;
        var tokenHash = _tokens.HashToken(req.RefreshToken);

        var storedToken = await _db.RefreshTokens
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.TokenHash == tokenHash, ct);

        if (storedToken is null)
        {
            await HttpContext.Response.SendAsync(new { error = "Invalid refresh token" }, 401, cancellation: ct);
            return;
        }

        if (storedToken.IsExpired(utcNow))
        {
            // Clean up expired token
            _db.RefreshTokens.Remove(storedToken);
            await _db.SaveChangesAsync(ct);

            await HttpContext.Response.SendAsync(new { error = "Refresh token has expired" }, 401, cancellation: ct);
            return;
        }

        // Generate new access token (same refresh token stays)
        var accessToken = _tokens.GenerateAccessToken(storedToken.User);
        var accessTokenMinutes = int.Parse(_config["Jwt:AccessTokenExpirationMinutes"] ?? "15");

        await Send.OkAsync(new Response
        {
            AccessToken = accessToken,
            ExpiresIn = accessTokenMinutes * 60
        }, ct);
    }
}
