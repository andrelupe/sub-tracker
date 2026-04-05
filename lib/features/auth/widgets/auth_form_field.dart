import 'package:flutter/material.dart';

/// Reusable text form field for authentication screens.
///
/// Provides consistent styling with label, optional obscure text,
/// and validator support. Used across login, register, and
/// reset password screens.
class AuthFormField extends StatelessWidget {
  const AuthFormField({
    required this.controller,
    required this.label,
    super.key,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.autofocus = false,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool autofocus;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      autofocus: autofocus,
      autofillHints: autofillHints,
    );
  }
}
