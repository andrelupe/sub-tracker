using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Database;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(AppDbContext db)
    {
        if (await db.Subscriptions.AnyAsync())
            return;

        var utcNow = DateTime.UtcNow;

        var subscriptions = new[]
        {
            Subscription.Create(
                name: "Netflix",
                description: "Standard plan with ads",
                amount: 7.99m,
                currency: "EUR",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Entertainment,
                startDate: utcNow.AddMonths(-6).AddDays(-3),
                url: "https://netflix.com",
                reminderDaysBefore: 3,
                utcNow: utcNow),

            Subscription.Create(
                name: "Spotify Premium",
                description: "Individual plan",
                amount: 11.99m,
                currency: "EUR",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Music,
                startDate: utcNow.AddMonths(-14).AddDays(-10),
                url: "https://spotify.com",
                reminderDaysBefore: 2,
                utcNow: utcNow),

            Subscription.Create(
                name: "iCloud+",
                description: "200 GB storage",
                amount: 2.99m,
                currency: "EUR",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Cloud,
                startDate: utcNow.AddMonths(-24).AddDays(-1),
                url: "https://apple.com/icloud",
                reminderDaysBefore: 2,
                utcNow: utcNow),

            Subscription.Create(
                name: "Adobe Creative Cloud",
                description: "Photography plan - Photoshop + Lightroom",
                amount: 12.09m,
                currency: "EUR",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Productivity,
                startDate: utcNow.AddMonths(-8).AddDays(-15),
                url: "https://adobe.com",
                reminderDaysBefore: 5,
                utcNow: utcNow),

            Subscription.Create(
                name: "GitHub Pro",
                description: null,
                amount: 4.00m,
                currency: "USD",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Productivity,
                startDate: utcNow.AddMonths(-30).AddDays(-5),
                url: "https://github.com",
                reminderDaysBefore: 2,
                utcNow: utcNow),

            Subscription.Create(
                name: "ChatGPT Plus",
                description: "OpenAI subscription",
                amount: 20.00m,
                currency: "USD",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Productivity,
                startDate: utcNow.AddMonths(-10).AddDays(-7),
                url: "https://chat.openai.com",
                reminderDaysBefore: 3,
                utcNow: utcNow),

            Subscription.Create(
                name: "Nintendo Switch Online",
                description: "Family membership",
                amount: 39.99m,
                currency: "EUR",
                billingCycle: BillingCycle.Yearly,
                category: SubscriptionCategory.Gaming,
                startDate: utcNow.AddMonths(-4).AddDays(-20),
                url: "https://nintendo.com",
                reminderDaysBefore: 7,
                utcNow: utcNow),

            Subscription.Create(
                name: "The Economist",
                description: "Digital edition",
                amount: 69.90m,
                currency: "EUR",
                billingCycle: BillingCycle.Quarterly,
                category: SubscriptionCategory.News,
                startDate: utcNow.AddMonths(-5).AddDays(-12),
                url: "https://economist.com",
                reminderDaysBefore: 7,
                utcNow: utcNow),

            Subscription.Create(
                name: "Strava",
                description: "Running & cycling tracker",
                amount: 59.99m,
                currency: "EUR",
                billingCycle: BillingCycle.Yearly,
                category: SubscriptionCategory.Fitness,
                startDate: utcNow.AddMonths(-2).AddDays(-8),
                url: "https://strava.com",
                reminderDaysBefore: 14,
                utcNow: utcNow),

            Subscription.Create(
                name: "Coursera Plus",
                description: "Unlimited access to courses",
                amount: 49.00m,
                currency: "USD",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Education,
                startDate: utcNow.AddMonths(-3).AddDays(-18),
                url: "https://coursera.org",
                reminderDaysBefore: 5,
                utcNow: utcNow),

            Subscription.Create(
                name: "NordVPN",
                description: "2-year plan, billed yearly",
                amount: 59.88m,
                currency: "EUR",
                billingCycle: BillingCycle.Yearly,
                category: SubscriptionCategory.Utilities,
                startDate: utcNow.AddMonths(-7).AddDays(-2),
                url: "https://nordvpn.com",
                reminderDaysBefore: 14,
                utcNow: utcNow),

            Subscription.Create(
                name: "YouTube Premium",
                description: "Ad-free + YouTube Music",
                amount: 13.99m,
                currency: "EUR",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Entertainment,
                startDate: utcNow.AddMonths(-11).AddDays(-6),
                url: "https://youtube.com/premium",
                reminderDaysBefore: 2,
                utcNow: utcNow),
        };

        db.Subscriptions.AddRange(subscriptions);
        await db.SaveChangesAsync();
    }
}
