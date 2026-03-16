using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;
using SubTracker.Api.Features.Auth.Services;
using SubTracker.Api.Features.Auth.Shared;

namespace SubTracker.Api.Features.Auth;

public sealed class LoginEndpoint : Endpoint<LoginEndpoint.Request, AuthResponse>
{
    public sealed class Request
    {
        public string Email { get; init; } = string.Empty;
        public string Password { get; init; } = string.Empty;
    }

    public sealed class Validator : Validator<Request>
    {
        public Validator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required");

            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Password is required");
        }
    }

    private readonly AppDbContext _db;
    private readonly IPasswordService _password;
    private readonly ITokenService _tokens;
    private readonly IDateTimeProvider _dateTime;
    private readonly IConfiguration _config;
    private readonly ILogger<LoginEndpoint> _logger;

    public LoginEndpoint(
        AppDbContext db,
        IPasswordService password,
        ITokenService tokens,
        IDateTimeProvider dateTime,
        IConfiguration config,
        ILogger<LoginEndpoint> logger)
    {
        _db = db;
        _password = password;
        _tokens = tokens;
        _dateTime = dateTime;
        _config = config;
        _logger = logger;
    }

    public override void Configure()
    {
        Post("/api/auth/login");
        AllowAnonymous();
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var utcNow = _dateTime.UtcNow;
        var normalizedEmail = req.Email.ToLowerInvariant().Trim();

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == normalizedEmail, ct);

        if (user is null || !_password.Verify(req.Password, user.PasswordHash))
        {
            await HttpContext.Response.SendAsync(new { error = "Invalid email or password" }, 401, cancellation: ct);
            return;
        }

        // Generate tokens
        var accessToken = _tokens.GenerateAccessToken(user);
        var refreshTokenRaw = _tokens.GenerateRefreshToken();
        var refreshTokenHash = _tokens.HashToken(refreshTokenRaw);

        var refreshTokenDays = int.Parse(_config["Jwt:RefreshTokenExpirationDays"] ?? "30");
        var refreshToken = RefreshToken.Create(user.Id, refreshTokenHash, utcNow.AddDays(refreshTokenDays), utcNow);
        _db.RefreshTokens.Add(refreshToken);

        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("User logged in: {UserId} ({Email})", user.Id, user.Email);

        var accessTokenMinutes = int.Parse(_config["Jwt:AccessTokenExpirationMinutes"] ?? "15");

        await Send.OkAsync(new AuthResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshTokenRaw,
            ExpiresIn = accessTokenMinutes * 60,
            User = new UserResponse
            {
                Id = user.Id,
                Email = user.Email,
                Role = user.Role.ToString()
            }
        }, ct);
    }
}
