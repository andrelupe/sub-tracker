using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Features.Auth;

public sealed class LogoutEndpoint : Endpoint<LogoutEndpoint.Request>
{
    public sealed class Request
    {
        public string RefreshToken { get; init; } = string.Empty;
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
    private readonly ILogger<LogoutEndpoint> _logger;

    public LogoutEndpoint(AppDbContext db, ITokenService tokens, ILogger<LogoutEndpoint> logger)
    {
        _db = db;
        _tokens = tokens;
        _logger = logger;
    }

    public override void Configure()
    {
        Post("/api/auth/logout");
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var tokenHash = _tokens.HashToken(req.RefreshToken);

        var deleted = await _db.RefreshTokens
            .Where(t => t.TokenHash == tokenHash)
            .ExecuteDeleteAsync(ct);

        if (deleted > 0)
        {
            _logger.LogInformation("Refresh token revoked for user");
        }

        await Send.NoContentAsync(ct);
    }
}
