using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;

namespace SubTracker.Api.Features.Auth;

public sealed class CleanupExpiredTokensJob : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<CleanupExpiredTokensJob> _logger;
    private readonly TimeSpan _interval = TimeSpan.FromHours(24);

    public CleanupExpiredTokensJob(
        IServiceScopeFactory scopeFactory,
        ILogger<CleanupExpiredTokensJob> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("CleanupExpiredTokensJob started. Running every {IntervalHours} hours", _interval.TotalHours);

        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(_interval, stoppingToken);

            try
            {
                await CleanupAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error cleaning up expired tokens");
            }
        }

        _logger.LogInformation("CleanupExpiredTokensJob stopped");
    }

    private async Task CleanupAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var dateTime = scope.ServiceProvider.GetRequiredService<IDateTimeProvider>();
        var utcNow = dateTime.UtcNow;

        var expiredTokens = await db.RefreshTokens
            .Where(t => t.ExpiresAt <= utcNow)
            .CountAsync(ct);

        if (expiredTokens > 0)
        {
            await db.RefreshTokens
                .Where(t => t.ExpiresAt <= utcNow)
                .ExecuteDeleteAsync(ct);

            _logger.LogInformation("Cleaned up {Count} expired refresh tokens", expiredTokens);
        }

        // Clear expired reset tokens on users
        var usersWithExpiredResets = await db.Users
            .Where(u => u.ResetToken != null && u.ResetTokenExpiresAt <= utcNow)
            .ToListAsync(ct);

        foreach (var user in usersWithExpiredResets)
        {
            user.ClearResetToken(utcNow);
        }

        if (usersWithExpiredResets.Count > 0)
        {
            await db.SaveChangesAsync(ct);
            _logger.LogInformation("Cleared {Count} expired reset tokens", usersWithExpiredResets.Count);
        }
    }
}