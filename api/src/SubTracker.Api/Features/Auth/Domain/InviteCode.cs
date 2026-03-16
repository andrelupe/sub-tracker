namespace SubTracker.Api.Features.Auth.Domain;

public sealed class InviteCode
{
    public Guid Id { get; private set; }
    public string Code { get; private set; } = string.Empty;
    public Guid CreatedByUserId { get; private set; }
    public Guid? UsedByUserId { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? UsedAt { get; private set; }

    // Navigation
    public User CreatedByUser { get; private set; } = null!;
    public User? UsedByUser { get; private set; }

    private InviteCode() { } // EF Core

    public static InviteCode Create(Guid createdByUserId, string code, DateTime utcNow)
    {
        return new InviteCode
        {
            Id = Guid.NewGuid(),
            Code = code,
            CreatedByUserId = createdByUserId,
            CreatedAt = utcNow
        };
    }

    public bool IsUsed => UsedByUserId is not null;

    public void MarkUsed(Guid usedByUserId, DateTime utcNow)
    {
        UsedByUserId = usedByUserId;
        UsedAt = utcNow;
    }
}
