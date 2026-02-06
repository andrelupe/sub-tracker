import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';

/// Generates dummy subscriptions for development/testing purposes.
class DummyData {
  static List<Subscription> generateSubscriptions() {
    final now = DateTime.now();

    return [
      // Entertainment
      Subscription(
        id: 'dummy-netflix',
        name: 'Netflix',
        description: 'Standard plan with HD streaming',
        amount: 15.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        startDate: now.subtract(const Duration(days: 90)),
        nextBillingDate: now.add(const Duration(days: 5)),
        url: 'https://netflix.com',
      ),
      Subscription(
        id: 'dummy-disney',
        name: 'Disney+',
        description: 'Annual subscription',
        amount: 89.99,
        billingCycle: BillingCycle.yearly,
        category: SubscriptionCategory.entertainment,
        startDate: now.subtract(const Duration(days: 200)),
        nextBillingDate: now.add(const Duration(days: 165)),
        url: 'https://disneyplus.com',
      ),
      Subscription(
        id: 'dummy-hbomax',
        name: 'HBO Max',
        description: 'Ad-free plan',
        amount: 14.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        startDate: now.subtract(const Duration(days: 45)),
        nextBillingDate: now.add(const Duration(days: 12)),
        url: 'https://max.com',
      ),

      // Music
      Subscription(
        id: 'dummy-spotify',
        name: 'Spotify Premium',
        description: 'Individual plan',
        amount: 11.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.music,
        startDate: now.subtract(const Duration(days: 365)),
        nextBillingDate: now.add(const Duration(days: 3)),
        url: 'https://spotify.com',
      ),

      // Productivity
      Subscription(
        id: 'dummy-notion',
        name: 'Notion',
        description: 'Personal Pro plan',
        amount: 10,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.productivity,
        startDate: now.subtract(const Duration(days: 120)),
        nextBillingDate: now.add(const Duration(days: 18)),
        url: 'https://notion.so',
      ),
      Subscription(
        id: 'dummy-github',
        name: 'GitHub Pro',
        description: 'Developer tools and features',
        amount: 4,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.productivity,
        startDate: now.subtract(const Duration(days: 60)),
        nextBillingDate: now.add(const Duration(days: 22)),
        url: 'https://github.com',
      ),

      // Gaming
      Subscription(
        id: 'dummy-gamepass',
        name: 'Xbox Game Pass',
        description: 'Ultimate subscription',
        amount: 14.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.gaming,
        startDate: now.subtract(const Duration(days: 30)),
        nextBillingDate: now.add(const Duration(days: 2)),
        url: 'https://xbox.com/gamepass',
      ),

      // Cloud Storage
      Subscription(
        id: 'dummy-icloud',
        name: 'iCloud+',
        description: '200GB storage plan',
        amount: 2.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.cloud,
        startDate: now.subtract(const Duration(days: 400)),
        nextBillingDate: now.add(const Duration(days: 8)),
        url: 'https://apple.com/icloud',
      ),
      Subscription(
        id: 'dummy-dropbox',
        name: 'Dropbox Plus',
        description: '2TB cloud storage',
        amount: 119.88,
        billingCycle: BillingCycle.yearly,
        category: SubscriptionCategory.cloud,
        startDate: now.subtract(const Duration(days: 180)),
        nextBillingDate: now.add(const Duration(days: 185)),
        url: 'https://dropbox.com',
      ),

      // Fitness
      Subscription(
        id: 'dummy-strava',
        name: 'Strava Premium',
        description: 'Training analysis and routes',
        amount: 59.99,
        billingCycle: BillingCycle.yearly,
        category: SubscriptionCategory.fitness,
        startDate: now.subtract(const Duration(days: 100)),
        nextBillingDate: now.add(const Duration(days: 265)),
        url: 'https://strava.com',
      ),

      // Education
      Subscription(
        id: 'dummy-duolingo',
        name: 'Duolingo Plus',
        description: 'Language learning without ads',
        amount: 6.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.education,
        startDate: now.subtract(const Duration(days: 75)),
        nextBillingDate: now.add(const Duration(days: 14)),
        url: 'https://duolingo.com',
      ),

      // Utilities
      Subscription(
        id: 'dummy-1password',
        name: '1Password',
        description: 'Family plan',
        amount: 4.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.utilities,
        startDate: now.subtract(const Duration(days: 500)),
        nextBillingDate: now.add(const Duration(days: 6)),
        url: 'https://1password.com',
      ),
    ];
  }
}
