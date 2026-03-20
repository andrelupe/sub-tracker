using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Tests.Features.Auth;

public class UserTests
{
    private readonly DateTime _utcNow = new(2026, 3, 15, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Create_ShouldSetAllProperties()
    {
        var user = User.Create("Test@Example.COM", "hashed_password", UserRole.User, _utcNow);

        Assert.NotEqual(Guid.Empty, user.Id);
        Assert.Equal("test@example.com", user.Email);
        Assert.Equal("hashed_password", user.PasswordHash);
        Assert.Equal(UserRole.User, user.Role);
        Assert.Null(user.ResetToken);
        Assert.Null(user.ResetTokenExpiresAt);
        Assert.Equal(_utcNow, user.CreatedAt);
        Assert.Equal(_utcNow, user.UpdatedAt);
    }

    [Fact]
    public void Create_ShouldNormalizeEmail()
    {
        var user = User.Create("  Admin@TEST.com  ", "hash", UserRole.Admin, _utcNow);

        Assert.Equal("admin@test.com", user.Email);
    }

    [Fact]
    public void UpdatePassword_ShouldUpdateHashAndClearResetToken()
    {
        var user = User.Create("user@test.com", "old_hash", UserRole.User, _utcNow);
        user.SetResetToken("token_hash", _utcNow.AddHours(1), _utcNow);
        var later = _utcNow.AddMinutes(30);

        user.UpdatePassword("new_hash", later);

        Assert.Equal("new_hash", user.PasswordHash);
        Assert.Null(user.ResetToken);
        Assert.Null(user.ResetTokenExpiresAt);
        Assert.Equal(later, user.UpdatedAt);
    }

    [Fact]
    public void UpdateEmail_ShouldNormalizeAndUpdate()
    {
        var user = User.Create("old@test.com", "hash", UserRole.User, _utcNow);
        var later = _utcNow.AddMinutes(10);

        user.UpdateEmail("  NEW@Example.COM  ", later);

        Assert.Equal("new@example.com", user.Email);
        Assert.Equal(later, user.UpdatedAt);
    }

    [Fact]
    public void SetResetToken_ShouldSetTokenAndExpiry()
    {
        var user = User.Create("user@test.com", "hash", UserRole.User, _utcNow);
        var expiresAt = _utcNow.AddHours(1);
        var later = _utcNow.AddMinutes(5);

        user.SetResetToken("token_hash", expiresAt, later);

        Assert.Equal("token_hash", user.ResetToken);
        Assert.Equal(expiresAt, user.ResetTokenExpiresAt);
        Assert.Equal(later, user.UpdatedAt);
    }

    [Fact]
    public void ClearResetToken_ShouldNullifyTokenAndExpiry()
    {
        var user = User.Create("user@test.com", "hash", UserRole.User, _utcNow);
        user.SetResetToken("token_hash", _utcNow.AddHours(1), _utcNow);
        var later = _utcNow.AddMinutes(30);

        user.ClearResetToken(later);

        Assert.Null(user.ResetToken);
        Assert.Null(user.ResetTokenExpiresAt);
        Assert.Equal(later, user.UpdatedAt);
    }

    [Fact]
    public void HasValidResetToken_ShouldReturnTrue_WhenTokenNotExpired()
    {
        var user = User.Create("user@test.com", "hash", UserRole.User, _utcNow);
        user.SetResetToken("token_hash", _utcNow.AddHours(1), _utcNow);

        Assert.True(user.HasValidResetToken(_utcNow.AddMinutes(30)));
    }

    [Fact]
    public void HasValidResetToken_ShouldReturnFalse_WhenTokenExpired()
    {
        var user = User.Create("user@test.com", "hash", UserRole.User, _utcNow);
        user.SetResetToken("token_hash", _utcNow.AddHours(1), _utcNow);

        Assert.False(user.HasValidResetToken(_utcNow.AddHours(2)));
    }

    [Fact]
    public void HasValidResetToken_ShouldReturnFalse_WhenNoToken()
    {
        var user = User.Create("user@test.com", "hash", UserRole.User, _utcNow);

        Assert.False(user.HasValidResetToken(_utcNow));
    }

    [Fact]
    public void IsAdmin_ShouldReturnTrue_ForAdminRole()
    {
        var user = User.Create("admin@test.com", "hash", UserRole.Admin, _utcNow);

        Assert.True(user.IsAdmin);
    }

    [Fact]
    public void IsAdmin_ShouldReturnFalse_ForUserRole()
    {
        var user = User.Create("user@test.com", "hash", UserRole.User, _utcNow);

        Assert.False(user.IsAdmin);
    }
}