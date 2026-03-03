using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Common;
using SubTracker.Api.Database;

namespace SubTracker.Api.Features.ExchangeRates;

public sealed class RefreshRatesBackgroundJob : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<RefreshRatesBackgroundJob> _logger;
    private readonly TimeSpan _interval = TimeSpan.FromHours(6);

    public RefreshRatesBackgroundJob(
        IServiceScopeFactory scopeFactory,
        ILogger<RefreshRatesBackgroundJob> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("RefreshRatesBackgroundJob started. Running every {IntervalHours} hours", _interval.TotalHours);

        // On startup: check if rates are stale or missing
        await RefreshIfStaleAsync(stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(_interval, stoppingToken);

            try
            {
                await RefreshIfStaleAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error refreshing exchange rates");
            }
        }

        _logger.LogInformation("RefreshRatesBackgroundJob stopped");
    }

    private async Task RefreshIfStaleAsync(CancellationToken ct)
    {
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var dateTime = scope.ServiceProvider.GetRequiredService<IDateTimeProvider>();
            var utcNow = dateTime.UtcNow;

            var hasRates = await db.ExchangeRates.AnyAsync(ct);

            if (!hasRates || await db.ExchangeRates.AnyAsync(r => r.UpdatedAt < utcNow.AddHours(-24), ct))
            {
                _logger.LogInformation("Exchange rates are stale or missing, refreshing...");

                var exchangeRateService = scope.ServiceProvider.GetRequiredService<IExchangeRateService>();
                await exchangeRateService.RefreshRatesAsync(ct);
            }
            else
            {
                _logger.LogDebug("Exchange rates are fresh, skipping refresh");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking/refreshing exchange rates");
        }
    }
}
