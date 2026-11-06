import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:engineering_drawing_city/models/app_settings_model.dart';
import 'package:engineering_drawing_city/models/book_model.dart';
import 'package:engineering_drawing_city/models/course_model.dart';
import 'package:engineering_drawing_city/models/past_paper_model.dart';
import 'package:engineering_drawing_city/models/payment_model.dart';
import 'package:engineering_drawing_city/models/video_model.dart';
import 'package:engineering_drawing_city/models/user_model.dart';
import 'package:engineering_drawing_city/services/firebase_service.dart';
import 'package:engineering_drawing_city/theme/app_theme.dart';

bool _isSupportedLearningPdfUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.path.toLowerCase().endsWith('.pdf') == false) {
    return false;
  }

  // Keep existing private Firebase Storage documents working during migration.
  if (uri.scheme == 'gs') {
    return uri.host.isNotEmpty &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'learning_materials';
  }

  // GitHub must be a direct/raw file URL, not a repository or HTML preview page.
  if (uri.scheme != 'https') return false;
  if (uri.host == 'raw.githubusercontent.com') return true;
  return uri.host == 'github.com' && uri.pathSegments.contains('raw');
}

class AdminLoginScreen extends StatefulWidget {
  static const String routeName = '/admin-login';
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user.role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        setState(() {
          _errorMessage = 'Access denied. This account does not possess administrator credentials.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E293B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 38,
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Administrator Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Course, Video & Payment Verification Console',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Admin Email',
                          prefixIcon: Icon(Icons.security, color: AppTheme.primaryBlue),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Master Password',
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter password' : null,
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: AppTheme.accentGold,
                        ),
                        onPressed: _isLoading ? null : _handleAdminLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: AppTheme.accentGold),
                              )
                            : const Text('Enter Admin Console'),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text('Return to Student Login'),
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

