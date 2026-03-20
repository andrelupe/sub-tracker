using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Features.Auth.Domain;

public sealed class User
{
    public Guid Id { get; private set; }
    public string Email { get; private set; } = string.Empty;
    public string PasswordHash { get; private set; } = string.Empty;
    public UserRole Role { get; private set; }
    public string? ResetToken { get; private set; }
    public DateTime? ResetTokenExpiresAt { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    // Navigation properties
    public ICollection<RefreshToken> RefreshTokens { get; private set; } = [];
    public ICollection<Subscription> Subscriptions { get; private set; } = [];

    private User() { } // EF Core

    public static User Create(string email, string passwordHash, UserRole role, DateTime utcNow)
    {
        return new User
        {
            Id = Guid.NewGuid(),
            Email = email.ToLowerInvariant().Trim(),
            PasswordHash = passwordHash,
            Role = role,
            CreatedAt = utcNow,
            UpdatedAt = utcNow
        };
    }

    public void UpdatePassword(string newPasswordHash, DateTime utcNow)
    {
        PasswordHash = newPasswordHash;
        ResetToken = null;
        ResetTokenExpiresAt = null;
        UpdatedAt = utcNow;
    }

    public void UpdateEmail(string newEmail, DateTime utcNow)
    {
        Email = newEmail.ToLowerInvariant().Trim();
        UpdatedAt = utcNow;
    }

    public void SetResetToken(string tokenHash, DateTime expiresAt, DateTime utcNow)
    {
        ResetToken = tokenHash;
        ResetTokenExpiresAt = expiresAt;
        UpdatedAt = utcNow;
    }

    public void ClearResetToken(DateTime utcNow)
    {
        ResetToken = null;
        ResetTokenExpiresAt = null;
        UpdatedAt = utcNow;
    }

    public bool HasValidResetToken(DateTime utcNow)
        => ResetToken is not null && ResetTokenExpiresAt > utcNow;

    public bool IsAdmin => Role == UserRole.Admin;
}