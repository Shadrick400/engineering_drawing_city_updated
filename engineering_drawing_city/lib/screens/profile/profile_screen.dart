import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:engineering_drawing_city/models/payment_model.dart';
import 'package:engineering_drawing_city/models/user_model.dart';
import 'package:engineering_drawing_city/services/firebase_service.dart';
import 'package:engineering_drawing_city/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  StreamSubscription? _subscriptionUpdates;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null && user.role != 'admin') {
      _subscriptionUpdates = _firestoreService.getSubscription(user.uid).listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _subscriptionUpdates?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final sub = _firestoreService.getSubscriptionSync(user.uid);
    final hasActiveSub = user.role == 'admin' || (sub != null && sub.status == 'active' && sub.expiryDate.isAfter(DateTime.now()));
    final payments = _firestoreService
        .getAllPaymentsSync()
        .where((p) => p.userId == user.uid)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Suspension Banner
                if (user.isSuspended)
                  _buildSuspensionBanner(user),

                // Profile Header Card
                _buildProfileCard(user),
                const SizedBox(height: 20),

                // Student Details (editable)
                _buildAcademicCard(user),
                const SizedBox(height: 20),

                // Subscription Status
                _buildSubscriptionCard(user, hasActiveSub, sub),
                const SizedBox(height: 20),

                // Payment History
                _buildPaymentHistory(payments),
                const SizedBox(height: 20),

                // Account Actions
                _buildAccountActions(user),
                const SizedBox(height: 20),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuspensionBanner(UserModel user) {
    final reason = user.suspensionReason ??
        'This account is currently suspended. Please contact the administrator for assistance.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorRed.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.block, color: AppTheme.errorRed, size: 22),
              SizedBox(width: 10),
              Text(
                'Account Suspended',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: $reason',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Please contact the administrator for an account review.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentCyan.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                  ),
                  if (user.phoneNumber != null &&
                      user.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_android,
                            size: 14, color: AppTheme.primaryBlue),
                        const SizedBox(width: 4),
                        Text(
                          user.phoneNumber!,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyanLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicCard(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Academic Information',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNavy),
                ),

              ],
            ),
            const SizedBox(height: 14),
            _infoRow(Icons.location_city, 'Institution',
                user.institution ?? 'The Copperbelt University'),
            const Divider(height: 20),
            _infoRow(Icons.school, 'Programme',
                user.program ?? 'Not specified'),
            const Divider(height: 20),
            _infoRow(Icons.calendar_today, 'Year of Study',
                user.year ?? 'Not specified'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkNavy)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(UserModel user, bool hasActiveSub, dynamic sub) {
    final isAdministrator = user.role == 'admin';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subscription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNavy,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasActiveSub
                        ? AppTheme.successGreen.withValues(alpha: 0.15)
                        : AppTheme.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAdministrator ? 'ADMIN ACCESS' : (hasActiveSub ? 'ACTIVE' : 'NOT ACTIVE'),
                    style: TextStyle(
                      color: isAdministrator || hasActiveSub
                          ? AppTheme.successGreen
                          : AppTheme.darkNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isAdministrator)
              const Text('Administrator accounts have complimentary access to all app features.')
            else if (hasActiveSub && sub != null) ...[
              Text(
                'Your access expires on ${sub.expiryDate.toLocal().toString().split(' ')[0]}.',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ] else ...[
              const Text(
                'Student subscription: K50 per month.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Secure mobile money checkout is being configured. '
                'Payments are not being collected yet. Your account will unlock '
                'premium materials after a successful payment is verified.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildPaymentHistory(List<PaymentModel> payments) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment History',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkNavy),
            ),
            const SizedBox(height: 12),
            if (payments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No payment records found.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = payments[index];
                  final isApproved = p.status == 'approved';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isApproved ? Icons.check_circle : Icons.pending,
                      color: isApproved
                          ? AppTheme.successGreen
                          : Colors.orange,
                    ),
                    title: Text(
                      'K${p.amount.toStringAsFixed(0)} — ${p.paymentReference}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Submitted: ${p.submittedAt.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                    trailing: Text(
                      p.status.toUpperCase(),
                      style: TextStyle(
                        color: isApproved
                            ? AppTheme.successGreen
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                Icon(Icons.settings, color: AppTheme.primaryBlue),
                SizedBox(width: 10),
                Text('Profile Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit, color: AppTheme.primaryBlue),
            title: const Text('Edit Full Name'),
            onTap: () => _showEditNameDialog(user),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.phone_android, color: AppTheme.primaryBlue),
            title: const Text('Edit Phone Number'),
            subtitle: Text(
              user.phoneNumber?.isNotEmpty == true
                  ? user.phoneNumber!
                  : 'Not set',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () => _showEditPhoneDialog(user),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.school, color: AppTheme.primaryBlue),
            title: const Text('Edit Programme & Year'),
            onTap: () => _showEditAcademicDialog(user),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorRed),
            title: const Text('Sign Out',
                style: TextStyle(color: AppTheme.errorRed)),
            onTap: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  // ── DIALOGS ──

  void _showEditNameDialog(UserModel user) {
    final controller = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final updated = user.copyWith(
                  name: newName,
                  updatedAt: DateTime.now(),
                );
                await _firestoreService.saveUser(updated);
                _authService.setCurrentUser(updated);
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(UserModel user) {
    final controller =
        TextEditingController(text: user.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Phone Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            hintText: 'e.g. 0972123456',
            prefixIcon:
                Icon(Icons.phone_android, color: AppTheme.primaryBlue),
            helperText: 'Used for future mobile money payment prompts',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final phone = controller.text.trim();
              if (phone.isNotEmpty) {
                final updated = user.copyWith(
                  phoneNumber: phone,
                  updatedAt: DateTime.now(),
                );
                await _firestoreService.saveUser(updated);
                _authService.setCurrentUser(updated);
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditAcademicDialog(UserModel user) {
    final yearController = TextEditingController(text: user.year ?? '');
    final programmeController = TextEditingController(text: user.program ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Academic Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: programmeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Programme',
                hintText: 'e.g. Civil Engineering',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: yearController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Year of Study',
                hintText: 'e.g. Year 2',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final programme = programmeController.text.trim();
              final year = yearController.text.trim();
              if (programme.isEmpty || year.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter both your programme and year of study.'),
                  ),
                );
                return;
              }
              final updated = user.copyWith(
                year: year,
                program: programme,
                updatedAt: DateTime.now(),
              );
              try {
                await _firestoreService.saveUser(updated);
                _authService.setCurrentUser(updated);
                if (mounted) setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not update profile: $error')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}