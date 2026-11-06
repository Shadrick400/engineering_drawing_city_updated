import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:engineering_drawing_city/models/app_settings_model.dart';
import 'package:engineering_drawing_city/models/book_model.dart';
import 'package:engineering_drawing_city/models/course_model.dart';
import 'package:engineering_drawing_city/models/past_paper_model.dart';
import 'package:engineering_drawing_city/models/payment_model.dart';
import 'package:engineering_drawing_city/models/subscription_model.dart';
import 'package:engineering_drawing_city/models/user_model.dart';
import 'package:engineering_drawing_city/models/video_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeSeedUsers();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;

  final StreamController<UserModel?> _userStreamController =
      StreamController<UserModel?>.broadcast();

  UserModel? get currentUser => _currentUser;
  Stream<UserModel?> get authStateChanges => _userStreamController.stream;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  final Map<String, UserModel> _usersDb = {};
  final Map<String, String> _passwordsDb = {};

  // Real admin credentials
  static const String _adminEmail = 'engineeringdrawingcity400@gmail.com';
  static const String _adminPassword = 'kondwani1964#';

  void _initializeSeedUsers() {
    // Seed Admin account (real credentials)
    final admin = UserModel(
      uid: 'admin_01',
      email: _adminEmail,
      name: 'EDC Administrator',
      role: 'admin',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    );
    _usersDb[admin.uid] = admin;
    _usersDb[admin.email.toLowerCase()] = admin;
    _passwordsDb[admin.email.toLowerCase()] = _adminPassword;

    // Seed student accounts with varying states including Terms & Conditions violations
    final student1 = UserModel(
      uid: 'student_01',
      email: 'mwila.chanda@cbu.ac.zm',
      name: 'Mwila Chanda',
      role: 'student',
      year: 'Year 2',
      program: 'Mechanical Engineering',
      institution: 'The Copperbelt University',
      phoneNumber: '+260 971 234567',
      deviceId: 'device_cbu_01',
      isSuspended: false,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    );
    _usersDb[student1.uid] = student1;
    _usersDb[student1.email.toLowerCase()] = student1;
    _passwordsDb[student1.email.toLowerCase()] = 'student123';

    final student2 = UserModel(
      uid: 'student_02',
      email: 'kondwani.banda@unza.zm',
      name: 'Kondwani Banda',
      role: 'student',
      year: 'Year 3',
      program: 'Civil Engineering',
      institution: 'University of Zambia (UNZA)',
      phoneNumber: '+260 962 345678',
      deviceId: 'device_unza_02',
      isSuspended: true,
      suspensionReason: 'Terms & Conditions Violation: Unauthorized multi-device concurrent streaming detected (Section 4.1).',
      suspendedAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    _usersDb[student2.uid] = student2;
    _usersDb[student2.email.toLowerCase()] = student2;
    _passwordsDb[student2.email.toLowerCase()] = 'student123';

    final student3 = UserModel(
      uid: 'student_03',
      email: 'chileshe.phiri@ehc.edu.zm',
      name: 'Chileshe Phiri',
      role: 'student',
      year: 'Year 1',
      program: 'Electrical & Electronics',
      institution: 'Evelyn Hone College',
      phoneNumber: '+260 771 890123',
      deviceId: 'device_ehc_03',
      isSuspended: true,
      suspensionReason: 'Terms & Conditions Violation: Attempted screen-recording & unauthorized file extraction of technical drawing materials.',
      suspendedAt: DateTime.now().subtract(const Duration(hours: 18)),
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 18)),
    );
    _usersDb[student3.uid] = student3;
    _usersDb[student3.email.toLowerCase()] = student3;
    _passwordsDb[student3.email.toLowerCase()] = 'student123';

    final student4 = UserModel(
      uid: 'student_04',
      email: 'natasha.tembo@mu.ac.zm',
      name: 'Natasha Tembo',
      role: 'student',
      year: 'Year 2',
      program: 'Geomatic Engineering',
      institution: 'Mulungushi University',
      phoneNumber: '+260 955 456789',
      deviceId: 'device_mu_04',
      isSuspended: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    );
    _usersDb[student4.uid] = student4;
    _usersDb[student4.email.toLowerCase()] = student4;
    _passwordsDb[student4.email.toLowerCase()] = 'student123';

    // No auto-login — users must sign in explicitly
    _currentUser = null;
    _userStreamController.add(null);
  }

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    if (user != null) {
      _usersDb[user.uid] = user;
      _usersDb[user.email.toLowerCase()] = user;
    }
    _userStreamController.add(_currentUser);
  }

  /// Simulated device fingerprint (in production use device_info_plus package)
  String _getDeviceId() {
    // In real implementation: use device_info_plus to get a unique device ID
    // For demo we use a fixed string per app install session
    return 'device_${DateTime.now().day}_${DateTime.now().month}';
  }

  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // 1. Check real admin credentials first (no network needed)
    if (cleanEmail == _adminEmail.toLowerCase() && cleanPassword == _adminPassword) {
      final admin = _usersDb[cleanEmail] ?? UserModel(
        uid: 'admin_01',
        email: cleanEmail,
        name: 'EDC Administrator',
        role: 'admin',
        createdAt: DateTime.now(),
      );
      _usersDb[admin.uid] = admin;
      _usersDb[cleanEmail] = admin;
      _currentUser = admin;
      _userStreamController.add(_currentUser);
      return admin;
    }

    // 2. Try Firebase Auth for real registered users
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: cleanPassword,
      );
      if (cred.user != null) {
        final existing = _usersDb[cred.user!.uid];
        if (existing != null) {
          // Device lock check
          final currentDeviceId = _getDeviceId();
          if (existing.deviceId != null &&
              existing.deviceId!.isNotEmpty &&
              existing.deviceId != currentDeviceId) {
            // Suspend account – device changed / terms violation
            final suspended = existing.copyWith(
              isSuspended: true,
              suspensionReason: 'Terms & Conditions Violation: Login detected from a new/unauthorized device without prior reset approval.',
              suspendedAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            _usersDb[suspended.uid] = suspended;
            _usersDb[cleanEmail] = suspended;
            throw Exception(
                'ACCOUNT_SUSPENDED: This account has been suspended because a login was detected from an unrecognized device in violation of single-device terms. '
                'Please contact administrator or support at +260 772 184445 for reactivation.');
          }
          if (existing.isSuspended) {
            final reason = existing.suspensionReason ?? 'Violation of Terms and Conditions';
            throw Exception(
                'ACCOUNT_SUSPENDED: Your account is currently suspended.\nReason: $reason\n'
                'Please contact administrator at +260 772 184445 to request account reactivation.');
          }
          _currentUser = existing;
        } else {
          _currentUser = UserModel(
            uid: cred.user!.uid,
            email: cred.user!.email ?? cleanEmail,
            name: cred.user!.displayName ?? cleanEmail.split('@').first,
            role: 'student',
            deviceId: _getDeviceId(),
            createdAt: DateTime.now(),
          );
          _usersDb[_currentUser!.uid] = _currentUser!;
          _usersDb[cleanEmail] = _currentUser!;
        }
        _userStreamController.add(_currentUser);
        return _currentUser!;
      }
    } catch (e) {
      if (e.toString().contains('ACCOUNT_SUSPENDED')) rethrow;
      debugPrint('Firebase Auth signIn fallback to local store: $e');
    }

    // 3. Check local registered users (with password match if stored)
    if (_usersDb.containsKey(cleanEmail)) {
      final storedPassword = _passwordsDb[cleanEmail];
      if (storedPassword == null || storedPassword == cleanPassword) {
        final user = _usersDb[cleanEmail]!;

        // Device lock check for local users
        final currentDeviceId = _getDeviceId();
        if (user.deviceId != null &&
            user.deviceId!.isNotEmpty &&
            user.deviceId != currentDeviceId) {
          final suspended = user.copyWith(
            isSuspended: true,
            suspensionReason: 'Terms & Conditions Violation: Login detected from an unrecognized device in violation of single-device policy.',
            suspendedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _usersDb[suspended.uid] = suspended;
          _usersDb[cleanEmail] = suspended;
          throw Exception(
              'ACCOUNT_SUSPENDED: This account has been suspended because a login was detected from a new device. '
              'Please contact customer care at +260 772 184445 for reactivation.');
        }
        if (user.isSuspended) {
          final reason = user.suspensionReason ?? 'Violation of Terms and Conditions';
          throw Exception(
              'ACCOUNT_SUSPENDED: Your account is currently suspended.\nReason: $reason\n'
              'Please contact administrator at +260 772 184445 for reactivation.');
        }

        _currentUser = user;
        _userStreamController.add(_currentUser);
        return user;
      } else {
        throw Exception('Incorrect password. Please try again.');
      }
    }

    throw Exception('No account found for this email. Please register first.');
  }

  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    String? year,
    String? program,
    String? institution,
    String? phoneNumber,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Prevent admin email from registering as student
    if (cleanEmail == _adminEmail.toLowerCase()) {
      throw Exception('This email address is reserved. Please use a different email.');
    }

    // Check if already registered
    if (_usersDb.containsKey(cleanEmail)) {
      throw Exception('An account already exists with this email. Please sign in.');
    }

    final deviceId = _getDeviceId();

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (cred.user != null) {
        final userModel = UserModel(
          uid: cred.user!.uid,
          email: cleanEmail,
          name: name,
          role: 'student',
          year: year,
          program: program,
          institution: institution,
          phoneNumber: phoneNumber,
          deviceId: deviceId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _usersDb[userModel.uid] = userModel;
        _usersDb[cleanEmail] = userModel;
        _passwordsDb[cleanEmail] = password;
        _currentUser = userModel;
        _userStreamController.add(_currentUser);
        return userModel;
      }
    } catch (e) {
      debugPrint('Firebase Auth register fallback to local store: $e');
    }

    final userModel = UserModel(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      name: name,
      role: 'student',
      year: year,
      program: program,
      institution: institution,
      phoneNumber: phoneNumber,
      deviceId: deviceId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _usersDb[userModel.uid] = userModel;
    _usersDb[cleanEmail] = userModel;
    _passwordsDb[cleanEmail] = password;
    _currentUser = userModel;
    _userStreamController.add(_currentUser);

    return userModel;
  }

  /// Reactivate / Activate a suspended account (admin action)
  Future<void> reactivateAccount(String uid) async {
    final user = _usersDb[uid];
    if (user != null) {
      final reactivated = user.copyWith(
        isSuspended: false,
        clearSuspensionReason: true,
        deviceId: _getDeviceId(),
        updatedAt: DateTime.now(),
      );
      _usersDb[uid] = reactivated;
      _usersDb[reactivated.email.toLowerCase()] = reactivated;
      if (_currentUser?.uid == uid) {
        _currentUser = reactivated;
      }
      _userStreamController.add(_currentUser);
    }
  }

  /// Activate suspended user (alias for reactivateAccount)
  Future<void> activateUser(String uid) => reactivateAccount(uid);

  /// Suspend a user account for Terms & Conditions breach (admin action)
  Future<void> suspendUser(String uid, {required String reason}) async {
    final user = _usersDb[uid];
    if (user != null) {
      final suspended = user.copyWith(
        isSuspended: true,
        suspensionReason: reason,
        suspendedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _usersDb[uid] = suspended;
      _usersDb[suspended.email.toLowerCase()] = suspended;
      if (_currentUser?.uid == uid) {
        _currentUser = suspended;
      }
      _userStreamController.add(_currentUser);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _currentUser = null;
    _userStreamController.add(null);
  }

  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (_) {}
  }

  /// Get all users (for admin)
  List<UserModel> getAllUsers() {
    final seen = <String>{};
    return _usersDb.values.where((u) {
      if (seen.contains(u.uid)) return false;
      seen.add(u.uid);
      return true;
    }).toList();
  }
}

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initializeSeedData();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory data store with reactive StreamControllers
  final Map<String, CourseModel> _courses = {};
  final Map<String, VideoModel> _videos = {};
  final Map<String, BookModel> _books = {};
  final Map<String, PastPaperModel> _pastPapers = {};
  final Map<String, SubscriptionModel> _subscriptions = {};
  final Map<String, PaymentModel> _payments = {};
  final Map<String, UserModel> _users = {};
  late AppSettingsModel _appSettings;

  final StreamController<List<CourseModel>> _coursesController =
      StreamController<List<CourseModel>>.broadcast();
  final StreamController<List<VideoModel>> _videosController =
      StreamController<List<VideoModel>>.broadcast();
  final StreamController<List<BookModel>> _booksController =
      StreamController<List<BookModel>>.broadcast();
  final StreamController<List<PastPaperModel>> _pastPapersController =
      StreamController<List<PastPaperModel>>.broadcast();
  final StreamController<List<SubscriptionModel>> _subscriptionsController =
      StreamController<List<SubscriptionModel>>.broadcast();
  final StreamController<List<PaymentModel>> _paymentsController =
      StreamController<List<PaymentModel>>.broadcast();

  void _initializeSeedData() {
    // 1. App Settings
    _appSettings = AppSettingsModel(
      appName: 'Engineering Drawing City',
      logo: 'assets/images/logo.png',
      welcomeMessage:
          'Master Engineering Drawing, CAD & Technical Graphics with Pro Video Modules',
      paymentNumber: '0772184445',
      subscriptionPrice: 10.0,
      subscriptionDuration: '30 days',
      paymentInstructions:
          'Send \$10 via Mobile Money or Bank to 0772184445 (Name: Engineering Drawing City). Enter your Transaction ID/Reference below for immediate activation.',
      aiEnabled: true,
      contactInformation: 'support@drawingcity.com | Phone: +256 772 184445',
      maintenanceMode: false,
    );

    // 2. Courses
    final seedCourses = [
      CourseModel(
        id: 'course_01',
        title: 'Fundamentals of Engineering Drawing',
        description:
            'Drawing instruments, standard sheet sizes (A0-A4), title blocks, line types, lettering, and plain & diagonal scales.',
        imageUrl: '',
        order: 1,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      CourseModel(
        id: 'course_02',
        title: 'Orthographic Projections Masterclass',
        description:
            'First Angle and Third Angle projection rules, principal planes of projection, front/top/side views of solids and brackets.',
        imageUrl: '',
        order: 2,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
        updatedAt: DateTime.now(),
      ),
      CourseModel(
        id: 'course_03',
        title: 'Isometric & Axonometric Drawing',
        description:
            'Isometric axes at 30°, box construction method, 4-centre method for isometric circles and ellipses, oblique views.',
        imageUrl: '',
        order: 3,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      CourseModel(
        id: 'course_04',
        title: 'Sectional Views & Conic Sections',
        description:
            'Cutting planes, full sections, half sections, offset sections, hatching conventions, and drawing ellipses and parabolas.',
        imageUrl: '',
        order: 4,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      CourseModel(
        id: 'course_05',
        title: 'Machine Drawing, GD&T & CAD Essentials',
        description:
            'Thread profiles, bolts and nuts, limits, fits and tolerances, GD&T symbols, and introduction to 2D CAD drafting.',
        imageUrl: '',
        order: 5,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
    ];

    for (var c in seedCourses) {
      _courses[c.id] = c;
    }

    // 3. Videos
    final seedVideos = [
      // Course 1
      VideoModel(
        id: 'vid_01',
        title: '1. Drafting Instruments & Drawing Sheet Setup',
        description:
            'Complete breakdown of T-squares, set-squares, compasses, sheet layouts, and standard title blocks.',
        youtubeVideoId: 'WkL3SfvWz1U',
        thumbnailUrl: '',
        courseId: 'course_01',
        order: 1,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 29)),
        updatedAt: DateTime.now(),
      ),
      VideoModel(
        id: 'vid_02',
        title: '2. Standard Engineering Lines & Lettering',
        description:
            'Continuous thick/thin lines, hidden lines, centre lines, cutting planes, and single-stroke vertical gothic lettering.',
        youtubeVideoId: '9Z9-p97U8vE',
        thumbnailUrl: '',
        courseId: 'course_01',
        order: 2,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
        updatedAt: DateTime.now(),
      ),
      VideoModel(
        id: 'vid_03',
        title: '3. Plain Scales and Diagonal Scales Worked Examples',
        description:
            'Constructing plain scales and diagonal scales to read 3 units (e.g., metres, decimetres, centimetres).',
        youtubeVideoId: 'N1rE7y2aL5Q',
        thumbnailUrl: '',
        courseId: 'course_01',
        order: 3,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 27)),
        updatedAt: DateTime.now(),
      ),

      // Course 2
      VideoModel(
        id: 'vid_04',
        title: '1. First Angle vs Third Angle Projection Concepts',
        description:
            'Why 1st angle places views opposite to observer and 3rd angle maintains view alignment. Standard symbols.',
        youtubeVideoId: 'l9iWp0m4_Q4',
        thumbnailUrl: '',
        courseId: 'course_02',
        order: 1,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      VideoModel(
        id: 'vid_05',
        title: '2. Orthographic Projection Problem 1 - Stepped Block',
        description:
            'Projecting Front View, Top View and Right Side View for a standard 3D block step-by-step.',
        youtubeVideoId: '7Y3o3k3g1aE',
        thumbnailUrl: '',
        courseId: 'course_02',
        order: 2,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 24)),
        updatedAt: DateTime.now(),
      ),
      VideoModel(
        id: 'vid_06',
        title: '3. Orthographic Projection Problem 2 - Slanted Faces & Holes',
        description:
            'Dealing with incline surfaces, true lengths, and drawing hidden circular holes accurately.',
        youtubeVideoId: 'yM9hD6L3q0M',
        thumbnailUrl: '',
        courseId: 'course_02',
        order: 3,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 23)),
        updatedAt: DateTime.now(),
      ),

      // Course 3
      VideoModel(
        id: 'vid_07',
        title: '1. Isometric Projection Principles & The Box Method',
        description:
            'Establishing the 30-degree isometric axes and enclosing irregular machine parts within a reference bounding box.',
        youtubeVideoId: 'fW_F4Wn11b8',
        thumbnailUrl: '',
        courseId: 'course_03',
        order: 1,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      VideoModel(
        id: 'vid_08',
        title: '2. Drawing Isometric Circles with the Four-Centre Method',
        description:
            'Mastering the rhombus technique and four arc centers to draw perfect isometric ellipses on all planes.',
        youtubeVideoId: '8K8wK_jGq1g',
        thumbnailUrl: '',
        courseId: 'course_03',
        order: 2,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 19)),
        updatedAt: DateTime.now(),
      ),

      // Course 4
      VideoModel(
        id: 'vid_09',
        title: '1. Full Sectional Views & Hatching Standards',
        description:
            'Cutting plane representation, cross-hatching angle (45 degrees), pitch spacing, and sectioning thin ribs.',
        youtubeVideoId: '2kY9k1P5_zM',
        thumbnailUrl: '',
        courseId: 'course_04',
        order: 1,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      VideoModel(
        id: 'vid_10',
        title: '2. Half Sectional & Offset Section Techniques',
        description:
            'Revealing internal symmetrical features alongside external appearance on hollow machine components.',
        youtubeVideoId: 'uP7rS8e01Xk',
        thumbnailUrl: '',
        courseId: 'course_04',
        order: 2,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        updatedAt: DateTime.now(),
      ),

      // Course 5
      VideoModel(
        id: 'vid_11',
        title: '1. Limits, Fits & Tolerances in Machine Drawing',
        description:
            'Hole basis vs shaft basis systems, clearance fits, transition fits, interference fits, and ISO tolerance grades.',
        youtubeVideoId: 'qZ3c8L1e5_8',
        thumbnailUrl: '',
        courseId: 'course_05',
        order: 1,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      VideoModel(
        id: 'vid_12',
        title: '2. GD&T Symbols, Datums & Feature Control Frames',
        description:
            'Geometric Dimensioning & Tolerancing (GD&T): Form, Orientation, Location, and Runout tolerances.',
        youtubeVideoId: 'dK4n8L0w9_M',
        thumbnailUrl: '',
        courseId: 'course_05',
        order: 2,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
        updatedAt: DateTime.now(),
      ),
      VideoModel(
        id: 'vid_13',
        title: '3. Introduction to AutoCAD 2D Drafting for Students',
        description:
            'Layers, object snaps, polar tracking, dimension styles, and plotting drawing sheets to scale.',
        youtubeVideoId: 'aM8c9V1x4_A',
        thumbnailUrl: '',
        courseId: 'course_05',
        order: 3,
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now(),
      ),
    ];

    for (var v in seedVideos) {
      _videos[v.id] = v;
    }

    // 4. Seed Books
    final seedBooks = [
      BookModel(
        id: 'book_01',
        title: 'Engineering Drawing (N.D. Bhatt)',
        author: 'N.D. Bhatt & V.M. Panchal',
        description:
            'The classic reference for engineering drawing covering all fundamentals, orthographic projections, and machine drawing in detail.',
        courseId: 'course_01',
        fileUrl: 'https://drive.google.com/file/d/sample_bhatt',
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: 'book_02',
        title: 'Engineering Graphics with AutoCAD',
        author: 'James D. Bethune',
        description:
            'Integrates 2D and 3D CAD with traditional engineering graphics principles. Covers projections, sections, and GD&T.',
        courseId: 'course_05',
        fileUrl: 'https://drive.google.com/file/d/sample_autocad',
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now(),
      ),
      BookModel(
        id: 'book_03',
        title: 'Fundamentals of Technical Drawing',
        author: 'Giesecke et al.',
        description:
            'Comprehensive textbook covering lines, lettering, geometric constructions, orthographic and isometric views.',
        courseId: 'course_02',
        fileUrl: 'https://drive.google.com/file/d/sample_giesecke',
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
    ];

    for (var b in seedBooks) {
      _books[b.id] = b;
    }

    // 5. Seed Past Papers
    final seedPastPapers = [
      PastPaperModel(
        id: 'pp_01',
        title: 'Test 1 – 2023 (Fundamentals)',
        description: 'Drawing instruments, line types, and plain scales.',
        year: '2023',
        type: 'test1',
        courseId: 'course_01',
        fileUrl: 'https://drive.google.com/file/d/sample_test1_2023',
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      PastPaperModel(
        id: 'pp_02',
        title: 'Test 2 – 2023 (Projections)',
        description: 'First and third angle projections problems.',
        year: '2023',
        type: 'test2',
        courseId: 'course_02',
        fileUrl: 'https://drive.google.com/file/d/sample_test2_2023',
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 350)),
        updatedAt: DateTime.now(),
      ),
      PastPaperModel(
        id: 'pp_03',
        title: 'Sessional Exam – 2023',
        description: 'Full course sessional examination covering all topics.',
        year: '2023',
        type: 'sessional',
        courseId: 'course_01',
        fileUrl: 'https://drive.google.com/file/d/sample_sessional_2023',
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 330)),
        updatedAt: DateTime.now(),
      ),
      PastPaperModel(
        id: 'pp_04',
        title: 'Test 1 – 2024 (Fundamentals)',
        description: 'Drawing standards, title blocks, and lettering.',
        year: '2024',
        type: 'test1',
        courseId: 'course_01',
        fileUrl: 'https://drive.google.com/file/d/sample_test1_2024',
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now(),
      ),
      PastPaperModel(
        id: 'pp_05',
        title: 'Test 2 – 2024 (Isometric)',
        description: 'Isometric box method and four-centre ellipse exercises.',
        year: '2024',
        type: 'test2',
        courseId: 'course_03',
        fileUrl: 'https://drive.google.com/file/d/sample_test2_2024',
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 165)),
        updatedAt: DateTime.now(),
      ),
      PastPaperModel(
        id: 'pp_06',
        title: 'Sessional Exam – 2024',
        description: 'Full sessional covering orthographic, isometric, and sectioning.',
        year: '2024',
        type: 'sessional',
        courseId: 'course_02',
        fileUrl: 'https://drive.google.com/file/d/sample_sessional_2024',
        isPublished: true,
        createdAt: DateTime.now().subtract(const Duration(days: 140)),
        updatedAt: DateTime.now(),
      ),
    ];

    for (var pp in seedPastPapers) {
      _pastPapers[pp.id] = pp;
    }

    // 6. Initial Subscriptions
    final activeSub = SubscriptionModel(
      id: 'sub_student_01',
      userId: 'student_01',
      status: 'active',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      expiryDate: DateTime.now().add(const Duration(days: 25)),
      amount: 10.0,
      paymentReference: 'MM-TXN-8849201',
      approvedBy: 'admin_01',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    );
    _subscriptions[activeSub.userId] = activeSub;

    // 7. Seed Payments
    final pendingPayment = PaymentModel(
      id: 'pay_001',
      userId: 'student_01',
      amount: 10.0,
      paymentReference: 'MM-REF-9923841',
      status: 'pending',
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
    _payments[pendingPayment.id] = pendingPayment;

    final approvedPayment = PaymentModel(
      id: 'pay_002',
      userId: 'student_01',
      amount: 10.0,
      paymentReference: 'MM-TXN-8849201',
      status: 'approved',
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 5)),
      reviewedBy: 'admin_01',
    );
    _payments[approvedPayment.id] = approvedPayment;
  }

  // ================= USERS =================
  Future<void> saveUser(UserModel user) async {
    _users[user.uid] = user;
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (_) {}
  }

  Stream<UserModel?> getUser(String uid) {
    if (_users.containsKey(uid)) {
      return Stream.value(_users[uid]);
    }
    final user = AuthService().currentUser;
    if (user != null && user.uid == uid) {
      return Stream.value(user);
    }
    return Stream.value(null);
  }

  // ================= COURSES =================
  Future<void> saveCourse(CourseModel course) async {
    _courses[course.id] = course;
    _coursesController.add(_courses.values.toList()..sort((a, b) => a.order.compareTo(b.order)));
    try {
      await _db.collection('courses').doc(course.id).set(course.toMap());
    } catch (_) {}
  }

  Stream<List<CourseModel>> getCourses() {
    final list = _courses.values.toList()..sort((a, b) => a.order.compareTo(b.order));
    return _coursesController.stream.transform(
      StreamTransformer<List<CourseModel>, List<CourseModel>>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
      ),
    ).asBroadcastStream(
      onListen: (subscription) {
        _coursesController.add(list);
      },
    );
  }

  List<CourseModel> getCoursesSync() {
    return _courses.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<CourseModel?> getCourse(String courseId) async {
    return _courses[courseId];
  }

  Future<void> updateCourse(CourseModel course) async {
    _courses[course.id] = course;
    _coursesController.add(_courses.values.toList()..sort((a, b) => a.order.compareTo(b.order)));
    try {
      await _db.collection('courses').doc(course.id).update(course.toMap());
    } catch (_) {}
  }

  Future<void> deleteCourse(String courseId) async {
    _courses.remove(courseId);
    _coursesController.add(_courses.values.toList()..sort((a, b) => a.order.compareTo(b.order)));
    try {
      await _db.collection('courses').doc(courseId).delete();
    } catch (_) {}
  }

  // ================= VIDEOS =================
  Future<void> saveVideo(VideoModel video) async {
    _videos[video.id] = video;
    _videosController.add(_videos.values.toList()..sort((a, b) => a.order.compareTo(b.order)));
    try {
      await _db.collection('videos').doc(video.id).set(video.toMap());
    } catch (_) {}
  }

  Stream<List<VideoModel>> getVideos() {
    final list = _videos.values.toList()..sort((a, b) => a.order.compareTo(b.order));
    return _videosController.stream.asBroadcastStream(
      onListen: (sub) {
        _videosController.add(list);
      },
    );
  }

  List<VideoModel> getVideosSync() {
    return _videos.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  Stream<List<VideoModel>> getVideosByCourse(String courseId) {
    final list = _videos.values
        .where((v) => v.courseId == courseId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return Stream.value(list);
  }

  List<VideoModel> getVideosByCourseSync(String courseId) {
    return _videos.values
        .where((v) => v.courseId == courseId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<VideoModel?> getVideo(String videoId) async {
    return _videos[videoId];
  }

  Future<void> updateVideo(VideoModel video) async {
    _videos[video.id] = video;
    _videosController.add(_videos.values.toList()..sort((a, b) => a.order.compareTo(b.order)));
    try {
      await _db.collection('videos').doc(video.id).update(video.toMap());
    } catch (_) {}
  }

  Future<void> deleteVideo(String videoId) async {
    _videos.remove(videoId);
    _videosController.add(_videos.values.toList()..sort((a, b) => a.order.compareTo(b.order)));
    try {
      await _db.collection('videos').doc(videoId).delete();
    } catch (_) {}
  }

  // ================= BOOKS =================
  Future<void> saveBook(BookModel book) async {
    _books[book.id] = book;
    _booksController.add(_books.values.toList());
    try {
      await _db.collection('books').doc(book.id).set(book.toMap());
    } catch (_) {}
  }

  Stream<List<BookModel>> getBooks() {
    final list = _books.values.toList();
    return _booksController.stream.asBroadcastStream(
      onListen: (sub) {
        _booksController.add(list);
      },
    );
  }

  List<BookModel> getBooksSync() {
    return _books.values.toList();
  }

  List<BookModel> getBooksByCourseSync(String courseId) {
    return _books.values.where((b) => b.courseId == courseId).toList();
  }

  Future<void> updateBook(BookModel book) async {
    _books[book.id] = book;
    _booksController.add(_books.values.toList());
    try {
      await _db.collection('books').doc(book.id).update(book.toMap());
    } catch (_) {}
  }

  Future<void> deleteBook(String bookId) async {
    _books.remove(bookId);
    _booksController.add(_books.values.toList());
    try {
      await _db.collection('books').doc(bookId).delete();
    } catch (_) {}
  }

  // ================= PAST PAPERS =================
  Future<void> savePastPaper(PastPaperModel paper) async {
    _pastPapers[paper.id] = paper;
    _pastPapersController.add(_pastPapers.values.toList());
    try {
      await _db.collection('past_papers').doc(paper.id).set(paper.toMap());
    } catch (_) {}
  }

  Stream<List<PastPaperModel>> getPastPapers() {
    final list = _pastPapers.values.toList();
    return _pastPapersController.stream.asBroadcastStream(
      onListen: (sub) {
        _pastPapersController.add(list);
      },
    );
  }

  List<PastPaperModel> getPastPapersSync() {
    return _pastPapers.values.toList();
  }

  List<PastPaperModel> getPastPapersByYearAndType(String year, String type) {
    return _pastPapers.values
        .where((pp) => pp.year == year && pp.type == type)
        .toList();
  }

  List<String> getAvailablePastPaperYears() {
    final years = _pastPapers.values.map((pp) => pp.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // newest first
    return years;
  }

  Future<void> updatePastPaper(PastPaperModel paper) async {
    _pastPapers[paper.id] = paper;
    _pastPapersController.add(_pastPapers.values.toList());
    try {
      await _db.collection('past_papers').doc(paper.id).update(paper.toMap());
    } catch (_) {}
  }

  Future<void> deletePastPaper(String paperId) async {
    _pastPapers.remove(paperId);
    _pastPapersController.add(_pastPapers.values.toList());
    try {
      await _db.collection('past_papers').doc(paperId).delete();
    } catch (_) {}
  }

  // ================= SUBSCRIPTIONS =================
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    _subscriptions[subscription.userId] = subscription;
    _subscriptionsController.add(_subscriptions.values.toList());
    try {
      await _db
          .collection('subscriptions')
          .doc(subscription.id)
          .set(subscription.toMap());
    } catch (_) {}
  }

  Stream<SubscriptionModel?> getSubscription(String userId) {
    final sub = _subscriptions[userId];
    return Stream.value(sub);
  }

  SubscriptionModel? getSubscriptionSync(String userId) {
    return _subscriptions[userId];
  }

  Stream<List<SubscriptionModel>> getAllSubscriptions() {
    return Stream.value(_subscriptions.values.toList());
  }

  bool hasActiveSubscription(String userId) {
    final sub = _subscriptions[userId];
    return sub != null &&
        sub.status == 'active' &&
        sub.expiryDate.isAfter(DateTime.now());
  }

  // Activate 30 days subscription for user
  Future<SubscriptionModel> activateSubscription({
    required String userId,
    required String paymentReference,
    double amount = 10.0,
    String approvedBy = 'admin',
  }) async {
    final sub = SubscriptionModel(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      status: 'active',
      startDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      amount: amount,
      paymentReference: paymentReference,
      approvedBy: approvedBy,
      createdAt: DateTime.now(),
    );
    await saveSubscription(sub);
    return sub;
  }

  // ================= PAYMENTS =================
  /// Airtel mobile money number – all payments to this number are auto-approved.
  static const String _airtelPaymentNumber = '0772184445';

  Future<void> savePayment(PaymentModel payment) async {
    final approved = PaymentModel(
      id: payment.id,
      userId: payment.userId,
      amount: payment.amount,
      paymentReference: payment.paymentReference,
      proofUrl: payment.proofUrl,
      status: 'approved',
      submittedAt: payment.submittedAt,
      reviewedAt: DateTime.now(),
      reviewedBy: 'airtel_auto',
    );
    _payments[approved.id] = approved;
    _paymentsController.add(_payments.values.toList());
    await activateSubscription(
      userId: payment.userId,
      paymentReference: payment.paymentReference,
      amount: payment.amount,
      approvedBy: 'Airtel $_airtelPaymentNumber',
    );
    try {
      await _db.collection('payments').doc(approved.id).set(approved.toMap());
    } catch (_) {}
  }

  Stream<List<PaymentModel>> getPaymentsByUser(String userId) {
    final userPayments = _payments.values
        .where((p) => p.userId == userId)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return Stream.value(userPayments);
  }

  Stream<List<PaymentModel>> getAllPayments() {
    final all = _payments.values.toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return Stream.value(all);
  }

  List<PaymentModel> getAllPaymentsSync() {
    return _payments.values.toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  Future<void> approvePayment(String paymentId, {String approvedBy = 'admin'}) async {
    final payment = _payments[paymentId];
    if (payment != null) {
      final updated = PaymentModel(
        id: payment.id,
        userId: payment.userId,
        amount: payment.amount,
        paymentReference: payment.paymentReference,
        proofUrl: payment.proofUrl,
        status: 'approved',
        submittedAt: payment.submittedAt,
        reviewedAt: DateTime.now(),
        reviewedBy: approvedBy,
      );
      _payments[paymentId] = updated;
      await activateSubscription(
        userId: payment.userId,
        paymentReference: payment.paymentReference,
        amount: payment.amount,
        approvedBy: approvedBy,
      );
      _paymentsController.add(_payments.values.toList());
    }
  }

  Future<void> rejectPayment(String paymentId, {String rejectedBy = 'admin'}) async {
    final payment = _payments[paymentId];
    if (payment != null) {
      final updated = PaymentModel(
        id: payment.id,
        userId: payment.userId,
        amount: payment.amount,
        paymentReference: payment.paymentReference,
        proofUrl: payment.proofUrl,
        status: 'rejected',
        submittedAt: payment.submittedAt,
        reviewedAt: DateTime.now(),
        reviewedBy: rejectedBy,
      );
      _payments[paymentId] = updated;
      _paymentsController.add(_payments.values.toList());
    }
  }

  // ================= APP SETTINGS =================
  Future<AppSettingsModel> getAppSettings() async {
    return _appSettings;
  }

  AppSettingsModel getAppSettingsSync() {
    return _appSettings;
  }

  Future<void> updateAppSettings(AppSettingsModel settings) async {
    _appSettings = settings;
    try {
      await _db.collection('app_settings').doc('current').set(settings.toMap());
    } catch (_) {}
  }
}