class AdminDashboardScreen extends StatefulWidget {
  static const String routeName = '/admin-dashboard';
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  StreamSubscription? _usersChangesSubscription;
  final Set<String> _activatingUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    final admin = _authService.currentUser;
    if (admin != null) {
      // Reassert admin content access whenever the dashboard is opened.
      _firestoreService.watchSubscription(admin.uid);
    }
    _usersChangesSubscription = _authService.usersStream.listen((_) {
      if (mounted) setState(() {});
    });
    // Fetch a fresh Firebase snapshot after the dashboard listener is ready.
    // This prevents the initial users update from being lost by the broadcast stream.
    unawaited(_authService.loadAllUsers().catchError((Object error) {
      debugPrint('Unable to load admin student list: $error');
    }));
  }

  @override
  void dispose() {
    _usersChangesSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppTheme.accentGold),
            SizedBox(width: 10),
            Text('Admin Management Console'),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentCyan),
            icon: const Icon(Icons.school, size: 18),
            label: const Text('Student View'),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Payments'),
            Tab(icon: Icon(Icons.auto_stories_outlined), text: 'Courses'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Books'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Past Papers'),
            Tab(icon: Icon(Icons.people_outlined), text: 'Students'),
            Tab(icon: Icon(Icons.block_outlined), text: 'Suspended'),
            Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPaymentsTab(),
          _buildCoursesTab(),
          _buildBooksTab(),
          _buildPastPapersTab(),
          _buildUsersTab(),
          _buildSuspendedUsersTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final courses = _firestoreService.getCoursesSync();
    final videos = _firestoreService.getVideosSync();
    final books = _firestoreService.getBooksSync();
    final papers = _firestoreService.getPastPapersSync();
    final payments = _firestoreService.getAllPaymentsSync();
    final pendingCount = payments.where((p) => p.status == 'pending').length;
    final approvedCount = payments.where((p) => p.status == 'approved').length;
    final users = _authService.getAllUsers();
    final suspendedCount = users.where((u) => u.isSuspended).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Portal Metrics & Performance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard('Active Courses', '${courses.length}', Icons.menu_book, AppTheme.primaryBlue),
                  _buildStatCard('Video Lessons', '${videos.length}', Icons.ondemand_video, AppTheme.accentCyan),
                  _buildStatCard('Books', '${books.length}', Icons.auto_stories, const Color(0xFF7C3AED)),
                  _buildStatCard('Past Papers', '${papers.length}', Icons.assignment, const Color(0xFF059669)),
                  _buildStatCard('Pending Payments', '$pendingCount', Icons.pending_actions, Colors.orange),
                  _buildStatCard('Approved Passes', '$approvedCount', Icons.verified, AppTheme.successGreen),
                  if (suspendedCount > 0)
                    _buildStatCard('Suspended Users', '$suspendedCount', Icons.block, AppTheme.errorRed),
                ],
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Admin Actions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add New Course'),
                            onPressed: () => _showAddCourseDialog(),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan),
                            icon: const Icon(Icons.video_call),
                            label: const Text('Add Video Lesson'),
                            onPressed: () => _showAddVideoDialog(),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                            icon: const Icon(Icons.menu_book),
                            label: const Text('Add Book'),
                            onPressed: () => _showAddBookDialog(),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                            icon: const Icon(Icons.assignment_add),
                            label: const Text('Add Past Paper'),
                            onPressed: () => _showAddPastPaperDialog(),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Review Payments'),
                            onPressed: () => _tabController.animateTo(1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return StreamBuilder<List<PaymentModel>>(
      stream: _firestoreService.getAllPayments(),
      builder: (context, snapshot) {
        final payments =
            snapshot.data ?? _firestoreService.getAllPaymentsSync();
        return _buildPaymentsContent(payments);
      },
    );
  }

  Widget _buildPaymentsContent(List<PaymentModel> payments) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Subscription Payments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
              ),
              const SizedBox(height: 6),
              const Text(
                'Approve submitted Mobile Money & bank transaction IDs to activate 30-day student passes.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (payments.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No payment submissions recorded yet.')),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    final isPending = p.status == 'pending';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? Colors.orange.withOpacity(0.12)
                                    : AppTheme.successGreen.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPending ? Icons.hourglass_top : Icons.check,
                                color: isPending ? Colors.orange : AppTheme.successGreen,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'K${p.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.darkNavy,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isPending ? Colors.orange : AppTheme.successGreen,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p.status.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ref: ${p.paymentReference} • Student: ${p.userId}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                  Text(
                                    'Submitted: ${p.submittedAt.toLocal().toString().substring(0, 16)}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (isPending) ...[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                                onPressed: () async {
                                  await _firestoreService.approvePayment(p.id);
                                  setState(() {});
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Payment ${p.paymentReference} approved! Subscription activated.')),
                                  );
                                },
                                child: const Text('Approve Pass'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorRed),
                                onPressed: () async {
                                  await _firestoreService.rejectPayment(p.id);
                                  setState(() {});
                                },
                                child: const Text('Reject'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesTab() {
    final courses = _firestoreService.getCoursesSync();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Engineering Curriculum Modules',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Course'),
                    onPressed: () => _showAddCourseDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = courses[index];
                  final videos = _firestoreService.getVideosByCourseSync(c.id);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue,
                        child: Text('${c.order}', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${c.programme} • ${c.year} • ${c.semester}\n${c.description}\n(${videos.length} videos linked)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue),
                            tooltip: 'Edit programme, year, semester and topic',
                            onPressed: () => _showEditCourseDialog(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.video_call, color: AppTheme.primaryBlue),
                            tooltip: 'Add video to this course',
                            onPressed: () => _showAddVideoDialog(preselectedCourseId: c.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                            tooltip: 'Delete Course',
                            onPressed: () async {
                              await _firestoreService.deleteCourse(c.id);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    final settings = _firestoreService.getAppSettingsSync();
    final nameCtrl = TextEditingController(text: settings.appName);
    final msgCtrl = TextEditingController(text: settings.welcomeMessage);
    final priceCtrl = TextEditingController(text: settings.subscriptionPrice.toString());
    final instrCtrl = TextEditingController(text: settings.paymentInstructions);
    final contactCtrl = TextEditingController(text: settings.contactInformation);
    bool aiActive = settings.aiEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Application & Payment Parameters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Portal Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: msgCtrl,
                    decoration: const InputDecoration(labelText: 'Welcome Banner Header'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Monthly Subscription Price (ZMW)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contactCtrl,
                    decoration: const InputDecoration(labelText: 'Verified Support Contact Details'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: instrCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Payment Instructions'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable AI Drawing Assistant for Students'),
                    value: aiActive,
                    onChanged: (v) => setState(() => aiActive = v),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                    onPressed: () async {
                      final updated = AppSettingsModel(
                        appName: nameCtrl.text.trim(),
                        logo: settings.logo,
                        welcomeMessage: msgCtrl.text.trim(),
                        subscriptionPrice: double.tryParse(priceCtrl.text.trim()) ?? 50.0,
                        subscriptionDuration: settings.subscriptionDuration,
                        paymentInstructions: instrCtrl.text.trim(),
                        aiEnabled: aiActive,
                        contactInformation: contactCtrl.text.trim(),
                        maintenanceMode: settings.maintenanceMode,
                      );
                      await _firestoreService.updateAppSettings(updated);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Portal settings updated successfully!'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    },
                    child: const Text('Save Configuration'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════ BOOKS TAB ══════════════════════
  Widget _buildBooksTab() {
    return StreamBuilder<List<BookModel>>(
      stream: _firestoreService.getBooks(),
      initialData: _firestoreService.getBooksSync(),
      builder: (context, snapshot) {
        final books = snapshot.data ?? const <BookModel>[];
        final courses = _firestoreService.getCoursesSync();

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to load books: ${snapshot.error}'),
            ),
          );
        }

        return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Reference Books & Study Materials',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Book'),
                    onPressed: () => _showAddBookDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (books.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No books added yet. Click "Add Book" to upload.')),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: books.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final b = books[index];
                    final course = courses.firstWhere(
                      (c) => c.id == b.courseId,
                      orElse: () => CourseModel(
                        id: '', title: 'General', description: '', imageUrl: '',
                        order: 0, isPublished: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
                      ),
                    );
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.menu_book, color: Colors.white, size: 28),
                        ),
                        title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${b.author}\nCourse: ${course.title}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                              tooltip: 'Delete Book',
                              onPressed: () async {
                                await _firestoreService.deleteBook(b.id);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        ),
      );
      },
    );
  }

  // ══════════════════════ PAST PAPERS TAB ══════════════════════
  Widget _buildPastPapersTab() {
    return StreamBuilder<List<PastPaperModel>>(
      stream: _firestoreService.getPastPapers(),
      initialData: _firestoreService.getPastPapersSync(),
      builder: (context, snapshot) {
        final papers = snapshot.data ?? const <PastPaperModel>[];
        final years = papers.map((paper) => paper.year).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to load past papers: ${snapshot.error}'),
            ),
          );
        }

        return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Past Papers Management',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Past Paper'),
                    onPressed: () => _showAddPastPaperDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (papers.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No past papers added yet.')),
                  ),
                )
              else
                ...years.map((year) {
                  final yearPapers = papers.where((pp) => pp.year == year).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12, top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
                        ),
                        child: Text(
                          'Academic Year $year — ${yearPapers.length} paper(s)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // Group by type
                      ..._buildPaperGroupRows(yearPapers, 'test1', 'Test 1', Colors.blue),
                      ..._buildPaperGroupRows(yearPapers, 'test2', 'Test 2', const Color(0xFF7C3AED)),
                      ..._buildPaperGroupRows(yearPapers, 'sessional', 'Sessional Exam', const Color(0xFF059669)),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
            ],
          ),
        ),
        ),
      );
      },
    );
  }

  List<Widget> _buildPaperGroupRows(List<PastPaperModel> papers, String type, String label, Color color) {
    final group = papers.where((pp) => pp.type == type).toList();
    if (group.isEmpty) return [];

    return group.map((pp) => Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.picture_as_pdf, color: color, size: 24),
        ),
        title: Text(pp.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('$label • ${pp.year}\n${pp.description}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
          onPressed: () async {
            await _firestoreService.deletePastPaper(pp.id);
            setState(() {});
          },
        ),
      ),
    )).toList();
  }

  // ══════════════════════ USERS TAB ══════════════════════
  Future<void> _activateStudentWithOneMonthAccess(
    UserModel user, {
    bool reactivate = false,
  }) async {
    if (_activatingUserIds.contains(user.uid)) return;
    setState(() => _activatingUserIds.add(user.uid));

    try {
      if (reactivate) {
        await _authService.reactivateAccount(user.uid);
      }

      final admin = _authService.currentUser;
      final now = DateTime.now();
      await _firestoreService.activateSubscription(
        userId: user.uid,
        paymentReference: 'admin_granted_30_days_${now.millisecondsSinceEpoch}',
        amount: 0,
        approvedBy: admin?.email ?? admin?.uid ?? 'admin',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user.name} now has full learning access for 30 days.',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not activate ${user.name}: $error'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _activatingUserIds.remove(user.uid));
      }
    }
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Read the live Firebase users collection directly. This makes the
      // dashboard independent of the AuthService in-memory cache.
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load users from Firebase. Check the admin account role and Firestore users read rules.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorRed),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allUsers = snapshot.data!.docs
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .where((user) => user.role != 'admin')
            .toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(2000))
              .compareTo(a.createdAt ?? DateTime(2000)));
        return _buildActiveUsersList(allUsers);
      },
    );
  }

  Widget _buildActiveUsersList(List<UserModel> allUsers) {
    final activeUsers = allUsers.where((u) => !u.isSuspended).toList();
    final suspendedCount = allUsers.where((u) => u.isSuspended).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Account Management',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activeUsers.length} active • $suspendedCount suspended',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (suspendedCount > 0)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                      ),
                      icon: const Icon(Icons.block, size: 16),
                      label: Text('View Suspended ($suspendedCount)'),
                      onPressed: () => _tabController.animateTo(6),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (activeUsers.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted),
                          SizedBox(height: 12),
                          Text('No active students registered yet.', style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeUsers.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = activeUsers[index];
                    final sub = _firestoreService.getSubscriptionSync(u.uid);
                    final hasActiveSub = sub != null &&
                        sub.status == 'active' &&
                        sub.expiryDate.isAfter(DateTime.now());

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                              child: Text(
                                u.name.isNotEmpty ? u.name[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.darkNavy,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    u.email,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (u.phoneNumber != null && u.phoneNumber!.isNotEmpty)
                                    Text('📱 ${u.phoneNumber}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (u.year != null)
                                        _buildChip(u.year!, const Color(0xFF2563EB)),
                                      if (u.program != null)
                                        _buildChip(u.program!, const Color(0xFF7C3AED)),
                                      _buildChip(
                                        hasActiveSub ? 'Subscribed ✓' : 'No Subscription',
                                        hasActiveSub ? AppTheme.successGreen : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Admin can grant or renew a full 30-day pass directly.
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 11),
                                  ),
                                  icon: _activatingUserIds.contains(u.uid)
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.lock_open, size: 14),
                                  label: Text(
                                    _activatingUserIds.contains(u.uid)
                                        ? 'Activating'
                                        : 'Activate 30 days',
                                  ),
                                  onPressed: _activatingUserIds.contains(u.uid)
                                      ? null
                                      : () => _activateStudentWithOneMonthAccess(u),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.errorRed,
                                    side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.6)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 11),
                                  ),
                                  icon: const Icon(Icons.block, size: 14),
                                  label: const Text('Suspend'),
                                  onPressed: () => _showSuspendUserDialog(u.uid, u.name),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  }

  // ══════════════════════ SUSPENDED USERS TAB ══════════════════════
  Widget _buildSuspendedUsersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load suspended users from Firebase: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorRed),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final suspendedUsers = snapshot.data!.docs
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .where((user) => user.role != 'admin' && user.isSuspended)
            .toList();
        return _buildSuspendedUsersList(suspendedUsers);
      },
    );
  }

  Widget _buildSuspendedUsersList(List<UserModel> suspendedUsers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.errorRed, const Color(0xFF7F1D1D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gavel, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terms & Conditions Enforcement',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${suspendedUsers.length} account(s) suspended. Review violations and activate eligible accounts.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (suspendedUsers.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.verified_user_outlined, size: 64, color: AppTheme.successGreen),
                          SizedBox(height: 16),
                          Text(
                            'No suspended accounts',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All students are in good standing with the Terms & Conditions.',
                            style: TextStyle(color: AppTheme.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suspendedUsers.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final u = suspendedUsers[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.35), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: avatar + info + status chip
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppTheme.errorRed.withValues(alpha: 0.12),
                                  child: Text(
                                    u.name.isNotEmpty ? u.name[0].toUpperCase() : 'S',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppTheme.errorRed,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              u.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppTheme.darkNavy,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.errorRed,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'SUSPENDED',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        u.email,
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (u.phoneNumber != null && u.phoneNumber!.isNotEmpty)
                                        Text('📱 ${u.phoneNumber}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (u.year != null) _buildChip(u.year!, const Color(0xFF2563EB)),
                                          if (u.program != null) _buildChip(u.program!, const Color(0xFF7C3AED)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Suspension reason box
                            if (u.suspensionReason != null && u.suspensionReason!.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        size: 18, color: AppTheme.errorRed),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Violation Reason:',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.errorRed,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            u.suspensionReason!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF7F1D1D),
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (u.suspendedAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Suspended on: ${u.suspendedAt!.toLocal().toString().substring(0, 16)}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                            const SizedBox(height: 14),
                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline, size: 16),
                                  label: const Text('Activate Account'),
                                  onPressed: _activatingUserIds.contains(u.uid)
                                      ? null
                                      : () => _activateStudentWithOneMonthAccess(
                                            u,
                                            reactivate: true,
                                          ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  }

  /// Small info chip helper
  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // ══════════════════════ DIALOGS ══════════════════════
  void _showAddBookDialog() {
    final courses = _firestoreService.getCoursesSync();
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a course before adding books.')),
      );
      return;
    }

    String selectedCourse = courses.first.id;
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Reference Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCourse,
                  decoration: const InputDecoration(labelText: 'Assign to Course'),
                  items: courses
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.title)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCourse = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Book Title')),
                const SizedBox(height: 12),
                TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author(s)')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(controller: urlCtrl, decoration: const InputDecoration(
                  labelText: 'GitHub Raw PDF URL',
                  hintText: 'https://raw.githubusercontent.com/USER/REPO/main/books/book.pdf',
                  helperText: 'Paste the direct Raw URL of a .pdf file. Existing Firebase Storage gs:// links remain supported during migration.',
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
              onPressed: () async {
                final pdfUri = Uri.tryParse(urlCtrl.text.trim());
                if (titleCtrl.text.trim().isEmpty ||
                    pdfUri == null || !_isSupportedLearningPdfUrl(urlCtrl.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter the book title and a valid GitHub Raw PDF URL (or existing learning_materials gs:// URL).'),
                    ),
                  );
                  return;
                }
                if (titleCtrl.text.trim().isNotEmpty) {
                  final book = BookModel(
                    id: 'book_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    author: authorCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    courseId: selectedCourse,
                    fileUrl: urlCtrl.text.trim(),
                    isPublished: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  try {
                    await _firestoreService.saveBook(book);
                    if (!mounted) return;
                    setState(() {});
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Book uploaded successfully.')),
                    );
                  } catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not upload book: $error')),
                    );
                  }
                }
              },
              child: const Text('Save Book', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPastPaperDialog() {
    final courses = _firestoreService.getCoursesSync();
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a course before adding past papers.')),
      );
      return;
    }

    String selectedCourse = courses.first.id;
    String selectedType = 'test1';
    final yearCtrl = TextEditingController(
        text: DateTime.now().year.toString());
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    const typeOptions = [
      ('test1', 'Test 1'),
      ('test2', 'Test 2'),
      ('sessional', 'Sessional Exam'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Past Paper'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCourse,
                  decoration: const InputDecoration(labelText: 'Assign to Course'),
                  items: courses
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.title)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCourse = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Paper Type'),
                  items: typeOptions
                      .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Academic Year (e.g. 2024)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Paper Title')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(controller: urlCtrl, decoration: const InputDecoration(
                  labelText: 'GitHub Raw PDF URL',
                  hintText: 'https://raw.githubusercontent.com/USER/REPO/main/past-papers/paper.pdf',
                  helperText: 'Paste the direct Raw URL of a .pdf file. The app checks subscription access before showing the document.',
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              onPressed: () async {
                final pdfUri = Uri.tryParse(urlCtrl.text.trim());
                if (titleCtrl.text.trim().isEmpty ||
                    yearCtrl.text.trim().isEmpty ||
                    pdfUri == null ||
                    !_isSupportedLearningPdfUrl(urlCtrl.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter the paper title, academic year, and a valid GitHub Raw PDF URL (or existing learning_materials gs:// URL).'),
                    ),
                  );
                  return;
                }
                if (titleCtrl.text.trim().isNotEmpty && yearCtrl.text.trim().isNotEmpty) {
                  final paper = PastPaperModel(
                    id: 'pp_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    year: yearCtrl.text.trim(),
                    type: selectedType,
                    courseId: selectedCourse,
                    fileUrl: urlCtrl.text.trim(),
                    isPublished: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  try {
                    await _firestoreService.savePastPaper(paper);
                    if (!mounted) return;
                    setState(() {});
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Past paper uploaded successfully.')),
                    );
                  } catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not upload past paper: $error')),
                    );
                  }
                }
              },
              child: const Text('Save Paper', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCourseDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final programmeCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: 'Year 1');
    final semesterCtrl = TextEditingController(text: 'Semester 1');
    final orderCtrl = TextEditingController(text: '${_firestoreService.getCoursesSync().length + 1}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Engineering Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Course / Topic Group Title')),
            const SizedBox(height: 12),
            TextField(controller: programmeCtrl, decoration: const InputDecoration(labelText: 'Programme (e.g. Mechanical Engineering)')),
            const SizedBox(height: 12),
            TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Study Year (e.g. Year 1)')),
            const SizedBox(height: 12),
            TextField(controller: semesterCtrl, decoration: const InputDecoration(labelText: 'Semester (e.g. Semester 1)')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: orderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Order Index')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty ||
                  programmeCtrl.text.trim().isEmpty ||
                  yearCtrl.text.trim().isEmpty ||
                  semesterCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter the topic title, programme, study year and semester.'),
                  ),
                );
                return;
              }
              final course = CourseModel(
                  id: 'course_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  imageUrl: '',
                  programme: programmeCtrl.text.trim(),
                  year: yearCtrl.text.trim(),
                  semester: semesterCtrl.text.trim(),
                  order: int.tryParse(orderCtrl.text.trim()) ?? 1,
                  isPublished: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await _firestoreService.saveCourse(course);
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save Course'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(CourseModel course) {
    final titleCtrl = TextEditingController(text: course.title);
    final descCtrl = TextEditingController(text: course.description);
    final programmeCtrl = TextEditingController(text: course.programme);
    final yearCtrl = TextEditingController(text: course.year);
    final semesterCtrl = TextEditingController(text: course.semester);
    final orderCtrl = TextEditingController(text: course.order.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Course Organisation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Topic Group Title')),
              const SizedBox(height: 12),
              TextField(controller: programmeCtrl, decoration: const InputDecoration(labelText: 'Programme')),
              const SizedBox(height: 12),
              TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Study Year')),
              const SizedBox(height: 12),
              TextField(controller: semesterCtrl, decoration: const InputDecoration(labelText: 'Semester')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(controller: orderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Order Index')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty ||
                  programmeCtrl.text.trim().isEmpty ||
                  yearCtrl.text.trim().isEmpty ||
                  semesterCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter the topic title, programme, study year and semester.'),
                  ),
                );
                return;
              }
              final updated = CourseModel(
                id: course.id,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                imageUrl: course.imageUrl,
                programme: programmeCtrl.text.trim(),
                year: yearCtrl.text.trim(),
                semester: semesterCtrl.text.trim(),
                order: int.tryParse(orderCtrl.text.trim()) ?? course.order,
                isPublished: course.isPublished,
                createdAt: course.createdAt,
                updatedAt: DateTime.now(),
              );
              try {
                await _firestoreService.updateCourse(updated);
                if (mounted) setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not update course: $error')),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showAddVideoDialog({String? preselectedCourseId}) {
    final courses = _firestoreService.getCoursesSync();
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a course before adding video lessons.')),
      );
      return;
    }

    String selectedCourse = preselectedCourseId ?? courses.first.id;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ytCtrl = TextEditingController();
    final thumbnailCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Video Lesson'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCourse,
                  decoration: const InputDecoration(labelText: 'Assign to Course'),
                  items: courses.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.title));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCourse = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Topic / Lesson Title')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Lesson Description')),
                const SizedBox(height: 12),
                TextField(controller: ytCtrl, decoration: const InputDecoration(labelText: 'YouTube Video URL or ID', hintText: 'https://www.youtube.com/watch?v=...')),
                const SizedBox(height: 12),
                TextField(
                  controller: thumbnailCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Topic Cover Image URL',
                    hintText: 'https://example.com/topic-cover.jpg',
                    helperText: 'Required: add an image that represents this lesson topic.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: orderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lesson Order')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final coverUri = Uri.tryParse(thumbnailCtrl.text.trim());
                final videoInput = ytCtrl.text.trim();
                final parsedVideoId = YoutubePlayer.convertUrlToId(videoInput) ?? videoInput;
                if (titleCtrl.text.trim().isEmpty ||
                    parsedVideoId.isEmpty ||
                    coverUri == null ||
                    !coverUri.hasScheme ||
                    !['http', 'https'].contains(coverUri.scheme) ||
                    coverUri.host.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a lesson title, valid YouTube URL or video ID, and a valid HTTP/HTTPS topic cover image URL.'),
                    ),
                  );
                  return;
                }
                if (titleCtrl.text.trim().isNotEmpty) {
                  final video = VideoModel(
                    id: 'vid_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    youtubeVideoId: parsedVideoId,
                    thumbnailUrl: thumbnailCtrl.text.trim(),
                    courseId: selectedCourse,
                    order: int.tryParse(orderCtrl.text.trim()) ?? 1,
                    isPublished: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  try {
                    await _firestoreService.saveVideo(video);
                    if (!mounted) return;
                    setState(() {});
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Video lesson uploaded successfully.')),
                    );
                  } catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not upload video lesson: $error')),
                    );
                  }
                }
              },
              child: const Text('Save Lesson'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuspendUserDialog(String uid, String userName) {
    const tcReasons = [
      'Unauthorized sharing of account credentials with another user.',
      'Attempting to screen-record or extract protected course materials.',
      'Unauthorized redistribution or uploading of platform content.',
      'Abusive or inappropriate behavior reported by other users.',
      'Payment fraud or chargebacks detected.',
      'Violation of academic integrity policies.',
    ];
    String selectedReason = tcReasons.first;
    final customCtrl = TextEditingController();
    bool useCustom = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gavel, color: AppTheme.errorRed, size: 20),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Suspend $userName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Signing in on multiple devices owned or used by the same student is allowed and is never a reason for suspension. This action is reserved for other serious policy violations.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Violation:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Write custom reason', style: TextStyle(fontSize: 13)),
                  value: useCustom,
                  onChanged: (v) => setDialogState(() => useCustom = v),
                ),
                if (useCustom)
                  TextField(
                    controller: customCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe the specific Terms & Conditions violation...',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  ...tcReasons.map((reason) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: AppTheme.errorRed,
                        title: Text(reason, style: const TextStyle(fontSize: 12)),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedReason = v);
                        },
                      )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.block, size: 16),
              label: const Text('Suspend Account'),
              onPressed: () async {
                final reason = useCustom
                    ? customCtrl.text.trim()
                    : selectedReason;
                if (reason.isEmpty) return;
                await _authService.suspendUser(uid, reason: reason);
                setState(() {});
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$userName\'s account has been suspended.'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                // Navigate to Suspended tab to review
                _tabController.animateTo(6);
              },
            ),
          ],
        ),
      ),
    );
  }
}