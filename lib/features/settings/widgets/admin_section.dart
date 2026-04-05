import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/auth/models/invite_code.dart';
import 'package:subtracker/features/auth/providers/auth_providers.dart';
import 'package:subtracker/features/auth/services/auth_api_service.dart';
import 'package:subtracker/features/settings/widgets/generate_invite_dialog.dart';
import 'package:subtracker/features/settings/widgets/invite_code_list.dart';
import 'package:subtracker/features/settings/widgets/reset_password_dialog.dart';

/// Administration section visible only to admin users.
///
/// Provides invite code generation with a list of existing codes,
/// and admin-initiated password reset functionality.
class AdminSection extends ConsumerStatefulWidget {
  const AdminSection({super.key});

  @override
  ConsumerState<AdminSection> createState() => _AdminSectionState();
}

class _AdminSectionState extends ConsumerState<AdminSection> {
  List<InviteCode> _inviteCodes = [];
  bool _isLoadingCodes = false;
  bool _isGenerating = false;
  bool _codesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInviteCodes();
  }

  Future<void> _loadInviteCodes() async {
    setState(() => _isLoadingCodes = true);

    try {
      final authApi = ref.read(authApiServiceProvider);
      final codes = await authApi.listInviteCodes();
      if (mounted) {
        setState(() {
          _inviteCodes = codes;
          _codesLoaded = true;
        });
      }
    } catch (_) {
      // Silently fail — the list will be empty.
    } finally {
      if (mounted) setState(() => _isLoadingCodes = false);
    }
  }

  Future<void> _generateInviteCode() async {
    setState(() => _isGenerating = true);

    try {
      final authApi = ref.read(authApiServiceProvider);
      final code = await authApi.createInviteCode();

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => GenerateInviteDialog(code: code),
        );
        // Refresh the list after generating.
        await _loadInviteCodes();
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
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Administration',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Invite Codes ---
                Text(
                  'Invite Codes',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _generateInviteCode,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Generate Invite Code'),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingCodes && !_codesLoaded)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  InviteCodeList(codes: _inviteCodes),
                const SizedBox(height: 24),

                // --- Password Reset ---
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'Password Reset',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const ResetPasswordDialog(),
                    ),
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Reset User Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
