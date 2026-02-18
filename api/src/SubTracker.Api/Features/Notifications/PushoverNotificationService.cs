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
        if (string.IsNullOrWhiteSpace(_options.ApiToken) || string.IsNullOrWhiteSpace(_options.UserKey))
        {
            _logger.LogWarning("Pushover not configured - skipping notification: {Title}", title);
            return;
        }

        _logger.LogDebug("Sending Pushover notification: {Title}", title);

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

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Pushover notification sent successfully: {Title}", title);
            }
            else
            {
                var responseBody = await response.Content.ReadAsStringAsync(ct);
                _logger.LogError(
                    "Pushover notification failed with status {StatusCode}: {ResponseBody}",
                    response.StatusCode,
                    responseBody);
                
                throw new HttpRequestException($"Pushover request failed with status {response.StatusCode}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send Pushover notification: {Title}", title);
            throw;
        }
    }
}
