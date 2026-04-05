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

/// Login screen with email and password fields.
///
/// Redirects to home on successful login via the auth guard in the router.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
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
    if (error is ApiException) {
      if (error.statusCode == 401) return 'Invalid email or password.';
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
        label: 'Login form',
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
                  'SubTracker',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
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
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _login(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                AuthSubmitButton(
                  onPressed: _login,
                  label: 'Login',
                  loadingLabel: 'Signing in...',
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                Tooltip(
                  message: 'Create a new account',
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.register),
                    child: const Text("Don't have an account? Register"),
                  ),
                ),
                Tooltip(
                  message: 'Reset your password with a token from your admin',
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.resetPassword),
                    child: const Text('Forgot password?'),
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
