namespace SubTracker.Api.Features.Auth.Domain;

public sealed class RefreshToken
{
    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public string TokenHash { get; private set; } = string.Empty;
    public DateTime ExpiresAt { get; private set; }
    public DateTime CreatedAt { get; private set; }

    // Navigation
    public User User { get; private set; } = null!;

    private RefreshToken() { } // EF Core

    public static RefreshToken Create(Guid userId, string tokenHash, DateTime expiresAt, DateTime utcNow)
    {
        return new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            TokenHash = tokenHash,
            ExpiresAt = expiresAt,
            CreatedAt = utcNow
        };
    }

    public bool IsExpired(DateTime utcNow) => ExpiresAt <= utcNow;
}