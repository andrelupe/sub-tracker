namespace SubTracker.Api.Common;

public interface INotificationService
{
    Task SendAsync(string title, string message, CancellationToken ct = default);
}
