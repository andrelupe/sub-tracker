using Microsoft.EntityFrameworkCore;
using SubTracker.Api.Features.Settings.Domain;
using SubTracker.Api.Features.Subscriptions.Domain;

namespace SubTracker.Api.Database;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(AppDbContext db)
    {
        // Seed UserSettings if not present
        if (!await db.UserSettings.AnyAsync())
        {
            db.UserSettings.Add(UserSettings.CreateDefault(DateTime.UtcNow));
            await db.SaveChangesAsync();
        }

        if (await db.Subscriptions.AnyAsync())
            return;

        var utcNow = DateTime.UtcNow;

        // ── Normal subscriptions (NextBillingDate in the future, no notification issues) ──

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

            Subscription.Create(
                name: "Car Insurance",
                description: "Biannual vehicle insurance premium",
                amount: 450.00m,
                currency: "EUR",
                billingCycle: BillingCycle.Biannual,
                category: SubscriptionCategory.Utilities,
                startDate: utcNow.AddMonths(-3).AddDays(-10),
                url: null,
                reminderDaysBefore: 14,
                utcNow: utcNow),
        };

        db.Subscriptions.AddRange(subscriptions);

        // ── : Due soon + already notified this cycle → should NOT send again ──

        var alreadyNotified = Subscription.Create(
            name: "Claude Pro",
            description: "Already notified this cycle - should NOT trigger again",
            amount: 20.00m,
            currency: "USD",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Productivity,
            startDate: utcNow.AddDays(1).AddMonths(-3), // NextBillingDate = tomorrow
            url: "https://claude.ai",
            reminderDaysBefore: 3,
            utcNow: utcNow);
        alreadyNotified.MarkNotified(utcNow.AddHours(-2)); // Notified 2 hours ago
        db.Subscriptions.Add(alreadyNotified);

        // ── : Due soon + notified in previous cycle → should send ──

        var notifiedPreviousCycle = Subscription.Create(
            name: "Notion",
            description: "Notified last cycle - should trigger new notification",
            amount: 10.00m,
            currency: "USD",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Productivity,
            startDate: utcNow.AddDays(1).AddMonths(-5), // NextBillingDate = tomorrow
            url: "https://notion.so",
            reminderDaysBefore: 3,
            utcNow: utcNow);
        notifiedPreviousCycle.MarkNotified(utcNow.AddMonths(-1).AddDays(-5)); // Notified in previous cycle
        db.Subscriptions.Add(notifiedPreviousCycle);

        // ── : Due soon + never notified → should send ──

        var neverNotified = Subscription.Create(
            name: "Linear",
            description: "Never notified - should trigger notification",
            amount: 8.00m,
            currency: "USD",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Productivity,
            startDate: utcNow.AddDays(2).AddMonths(-2), // NextBillingDate = in 2 days
            url: "https://linear.app",
            reminderDaysBefore: 3,
            utcNow: utcNow);
        // LastNotifiedAt stays null
        db.Subscriptions.Add(neverNotified);

        // ── : NextBillingDate in the past → job should advance it ──

        var pastDueMonthly = Subscription.Create(
            name: "Dropbox Plus",
            description: "Past due - NextBillingDate should be advanced by the job",
            amount: 11.99m,
            currency: "EUR",
            billingCycle: BillingCycle.Monthly,
            category: SubscriptionCategory.Cloud,
            startDate: utcNow.AddDays(-5).AddMonths(-3), // NextBillingDate = 5 days ago
            url: "https://dropbox.com",
            reminderDaysBefore: 2,
            utcNow: utcNow.AddMonths(-1)); // Create "as if" a month ago, so NextBillingDate is in the past
        db.Subscriptions.Add(pastDueMonthly);

        var pastDueWeekly = Subscription.Create(
            name: "The Athletic",
            description: "Past due weekly - should be advanced to next valid week",
            amount: 2.49m,
            currency: "GBP",
            billingCycle: BillingCycle.Weekly,
            category: SubscriptionCategory.News,
            startDate: utcNow.AddDays(-10), // NextBillingDate = 3 days ago
            url: "https://theathletic.com",
            reminderDaysBefore: 1,
            utcNow: utcNow.AddDays(-10)); // Create "as if" 10 days ago, so NextBillingDate is in the past
        db.Subscriptions.Add(pastDueWeekly);

        // ── Inactive (paused) subscriptions ──

        var inactiveSubscriptions = new[]
        {
            Subscription.Create(
                name: "HBO Max",
                description: "Cancelled after trial",
                amount: 8.99m,
                currency: "EUR",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Entertainment,
                startDate: utcNow.AddMonths(-4).AddDays(-10),
                url: "https://max.com",
                reminderDaysBefore: 2,
                utcNow: utcNow),

            Subscription.Create(
                name: "Duolingo Plus",
                description: "Language learning - paused",
                amount: 6.99m,
                currency: "EUR",
                billingCycle: BillingCycle.Monthly,
                category: SubscriptionCategory.Education,
                startDate: utcNow.AddMonths(-8).AddDays(-5),
                url: "https://duolingo.com",
                reminderDaysBefore: 2,
                utcNow: utcNow),

            Subscription.Create(
                name: "Disney+",
                description: "Shared plan - no longer needed",
                amount: 89.90m,
                currency: "EUR",
                billingCycle: BillingCycle.Yearly,
                category: SubscriptionCategory.Entertainment,
                startDate: utcNow.AddMonths(-10).AddDays(-14),
                url: "https://disneyplus.com",
                reminderDaysBefore: 7,
                utcNow: utcNow),
        };

        foreach (var sub in inactiveSubscriptions)
        {
            sub.Update(
                name: sub.Name,
                description: sub.Description,
                amount: sub.Amount,
                currency: sub.Currency,
                billingCycle: sub.BillingCycle,
                category: sub.Category,
                startDate: sub.StartDate,
                url: sub.Url,
                reminderDaysBefore: sub.ReminderDaysBefore,
                isActive: false,
                utcNow: utcNow);
        }

        db.Subscriptions.AddRange(inactiveSubscriptions);
        await db.SaveChangesAsync();
    }
}
