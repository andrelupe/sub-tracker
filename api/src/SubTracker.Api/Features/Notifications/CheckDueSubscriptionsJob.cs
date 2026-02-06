using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;

namespace SubTracker.Api.Features.Notifications;

public sealed class CheckDueSubscriptionsJob : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<CheckDueSubscriptionsJob> _logger;
    private readonly TimeSpan _interval = TimeSpan.FromHours(1);

    public CheckDueSubscriptionsJob(
        IServiceScopeFactory scopeFactory,
        ILogger<CheckDueSubscriptionsJob> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CheckAndNotifyAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking due subscriptions");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task CheckAndNotifyAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var notifications = scope.ServiceProvider.GetRequiredService<INotificationService>();
        var dateTime = scope.ServiceProvider.GetRequiredService<IDateTimeProvider>();

        var dueSubscriptions = await db.Subscriptions
            .Where(s => s.IsActive)
            .ToListAsync(ct);

        foreach (var sub in dueSubscriptions.Where(s => s.IsDueSoon(dateTime.UtcNow)))
        {
            var days = (int)(sub.NextBillingDate - dateTime.UtcNow).TotalDays;
            await notifications.SendAsync(
                $"💰 {sub.Name}",
                $"{sub.Currency} {sub.Amount} renews in {days} day(s)",
                ct
            );

            _logger.LogInformation("Notification sent for {Name}", sub.Name);
        }
    }
}
