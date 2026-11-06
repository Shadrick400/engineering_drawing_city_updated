import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:engineering_drawing_city/services/firebase_service.dart';
import 'package:engineering_drawing_city/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  String? _errorMessage;

  // Student-specific fields
  String? _selectedYear;
  String? _selectedProgram;
  // Institution is fixed to CBU for now
  final String _institution = 'The Copperbelt University';

  static const List<String> _years = [
    'Year 1',
    'Year 2',
  ];

  static const List<String> _programs = [
    'Bachelor of Engineering II (BEng II)',
    'Mining Engineering',
    'Chemical engineering',
    'Metallurgical Engineering',
    'Geometics engineering',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'You must accept the Terms & Conditions to create an account.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.registerWithEmailPassword(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text.trim(),
        year: _selectedYear,
        program: _selectedProgram,
        institution: _institution,
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (user.role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String? Function(T?) validator,
    IconData? icon,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon ?? Icons.arrow_drop_down,
            color: AppTheme.primaryBlue),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gavel, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('Terms & Conditions'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. Account & Access',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                "Keep your sign-in details secure and do not use another person's account without permission. We may restrict access after reviewing serious misuse or security concerns, and you may contact support to challenge an account action.",
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '2. Account Security',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'You may sign in on your supported devices. We may ask you to verify your identity if unusual activity is detected. Contact the administrator through the official support channel once it is published.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '3. Subscription & Payments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'The subscription price, duration, included features, payment method and cancellation/refund terms will be shown before you purchase. Premium features become available after payment is confirmed. Your rights under applicable Zambian consumer law are not removed by these terms.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '4. Content Use & No Downloads Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'The app does not provide download buttons for protected learning materials. Do not reproduce, redistribute, sell or otherwise use materials in a way that infringes the rights of their owners. A breach will be reviewed before any account restriction is applied.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '5. Intellectual Property',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Engineering Drawing City owns the content and software it creates. Other videos, books, drawings, examination papers and images may belong to their respective authors or rights holders and are displayed only where the app has permission or another lawful basis.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '6. Privacy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'We use account and profile information, such as your name, email, phone number, programme and year of study, to operate the app and provide support. Firebase/Google and other service providers may process information on our behalf. The app operator must provide a full Privacy Notice explaining purposes, retention, transfers and your data-protection rights before public launch.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                '7. Amendments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'We will communicate material changes to these terms. Where the law requires fresh consent or notice, we will request it before applying the change.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () {
              setState(() => _acceptedTerms = true);
              Navigator.pop(ctx);
            },
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentCyan.withValues(alpha: 0.3),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.primaryBlue,
                                child: const Icon(Icons.architecture,
                                    size: 36, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Create Student Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'The Copperbelt University',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline,
                              color: AppTheme.primaryBlue),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppTheme.primaryBlue),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number (for payments)',
                          hintText: 'e.g. 0972123456',
                          prefixIcon: Icon(Icons.phone_android,
                              color: AppTheme.primaryBlue),
                          helperText: 'Used for future mobile money payment prompts',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (value.trim().length < 9) {
                            return 'Enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Year Dropdown
                      _buildDropdownField<String>(
                        label: 'Year of Study',
                        value: _selectedYear,
                        items: _years,
                        icon: Icons.calendar_today,
                        onChanged: (val) => setState(() => _selectedYear = val),
                        validator: (val) {
                          if (val == null) return 'Please select your year';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Program Dropdown
                      _buildDropdownField<String>(
                        label: 'Programme / Course',
                        value: _selectedProgram,
                        items: _programs,
                        icon: Icons.school,
                        onChanged: (val) =>
                            setState(() => _selectedProgram = val),
                        validator: (val) {
                          if (val == null) return 'Please select your programme';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Institution (fixed, read-only)
                      TextFormField(
                        initialValue: _institution,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Institution',
                          prefixIcon: Icon(Icons.location_city,
                              color: AppTheme.primaryBlue),
                        ),
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppTheme.primaryBlue),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppTheme.primaryBlue),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        onFieldSubmitted: (_) => _handleRegister(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Terms & Conditions checkbox
                      GestureDetector(
                        onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              activeColor: AppTheme.primaryBlue,
                              onChanged: (val) =>
                                  setState(() => _acceptedTerms = val ?? false),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: GestureDetector(
                                  onTap: _showTermsDialog,
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.black87),
                                      children: [
                                        TextSpan(text: 'I agree to the '),
                                        TextSpan(
                                          text: 'Terms & Conditions',
                                          style: TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        TextSpan(
                                            text:
                                                ' including the device lock & payment policies.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.errorRed.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: AppTheme.errorRed, fontSize: 12),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Create Account',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),

                      const SizedBox(height: 16),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, '/login'),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}