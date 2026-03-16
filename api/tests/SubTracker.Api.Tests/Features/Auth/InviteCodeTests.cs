using SubTracker.Api.Features.Auth.Domain;

namespace SubTracker.Api.Tests.Features.Auth;

public class InviteCodeTests
{
    private readonly DateTime _utcNow = new(2026, 3, 15, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Create_ShouldSetAllProperties()
    {
        var createdBy = Guid.NewGuid();

        var invite = InviteCode.Create(createdBy, "ABC12345", _utcNow);

        Assert.NotEqual(Guid.Empty, invite.Id);
        Assert.Equal("ABC12345", invite.Code);
        Assert.Equal(createdBy, invite.CreatedByUserId);
        Assert.Null(invite.UsedByUserId);
        Assert.Null(invite.UsedAt);
        Assert.Equal(_utcNow, invite.CreatedAt);
    }

    [Fact]
    public void IsUsed_ShouldReturnFalse_WhenNotUsed()
    {
        var invite = InviteCode.Create(Guid.NewGuid(), "CODE1234", _utcNow);

        Assert.False(invite.IsUsed);
    }

    [Fact]
    public void MarkUsed_ShouldSetUsedByAndUsedAt()
    {
        var invite = InviteCode.Create(Guid.NewGuid(), "CODE1234", _utcNow);
        var usedBy = Guid.NewGuid();
        var usedAt = _utcNow.AddHours(2);

        invite.MarkUsed(usedBy, usedAt);

        Assert.Equal(usedBy, invite.UsedByUserId);
        Assert.Equal(usedAt, invite.UsedAt);
    }

    [Fact]
    public void IsUsed_ShouldReturnTrue_AfterMarkUsed()
    {
        var invite = InviteCode.Create(Guid.NewGuid(), "CODE1234", _utcNow);

        invite.MarkUsed(Guid.NewGuid(), _utcNow.AddHours(1));

        Assert.True(invite.IsUsed);
    }
}
