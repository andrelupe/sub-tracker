using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Common.Extensions;
using SubTracker.Api.Database;
using SubTracker.Api.Features.Auth.Services;

namespace SubTracker.Api.Features.Auth;

public sealed class ChangePasswordEndpoint(AppDbContext db, IPasswordService password, IDateTimeProvider dateTime, ILogger<ChangePasswordEndpoint> logger)
    : Endpoint<ChangePasswordEndpoint.Request, ChangePasswordEndpoint.Response>
{
    public sealed class Request
    {
        public string CurrentPassword { get; init; } = string.Empty;
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
            RuleFor(x => x.CurrentPassword)
                .NotEmpty().WithMessage("Current password is required");

            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("New password is required")
                .MinimumLength(8).WithMessage("New password must be at least 8 characters");
        }
    }

    public override void Configure()
    {
        Post("/api/auth/change-password");
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        var utcNow = dateTime.UtcNow;
        var userId = User.GetUserId();

        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null)
        {
            await Send.UnauthorizedAsync(ct);

            return;
        }

        // Verify current password
        if (!password.Verify(req.CurrentPassword, user.PasswordHash))
        {
            await HttpContext.Response.SendAsync(new { error = "Current password is incorrect" }, 400, cancellation: ct);

            return;
        }

        // Update password
        var newPasswordHash = password.Hash(req.NewPassword);
        user.UpdatePassword(newPasswordHash, utcNow);

        // Revoke all refresh tokens (force re-login everywhere)
        await db.RefreshTokens
            .Where(t => t.UserId == userId)
            .ExecuteDeleteAsync(ct);

        await db.SaveChangesAsync(ct);

        logger.LogInformation("Password changed for user {UserId}. All refresh tokens revoked", userId);

        await Send.OkAsync(new Response
        {
            Message = "Password changed successfully. Please login again."
        }, ct);
    }
}