using Microsoft.Extensions.Options;
using SubTracker.Api.Common;

namespace SubTracker.Api.Features.Notifications;

public sealed class PushoverNotificationService : INotificationService
{
    private readonly HttpClient _httpClient;
    private readonly PushoverOptions _options;
    private readonly ILogger<PushoverNotificationService> _logger;

    public PushoverNotificationService(
        HttpClient httpClient,
        IOptions<PushoverOptions> options,
        ILogger<PushoverNotificationService> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task SendAsync(string title, string message, CancellationToken ct = default)
    {
        try
        {
            var content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["token"] = _options.ApiToken,
                ["user"] = _options.UserKey,
                ["title"] = title,
                ["message"] = message,
                ["priority"] = "0"
            });

            var response = await _httpClient.PostAsync(string.Empty, content, ct);
            response.EnsureSuccessStatusCode();

            _logger.LogInformation("Pushover notification sent: {Title}", title);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send Pushover notification");
        }
    }
}
