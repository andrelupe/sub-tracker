import 'package:flutter/material.dart';

/// Responsive layout wrapper for authentication screens.
///
/// - **Mobile** (< 600px): full-width with 16px horizontal padding.
/// - **Tablet** (600–899px): centered with max-width 400px.
/// - **Desktop** (≥ 900px): centered [Card] with max-width 400px.
class AuthLayout extends StatelessWidget {
  const AuthLayout({required this.child, super.key});

  /// The form content to display inside the responsive container.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isMobile = width < 600;

    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: isDesktop
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: child,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}
