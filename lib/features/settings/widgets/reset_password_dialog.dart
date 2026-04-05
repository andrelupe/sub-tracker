import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/auth/services/auth_api_service.dart';
import 'package:subtracker/features/auth/widgets/auth_form_field.dart';

/// Dialog for admin-initiated password reset.
///
/// The admin enters a user's email. On confirmation the API returns a
/// reset token which is displayed in a second step with a copy button.
class ResetPasswordDialog extends ConsumerStatefulWidget {
  const ResetPasswordDialog({super.key});

  @override
  ConsumerState<ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _resetToken;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authApi = ref.read(authApiServiceProvider);
      final token = await authApi.requestPasswordReset(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _resetToken = token);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_resetToken == null) return;
    Clipboard.setData(ClipboardData(text: _resetToken!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset token copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_resetToken != null) {
      return _TokenResultDialog(
        token: _resetToken!,
        email: _emailController.text.trim(),
        onCopy: _copyToClipboard,
        onDone: () => Navigator.of(context).pop(),
      );
    }

    return AlertDialog(
      title: const Text('Reset User Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the user's email to generate a reset token."),
            const SizedBox(height: 16),
            AuthFormField(
              controller: _emailController,
              label: 'Email',
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!_emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate Token'),
        ),
      ],
    );
  }
}

/// Shows the generated reset token with copy functionality.
class _TokenResultDialog extends StatelessWidget {
  const _TokenResultDialog({
    required this.token,
    required this.email,
    required this.onCopy,
    required this.onDone,
  });

  final String token;
  final String email;
  final VoidCallback onCopy;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Reset Token Generated'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A reset token has been generated for $email.'),
          const SizedBox(height: 8),
          const Text('Share this token with the user:'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    token,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy token',
                  onPressed: onCopy,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}
