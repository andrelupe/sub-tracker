using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Features.Auth.Domain;
using SubTracker.Api.Features.ExchangeRates.Domain;
using SubTracker.Api.Features.Settings.Domain;
using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Database;

public sealed class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<InviteCode> InviteCodes => Set<InviteCode>();
    public DbSet<Subscription> Subscriptions => Set<Subscription>();
    public DbSet<ExchangeRate> ExchangeRates => Set<ExchangeRate>();
    public DbSet<UserSettings> UserSettings => Set<UserSettings>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Email).HasMaxLength(256).IsRequired();
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.PasswordHash).HasMaxLength(256).IsRequired();
            entity.Property(e => e.Role).HasConversion<string>().HasMaxLength(20);
            entity.Property(e => e.ResetToken).HasMaxLength(256);
        });

        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.TokenHash).HasMaxLength(256).IsRequired();
            entity.HasIndex(e => e.TokenHash).IsUnique();
            entity.HasOne(e => e.User)
                .WithMany(u => u.RefreshTokens)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<InviteCode>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Code).HasMaxLength(20).IsRequired();
            entity.HasIndex(e => e.Code).IsUnique();
            entity.HasOne(e => e.CreatedByUser)
                .WithMany()
                .HasForeignKey(e => e.CreatedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(e => e.UsedByUser)
                .WithMany()
                .HasForeignKey(e => e.UsedByUserId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Subscription>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.Amount).HasPrecision(18, 2);
            entity.Property(e => e.Url).HasMaxLength(500);
            entity.Property(e => e.UserId).IsRequired();
            entity.HasOne<User>()
                .WithMany(u => u.Subscriptions)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ExchangeRate>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.BaseCurrency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.TargetCurrency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.Rate).HasPrecision(18, 6);
            entity.HasIndex(e => new { e.BaseCurrency, e.TargetCurrency }).IsUnique();
        });

        modelBuilder.Entity<UserSettings>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.BaseCurrency).HasMaxLength(3).IsRequired();
        });
    }
}
