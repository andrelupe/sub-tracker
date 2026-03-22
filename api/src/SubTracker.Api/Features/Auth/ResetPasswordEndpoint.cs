using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Features.Auth;

public sealed class ResetPasswordEndpoint(AppDbContext db, IPasswordService password, ITokenService tokens, IDateTimeProvider dateTime, ILogger<ResetPasswordEndpoint> logger)
    : Endpoint<ResetPasswordEndpoint.Request, ResetPasswordEndpoint.Response>
{
    public sealed class Request
    {
        public string Email { get; init; } = string.Empty;
        public string Token { get; init; } = string.Empty;
        public string NewPassword { get; init; } = string.Empty;
    }

    public new sealed class Response
    {
        public string Message { get; init; } = string.Empty;
    }

    public sealed class Validator : Validator<Request>
    {
        public Validator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Invalid email format");

            RuleFor(x => x.Token)
                .NotEmpty().WithMessage("Reset token is required");

            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("New password is required")
                .MinimumLength(8).WithMessage("Password must be at least 8 characters");
        }
    }

    public override void Configure()
    {
        Post("/api/auth/reset-password");
        AllowAnonymous();
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var utcNow = dateTime.UtcNow;
        var normalizedEmail = req.Email.ToLowerInvariant().Trim();

        var user = await db.Users.FirstOrDefaultAsync(u => u.Email == normalizedEmail, ct);

        if (user is null)
        {
            await HttpContext.Response.SendAsync(new { error = "Invalid email or token" }, 400, cancellation: ct);

            return;
        }

        if (!user.HasValidResetToken(utcNow))
        {
            await HttpContext.Response.SendAsync(new { error = "Invalid email or token" }, 400, cancellation: ct);

            return;
        }

        // Verify token hash
        var tokenHash = tokens.HashToken(req.Token);

        if (user.ResetToken != tokenHash)
        {
            await HttpContext.Response.SendAsync(new { error = "Invalid email or token" }, 400, cancellation: ct);

            return;
        }

        // Update password and clear reset token
        var newPasswordHash = password.Hash(req.NewPassword);
        user.UpdatePassword(newPasswordHash, utcNow);
        await db.SaveChangesAsync(ct);

        logger.LogInformation("Password reset completed for {Email}", normalizedEmail);

        await Send.OkAsync(new Response
        {
            Message = "Password has been reset successfully. Please login with your new password."
        }, ct);
    }
}