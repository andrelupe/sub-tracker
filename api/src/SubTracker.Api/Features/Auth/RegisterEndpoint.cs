using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Domain;
using SubTracker.Api.Features.Auth.Services;
using SubTracker.Api.Features.Auth.Shared;

namespace SubTracker.Api.Features.Auth;

public sealed class RegisterEndpoint : Endpoint<RegisterEndpoint.Request, AuthResponse>
{
    public sealed class Request
    {
        public string Email { get; init; } = string.Empty;
        public string Password { get; init; } = string.Empty;
        public string? InviteCode { get; init; }
    }

    public sealed class Validator : Validator<Request>
    {
        public Validator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Invalid email format");

            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Password is required")
                .MinimumLength(8).WithMessage("Password must be at least 8 characters");
        }
    }

    private readonly AppDbContext _db;
    private readonly IPasswordService _password;
    private readonly ITokenService _tokens;
    private readonly IDateTimeProvider _dateTime;
    private readonly IConfiguration _config;
    private readonly ILogger<RegisterEndpoint> _logger;

    public RegisterEndpoint(
        AppDbContext db,
        IPasswordService password,
        ITokenService tokens,
        IDateTimeProvider dateTime,
        IConfiguration config,
        ILogger<RegisterEndpoint> logger)
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
        Post("/api/auth/register");
        AllowAnonymous();
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var utcNow = _dateTime.UtcNow;
        var normalizedEmail = req.Email.ToLowerInvariant().Trim();

        // Check duplicate email
        if (await _db.Users.AnyAsync(u => u.Email == normalizedEmail, ct))
        {
            await HttpContext.Response.SendAsync(new { error = "Email is already registered" }, 409, cancellation: ct);

            return;
        }

        var hasUsers = await _db.Users.AnyAsync(ct);
        UserRole role;

        if (!hasUsers)
        {
            // First user becomes Admin, no invite code needed
            role = UserRole.Admin;
        }
        else
        {
            // Subsequent users require a valid invite code
            if (string.IsNullOrWhiteSpace(req.InviteCode))
            {
                ThrowError("Invite code is required");
            }

            var inviteCode = await _db.InviteCodes
                .FirstOrDefaultAsync(c => c.Code == req.InviteCode && c.UsedByUserId == null, ct);

            if (inviteCode is null)
            {
                ThrowError("Invalid or already used invite code");
            }

            role = UserRole.User;
        }

        // Create user
        var passwordHash = _password.Hash(req.Password);
        var user = Domain.User.Create(normalizedEmail, passwordHash, role, utcNow);
        _db.Users.Add(user);

        // Mark invite code as used (if applicable)
        if (hasUsers && !string.IsNullOrWhiteSpace(req.InviteCode))
        {
            var code = await _db.InviteCodes
                .FirstAsync(c => c.Code == req.InviteCode, ct);
            code.MarkUsed(user.Id, utcNow);
        }

        // Generate tokens
        var accessToken = _tokens.GenerateAccessToken(user);
        var refreshTokenRaw = _tokens.GenerateRefreshToken();
        var refreshTokenHash = _tokens.HashToken(refreshTokenRaw);

        var refreshTokenDays = int.Parse(_config["Jwt:RefreshTokenExpirationDays"] ?? "30");
        var refreshToken = RefreshToken.Create(user.Id, refreshTokenHash, utcNow.AddDays(refreshTokenDays), utcNow);
        _db.RefreshTokens.Add(refreshToken);

        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("User registered: {UserId} ({Email}) as {Role}", user.Id, user.Email, role);

        var accessTokenMinutes = int.Parse(_config["Jwt:AccessTokenExpirationMinutes"] ?? "15");

        await HttpContext.Response.SendAsync(new AuthResponse
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
        }, 201, cancellation: ct);
    }
}