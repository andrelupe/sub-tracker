import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subtracker/core/router/app_router.dart';
import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/auth/providers/auth_providers.dart';
import 'package:subtracker/features/auth/widgets/auth_form_field.dart';
import 'package:subtracker/features/auth/widgets/auth_layout.dart';
import 'package:subtracker/features/auth/widgets/auth_submit_button.dart';

/// Email validation pattern.
final _emailRegExp = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$');

/// Registration screen with email, password, confirm password and invite code.
///
/// After successful registration the user is automatically logged in
/// and the auth guard redirects to home.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _inviteCodeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _inviteCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final inviteCode = _inviteCodeController.text.trim();
      await ref.read(authNotifierProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            inviteCode.isEmpty ? null : inviteCode,
          );
      // Auth guard in router handles redirect to home.
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_userFriendlyError(error)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _userFriendlyError(Object error) {
    if (error is ValidationException) {
      return 'Please check your input and try again.';
    }
    if (error is ApiException) {
      if (error.statusCode == 409)
        return 'An account with this email already exists.';
      if (error.statusCode == 0) {
        return 'Could not connect to the server. Check your connection.';
      }
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthLayout(
      child: Semantics(
        label: 'Registration form',
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register to start tracking subscriptions',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                AuthFormField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!_emailRegExp.hasMatch(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthFormField(
                  controller: _inviteCodeController,
                  label: 'Invite Code',
                  hintText: 'Enter your invite code',
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an invite code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                AuthSubmitButton(
                  onPressed: _register,
                  label: 'Register',
                  loadingLabel: 'Creating account...',
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                Tooltip(
                  message: 'Sign in with an existing account',
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Already have an account? Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
