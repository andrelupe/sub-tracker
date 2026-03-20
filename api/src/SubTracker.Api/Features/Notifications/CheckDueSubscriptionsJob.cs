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
        var utcNow = dateTime.UtcNow;

        // Step 1: Advance past billing dates to the next valid future date
        await AdvancePastBillingDatesAsync(db, utcNow, ct);

        // Step 2: Find subscriptions that are due soon and need notification
        var activeSubscriptions = await db.Subscriptions
            .Where(s => s.IsActive)
            .ToListAsync(ct);

        var toNotify = activeSubscriptions.Where(s => s.NeedsNotification(utcNow)).ToList();

        _logger.LogInformation(
            "Found {Total} active subscriptions, {ToNotify} need notification",
            activeSubscriptions.Count,
            toNotify.Count);

        // Step 3: Send notifications and mark as notified
        var successCount = 0;
        var failureCount = 0;

        foreach (var sub in toNotify)
        {
            try
            {
                var days = (int)(sub.NextBillingDate.Date - utcNow.Date).TotalDays;
                await notifications.SendAsync(
                    $"💰 {sub.Name}",
                    $"{sub.Currency} {sub.Amount} renews in {days} day(s)",
                    ct
                );

                sub.MarkNotified(utcNow);

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

        await db.SaveChangesAsync(ct);

        stopwatch.Stop();

        _logger.LogInformation(
            "Notification job completed in {ElapsedMs}ms. Sent: {SuccessCount}, Failed: {FailureCount}",
            stopwatch.ElapsedMilliseconds,
            successCount,
            failureCount);
    }

    /// <summary>
    /// Finds active subscriptions with NextBillingDate in the past and advances
    /// them to the next valid future date. Persists changes to the database.
    /// </summary>
    private async Task AdvancePastBillingDatesAsync(AppDbContext db, DateTime utcNow, CancellationToken ct)
    {
        var pastDue = await db.Subscriptions
            .Where(s => s.IsActive)
            .ToListAsync(ct);

        var toUpdate = pastDue.Where(s => s.HasPastBillingDate(utcNow)).ToList();

        if (toUpdate.Count == 0) return;

        _logger.LogInformation(
            "Updating {Count} subscriptions with past billing dates",
            toUpdate.Count);

        foreach (var sub in toUpdate)
        {
            var oldDate = sub.NextBillingDate;
            sub.AdvanceNextBillingDate(utcNow);

            _logger.LogDebug(
                "Updated {Name} NextBillingDate from {OldDate} to {NewDate}",
                sub.Name,
                oldDate,
                sub.NextBillingDate);
        }

        await db.SaveChangesAsync(ct);
    }
}