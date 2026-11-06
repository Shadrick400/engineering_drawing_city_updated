import 'package:flutter/material.dart';

import 'package:engineering_drawing_city/services/firebase_service.dart';
import 'package:engineering_drawing_city/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgot-password';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  bool _emailSent = false;

  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _clearMessages();
    });

    try {
      await _authService.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _emailSent = true;
        _successMessage =
            'Password reset email sent. Please check your inbox and follow the link to create a new password.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _useDifferentEmail() {
    setState(() {
      _emailController.clear();
      _emailSent = false;
      _clearMessages();
    });
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepCircle(1, 'Email', true),
        Expanded(child: _stepLine(_emailSent)),
        _stepCircle(2, 'Reset', _emailSent),
      ],
    );
  }

  Widget _stepCircle(
    int number,
    String label,
    bool active,
  ) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primaryBlue
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: active
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : Text(
                    '$number',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active
                ? AppTheme.primaryBlue
                : Colors.grey.shade600,
            fontWeight:
                active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: 20,
      ),
      color: active
          ? AppTheme.primaryBlue
          : Colors.grey.shade300,
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reset your password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkNavy,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the email address connected to your Engineering Drawing City account. We will send you a secure password reset link.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your registered email',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppTheme.primaryBlue,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }

            final email = value.trim();

            if (!email.contains('@') ||
                !email.contains('.')) {
              return 'Please enter a valid email address';
            }

            return null;
          },
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Send Reset Email',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 38,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkNavy,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a password reset link to:',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _emailController.text.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Open the email and tap the password reset link. Firebase will take you to the secure password reset page where you can create your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _useDifferentEmail,
          child: const Text(
            'Use a different email',
            style: TextStyle(
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
          child: const Text(
            'Back to Login',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.darkNavy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 15),

                _buildStepIndicator(),

                const SizedBox(height: 35),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(
                            bottom: 18,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  Colors.red.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_successMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(
                            bottom: 18,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Colors.green.withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.green
                                  .withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 250),
                        child: _emailSent
                            ? _buildSuccessStep()
                            : _buildEmailStep(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Remember your password? Sign in',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                    ),
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
