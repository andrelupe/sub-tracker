# SubTracker Roadmap

Planned features and improvements for SubTracker.

## v2.3.0 — UI & Accessibility (Done)

| Feature                       | Description                                                  |
| ----------------------------- | ------------------------------------------------------------ |
| Swipe action hints            | Visual indication of available swipe actions on mobile       |
| Skeleton loading              | Placeholder loading state while fetching subscriptions       |
| Semantics & accessibility     | Screen reader support and semantic labels throughout the app |
| Reposition "Add Subscription" | Move FAB/button to a more ergonomic position on desktop      |
| Bottom sheets → PopupMenu     | Replace bottom sheets with PopupMenu on desktop              |
| Improved tablet layout        | Better use of screen real estate on tablet breakpoint        |
| Keyboard shortcuts            | Keyboard navigation and shortcuts for desktop users          |

## v2.4.0 — Security & Multi-currency (Done)

| Feature                | Description                                                        |
| ---------------------- | ------------------------------------------------------------------ |
| API key authentication | Optional `X-Api-Key` header protection for all API endpoints       |
| Currency conversion    | Frankfurter API integration with 24h DB cache and stale fallback   |
| Base currency setting  | EUR/USD/GBP selector; totals and list tiles show converted amounts |
| User settings API      | `GET/PUT /api/settings` for persisting base currency preference    |
| Exchange rates API     | `GET /api/exchange-rates` with background refresh every 6 hours    |

## v2.5.0 — Analytics & Insights (Done)

| Feature              | Description                                                             |
| -------------------- | ----------------------------------------------------------------------- |
| Permanent navigation | NavigationBar (mobile) + NavigationRail (desktop) with 3 destinations   |
| Spending by category | Donut chart visualization with fl_chart, legend, and touch interactions |
| Monthly trends       | Line chart showing spending over configurable period (3/6/12 months)    |
| Statistics cards     | KPIs: monthly/yearly totals, most expensive subscription, top category  |
| Period selector      | SegmentedButton to filter charts by 3, 6, or 12 months                  |
| Responsive analytics | Mobile full-width, tablet centered (700px), desktop 2-column layout     |
| Accessibility        | Semantics on charts, tooltips on cards, accessible labels on controls   |

## v2.5.1 — Analytics Polish (Done)

| Feature                | Description                                                            |
| ---------------------- | ---------------------------------------------------------------------- |
| Monthly value labels   | Most Expensive and Top Category cards now show `/mo` suffix            |
| Reordered mobile/tablet| Statistics cards first, then period filter + trend chart + donut chart  |
| Reordered desktop      | Monthly trend chart placed directly below period selector              |

## v2.6.0 — Multi-user

| Feature           | Description                             |
| ----------------- | --------------------------------------- |
| User registration | Create account with email/password      |
| Data isolation    | Each user sees only their subscriptions |

## Future Ideas

| Feature                   | Description                               |
| ------------------------- | ----------------------------------------- |
| OIDC support              | Login with Google, Apple, Microsoft, etc. |
| Native mobile app         | Flutter iOS/Android build                 |
| Native push notifications | Firebase Cloud Messaging                  |
| Calendar integration      | Sync billing dates with calendar          |
| Custom categories         | User-defined categories with icons        |
| Receipt attachments       | Upload invoices/receipts per subscription |

---

> This roadmap is subject to change based on user feedback and priorities.
