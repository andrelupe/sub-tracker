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
        _logger.LogInformation("CheckDueSubscriptionsJob started. Running every {IntervalMinutes} minutes", _interval.TotalMinutes);
        
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
        
        _logger.LogInformation("CheckDueSubscriptionsJob stopped");
    }

    private async Task CheckAndNotifyAsync(CancellationToken ct)
    {
        _logger.LogInformation("Notification job started");
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();
        
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var notifications = scope.ServiceProvider.GetRequiredService<INotificationService>();
        var dateTime = scope.ServiceProvider.GetRequiredService<IDateTimeProvider>();

        var dueSubscriptions = await db.Subscriptions
            .Where(s => s.IsActive)
            .ToListAsync(ct);

        var subscriptionsDueSoon = dueSubscriptions.Where(s => s.IsDueSoon(dateTime.UtcNow)).ToList();
        
        _logger.LogInformation("Found {Count} subscriptions due for notification", subscriptionsDueSoon.Count);

        var successCount = 0;
        var failureCount = 0;

        foreach (var sub in subscriptionsDueSoon)
        {
            try
            {
                var days = (int)(sub.NextBillingDate - dateTime.UtcNow).TotalDays;
                await notifications.SendAsync(
                    $"💰 {sub.Name}",
                    $"{sub.Currency} {sub.Amount} renews in {days} day(s)",
                    ct
                );

                _logger.LogInformation(
                    "Notification sent for subscription {SubscriptionId} ({SubscriptionName})",
                    sub.Id,
                    sub.Name);
                
                successCount++;
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Failed to send notification for subscription {SubscriptionId} ({SubscriptionName})",
                    sub.Id,
                    sub.Name);
                
                failureCount++;
            }
        }

        stopwatch.Stop();
        
        _logger.LogInformation(
            "Notification job completed in {ElapsedMs}ms. Sent: {SuccessCount}, Failed: {FailureCount}",
            stopwatch.ElapsedMilliseconds,
            successCount,
            failureCount);
    }
}
