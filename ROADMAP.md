# SubTracker Roadmap

Planned features and improvements for SubTracker.

## v2.2.0 — Settings & Data Management

| Feature            | Description                                  |
| ------------------ | -------------------------------------------- |
| ⚙️ Settings screen | Dedicated settings page accessible from home |
| ☀️ Theme selector  | System / Light / Dark theme options          |
| 📤 Export JSON     | Export subscriptions for backup/migration    |
| 📥 Import JSON     | Import subscriptions from a JSON file        |
| ℹ️ About section   | App version and GitHub link                  |

## v2.2.1 — Responsive Desktop Layout

| Feature                     | Description                                                  |
| --------------------------- | ------------------------------------------------------------ |
| ResponsiveLayout widget     | Mobile/tablet/desktop breakpoints (<600, 600-900, >900px)    |
| CenteredContent widget      | Max-width content constraining with configurable padding     |
| Desktop two-column layout   | 320px sidebar + main content area, 1100px max-width          |
| Tablet centered layout      | Single-column layout centered at 600px max-width             |
| Form and Settings centering | CenteredContent applied to form (500px) and settings (600px) |

## v2.2.2 — UI Polish & Desktop UX

| Feature                     | Description                                                   |
| --------------------------- | ------------------------------------------------------------- |
| Desktop hover actions       | Inline Pause/Delete buttons on card hover                     |
| Undo delete                 | SnackBar with undo action after deleting subscriptions        |
| Desktop refresh button      | Refresh icon in AppBar for desktop (pull-to-refresh fallback) |
| Hover state on cards        | Visual feedback on card hover via CardTheme clipBehavior      |
| FilledButton dark mode fix  | Explicit primary color for better visibility                  |
| Success feedback            | SnackBar confirmation after creating or editing               |
| Inactive badge              | Visual "Paused" badge and reduced opacity for inactive subs   |
| Search debounce             | 300ms debounce to prevent excessive filtering                 |
| Sticky desktop header       | Section header stays fixed while scrolling                    |
| Consistent AppBar           | Uniform 1100px maxWidth across all pages                      |
| Contrast improvements       | Better text contrast in summary card and settings labels      |
| Category color adjustments  | Darker cloud, news, and education colors for accessibility    |
| Tooltips                    | Category name on icon hover, due soon threshold explanation   |
| Settings icons              | Download/upload icons replace chevrons in export/import       |
| Description field expansion | minLines: 2, maxLines: 5 for the description input            |
| Reusable delete dialog      | Extracted ConfirmDeleteDialog widget                          |
| Theme refactor              | Deduplicated light/dark theme via shared \_buildTheme()       |
| Branding                    | AppBar title updated to "SubTracker"                          |

## v2.3.0 — Security & Multi-currency

| Feature                  | Description                                |
| ------------------------ | ------------------------------------------ |
| 🔐 JWT Authentication    | Login with tokens, protected API endpoints |
| 💱 Currency conversion   | External exchange rate API integration     |
| 🌍 Base currency setting | Totals converted to preferred currency     |

## v2.4.0 — Analytics & Insights

| Feature                 | Description                               |
| ----------------------- | ----------------------------------------- |
| 📊 Spending by category | Pie chart visualization with fl_chart     |
| 📈 Monthly trends       | Line chart showing spending over time     |
| 📋 Statistics screen    | Averages, trends, most expensive category |

## v2.5.0 — Multi-user

| Feature              | Description                             |
| -------------------- | --------------------------------------- |
| 👥 User registration | Create account with email/password      |
| 🔒 Data isolation    | Each user sees only their subscriptions |

## Future Ideas

| Feature                      | Description                               |
| ---------------------------- | ----------------------------------------- |
| 🔑 OIDC support              | Login with Google, Apple, Microsoft, etc. |
| 📱 Native mobile app         | Flutter iOS/Android build                 |
| 🔔 Native push notifications | Firebase Cloud Messaging                  |
| 📅 Calendar integration      | Sync billing dates with calendar          |
| 🏷️ Custom categories         | User-defined categories with icons        |
| 📎 Receipt attachments       | Upload invoices/receipts per subscription |

---

> This roadmap is subject to change based on user feedback and priorities.
