import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monaco/providers/auth_provider.dart';
import 'package:monaco/services/auth_api.dart';
import 'package:monaco/utils/design_system.dart';
import 'package:monaco/widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await AuthApiService().requestPasswordReset(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isSubmitting = false;
        });
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MonacoDesign.charcoalDeep,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: MonacoDesign.accentBright),
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
                    color: MonacoDesign.inkBlack.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 36,
                    color: MonacoDesign.inkBlack,
                  ),
                ),
                const SizedBox(height: MonacoDesign.md),
                Text(
                  'Reset your password',
                  textAlign: TextAlign.center,
                  style: MonacoDesign.headlineLarge(context).copyWith(
                    fontWeight: FontWeight.w800,
                      color: MonacoDesign.textInk,
                  ),
                ),
                const SizedBox(height: MonacoDesign.sm),
                Text(
                  'Enter your email address and we will send you a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: MonacoDesign.bodyMedium(context).copyWith(
                      color: MonacoDesign.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: MonacoDesign.xl),

                if (!_emailSent) ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: MonacoDesign.inputDecoration(
                            context: context,
                            label: 'Email address',
                            hint: 'you@example.com',
                            prefixIcon: Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _sendResetLink(),
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
                              text: 'Send reset link',
                              isLoading: auth.isLoading || _isSubmitting,
                              onPressed: _sendResetLink,
                            );
                          },
                        ),
                        const SizedBox(height: MonacoDesign.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Remember your password? "),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Log in'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: MonacoDesign.success,
                  ),
                  const SizedBox(height: MonacoDesign.md),
                  Text(
                    'Reset link sent',
                    textAlign: TextAlign.center,
                    style: MonacoDesign.headlineMedium(context).copyWith(
                      fontWeight: FontWeight.w800,
                    color: MonacoDesign.textInk,
                    ),
                  ),
                  const SizedBox(height: MonacoDesign.sm),
                  Text(
                    'If an account exists with this email address, you will receive a password reset link. The link expires in 1 hour.',
                    textAlign: TextAlign.center,
                    style: MonacoDesign.bodyMedium(context).copyWith(
                    color: MonacoDesign.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: MonacoDesign.xl),
                  Consumer<AuthProvider>(
                    builder: (BuildContext context, AuthProvider auth, Widget? _) {
                      return CustomButton(
                        text: 'Back to login',
                        isLoading: auth.isLoading,
                        onPressed: () => Navigator.of(context).pop(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
