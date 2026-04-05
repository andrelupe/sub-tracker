import 'package:flutter/material.dart';

/// Full-width filled button with loading state for authentication forms.
///
/// Displays a [CircularProgressIndicator] alongside [loadingLabel] while
/// [isLoading] is true, and disables tap. Otherwise shows the [label].
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.onPressed,
    required this.label,
    super.key,
    this.loadingLabel = 'Please wait...',
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final String loadingLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(loadingLabel),
                ],
              )
            : Text(label),
      ),
    );
  }
}
