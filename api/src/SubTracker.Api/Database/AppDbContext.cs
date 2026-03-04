using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Features.ExchangeRates.Domain;
using SubTracker.Api.Features.Settings.Domain;
using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Database;

public sealed class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Subscription> Subscriptions => Set<Subscription>();
    public DbSet<ExchangeRate> ExchangeRates => Set<ExchangeRate>();
    public DbSet<UserSettings> UserSettings => Set<UserSettings>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Subscription>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.Currency).HasMaxLength(3).IsRequired();
            entity.Property(e => e.Amount).HasPrecision(18, 2);
            entity.Property(e => e.Url).HasMaxLength(500);
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
