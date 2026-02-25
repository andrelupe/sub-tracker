import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that wraps its child with keyboard shortcuts for desktop.
///
/// Shortcuts:
/// - `Ctrl+N` / `Cmd+N` → [onAddSubscription]
/// - `/` → [onFocusSearch]
/// - `Escape` → [onEscape]
/// - `Ctrl+R` / `Cmd+R` → [onRefresh]
class KeyboardShortcuts extends StatelessWidget {
  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.onAddSubscription,
    this.onFocusSearch,
    this.onEscape,
    this.onRefresh,
  });

  final Widget child;
  final VoidCallback? onAddSubscription;
  final VoidCallback? onFocusSearch;
  final VoidCallback? onEscape;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Ctrl+N / Cmd+N → Add subscription
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            const _AddSubscriptionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
            const _AddSubscriptionIntent(),
        // / → Focus search
        const SingleActivator(LogicalKeyboardKey.slash):
            const _FocusSearchIntent(),
        // Escape → Close / go back
        const SingleActivator(LogicalKeyboardKey.escape): const _EscapeIntent(),
        // Ctrl+R / Cmd+R → Refresh
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            const _RefreshIntent(),
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true):
            const _RefreshIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _AddSubscriptionIntent: CallbackAction<_AddSubscriptionIntent>(
            onInvoke: (_) {
              onAddSubscription?.call();
              return null;
            },
          ),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              onFocusSearch?.call();
              return null;
            },
          ),
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) {
              onEscape?.call();
              return null;
            },
          ),
          _RefreshIntent: CallbackAction<_RefreshIntent>(
            onInvoke: (_) {
              onRefresh?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _AddSubscriptionIntent extends Intent {
  const _AddSubscriptionIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}
