import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subtracker/features/settings/providers/settings_providers.dart';

/// Shell widget that provides persistent navigation across tabs.
///
/// Shows a [NavigationBar] on mobile/tablet (< 900px) or a [NavigationRail]
/// on desktop (>= 900px). The Analytics destination is only visible when
/// the user has enabled it via Settings.
///
/// Tab switches use a subtle fade transition for visual continuity.
class ScaffoldWithNavigation extends ConsumerStatefulWidget {
  const ScaffoldWithNavigation({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavigation> createState() =>
      _ScaffoldWithNavigationState();
}

class _ScaffoldWithNavigationState extends ConsumerState<ScaffoldWithNavigation>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 180);

  late final AnimationController _controller;
  int? _pendingBranch;

  /// All possible destinations (indices match the StatefulShellRoute branches).
  static const _allDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: 1, // start fully visible
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Branch indices that are visible given the current configuration.
  List<int> _visibleBranches(bool analyticsEnabled) =>
      analyticsEnabled ? [0, 1, 2] : [0, 2];

  /// The destinations shown in the navigation bar/rail.
  List<NavigationDestination> _destinations(List<int> branches) =>
      branches.map((i) => _allDestinations[i]).toList();

  /// Maps the current shell branch index to the visible navigation index.
  int _selectedIndex(List<int> branches) {
    final idx = branches.indexOf(widget.navigationShell.currentIndex);
    return idx >= 0 ? idx : 0;
  }

  /// Navigates to the shell branch at the given visible navigation index.
  /// Fades out, switches branch, then fades back in.
  void _onDestinationSelected(int visibleIndex, List<int> branches) {
    final branchIndex = branches[visibleIndex];
    if (branchIndex == widget.navigationShell.currentIndex) {
      // Already on this tab — go to initial location
      widget.navigationShell.goBranch(branchIndex, initialLocation: true);
      return;
    }

    // Avoid queueing multiple transitions
    if (_pendingBranch != null) return;

    _pendingBranch = branchIndex;

    // Fade out, then switch branch
    _controller.reverse().then((_) {
      if (!mounted) return;
      widget.navigationShell.goBranch(_pendingBranch!);
      _pendingBranch = null;
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsEnabled = ref.watch(analyticsEnabledNotifierProvider);
    final branches = _visibleBranches(analyticsEnabled);
    final destinations = _destinations(branches);
    final selectedIndex = _selectedIndex(branches);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    final body = FadeTransition(
      opacity: _controller,
      child: widget.navigationShell,
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _onDestinationSelected(i, branches),
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _onDestinationSelected(i, branches),
        destinations: destinations,
      ),
    );
  }
}
