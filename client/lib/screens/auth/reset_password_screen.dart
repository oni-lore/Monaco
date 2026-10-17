import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monaco/providers/auth_provider.dart';
import 'package:monaco/services/auth_api.dart';
import 'package:monaco/utils/design_system.dart';
import 'package:monaco/widgets/custom_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isResetting = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    setState(() {
      _isResetting = true;
      _error = null;
    });

    try {
      await AuthApiService().resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully. You can now log in.'),
            backgroundColor: MonacoDesign.success,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        String message;
        if (e is SocketException) {
          message = 'Unable to connect to the server. Please check your internet connection.';
        } else if (e is TimeoutException) {
          message = 'The request timed out. Please try again.';
        } else {
          message = e.toString();
        }
        setState(() {
          _error = message;
          _isResetting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MonacoDesign.brandSurface,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: MonacoDesign.brandPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: MonacoDesign.brandPrimary,
                  ),
                ),
                const SizedBox(height: MonacoDesign.md),
                Text(
                  'Create a new password',
                  textAlign: TextAlign.center,
                  style: MonacoDesign.headlineLarge(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: MonacoDesign.brandTextPrimary,
                  ),
                ),
                const SizedBox(height: MonacoDesign.sm),
                Text(
                  'Choose a strong password for your Monaco account.',
                  textAlign: TextAlign.center,
                  style: MonacoDesign.bodyMedium(context).copyWith(
                    color: MonacoDesign.brandTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: MonacoDesign.xl),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: 'At least 6 characters',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: MonacoDesign.md),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _resetPassword(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: MonacoDesign.sm),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: MonacoDesign.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: MonacoDesign.lg),
                      Consumer<AuthProvider>(
                        builder: (BuildContext context, AuthProvider auth, Widget? _) {
                          return CustomButton(
                            text: 'Reset password',
                            isLoading: auth.isLoading || _isResetting,
                            onPressed: _resetPassword,
                          );
                        },
                      ),
                      const SizedBox(height: MonacoDesign.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Remember your password? "),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false),
                            child: const Text('Log in'),
                          ),
                        ],
                      ),
                    ],
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
