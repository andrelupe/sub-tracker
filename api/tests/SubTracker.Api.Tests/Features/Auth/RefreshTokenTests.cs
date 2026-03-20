using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Tests.Features.Auth;

public class RefreshTokenTests
{
    private readonly DateTime _utcNow = new(2026, 3, 15, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Create_ShouldSetAllProperties()
    {
        var userId = Guid.NewGuid();
        var expiresAt = _utcNow.AddDays(30);

        var token = RefreshToken.Create(userId, "token_hash", expiresAt, _utcNow);

        Assert.NotEqual(Guid.Empty, token.Id);
        Assert.Equal(userId, token.UserId);
        Assert.Equal("token_hash", token.TokenHash);
        Assert.Equal(expiresAt, token.ExpiresAt);
        Assert.Equal(_utcNow, token.CreatedAt);
    }

    [Fact]
    public void IsExpired_ShouldReturnFalse_WhenNotExpired()
    {
        var token = RefreshToken.Create(Guid.NewGuid(), "hash", _utcNow.AddDays(30), _utcNow);

        Assert.False(token.IsExpired(_utcNow.AddDays(15)));
    }

    [Fact]
    public void IsExpired_ShouldReturnTrue_WhenExpired()
    {
        var token = RefreshToken.Create(Guid.NewGuid(), "hash", _utcNow.AddDays(30), _utcNow);

        Assert.True(token.IsExpired(_utcNow.AddDays(31)));
    }

    [Fact]
    public void IsExpired_ShouldReturnTrue_WhenExactlyAtExpiry()
    {
        var expiresAt = _utcNow.AddDays(30);
        var token = RefreshToken.Create(Guid.NewGuid(), "hash", expiresAt, _utcNow);

        Assert.True(token.IsExpired(expiresAt));
    }
}