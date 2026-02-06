namespace SubTracker.Api.Common;

public interface IDateTimeProvider
{
    DateTime UtcNow { get; }
}
