namespace SubTracker.Api.Features.Notifications;

public sealed class PushoverOptions
{
    public string ApiToken { get; init; } = string.Empty;
    public string UserKey { get; init; } = string.Empty;
}
