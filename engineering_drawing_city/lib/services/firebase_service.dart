import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  static Future<void>? _googleSignInInitialization;
  static const String _adminEmail = 'engineeringdrawingcity400@gmail.com';
  UserModel? _currentUser;

  final StreamController<UserModel?> _userStreamController =
      StreamController<UserModel?>.broadcast();

  UserModel? get currentUser => _currentUser;
  Stream<UserModel?> get authStateChanges => _userStreamController.stream;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  final Map<String, UserModel> _usersDb = {};
  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    if (user != null) {
      _usersDb[user.uid] = user;
      _usersDb[user.email.toLowerCase()] = user;
    }
    _userStreamController.add(_currentUser);
  }

Future<UserModel> signInWithEmailPassword({
  required String email,
  required String password,
}) async {
  final cleanEmail = email.trim().toLowerCase();
  final cleanPassword = password.trim();

  try {
    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception(
        'Unable to sign in. Please try again.',
      );
    }

    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    UserModel user;

    if (!userDocument.exists && cleanEmail == _adminEmail.toLowerCase()) {
      await _auth.signOut();
      throw Exception(
        'Administrator profile is not configured. Set this Firebase user\'s role to admin in the users collection, then sign in again.',
      );
    }

    if (userDocument.exists && userDocument.data() != null) {
      user = UserModel.fromMap(
        firebaseUser.uid,
        userDocument.data()!,
      );
    } else {
      user = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? cleanEmail,
        name: firebaseUser.displayName ??
            cleanEmail.split('@').first,
        role: 'student',
        isSuspended: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap());
    }

    if (cleanEmail == _adminEmail.toLowerCase() && user.role != 'admin') {
      await _auth.signOut();
      throw Exception(
        'This account is reserved for the administrator. Its Firestore profile must have role set to admin.',
      );
    }

    if (user.isSuspended) {
      final reason =
          user.suspensionReason ?? 'Violation of Terms and Conditions';

      await _auth.signOut();

      throw Exception(
        'ACCOUNT_SUSPENDED: Your account is currently suspended.\n'
        'Reason: $reason\n'
        'Please contact administrator for reactivation.',
      );
    }

    _currentUser = user;
    FirestoreService().watchSubscription(user.uid);
    if (user.role == 'admin') {
      await loadAllUsers();
    }

    _usersDb[user.uid] = user;
    _usersDb[cleanEmail] = user;

    _userStreamController.add(_currentUser);

    return user;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      throw Exception(
        'No account found for this email. Please register first.',
      );
    }

    if (e.code == 'wrong-password' ||
        e.code == 'invalid-credential') {
      throw Exception(
        'Incorrect email or password. Please try again.',
      );
    }

    if (e.code == 'invalid-email') {
      throw Exception(
        'Please enter a valid email address.',
      );
    }

    if (e.code == 'user-disabled') {
      throw Exception(
        'This Firebase account has been disabled.',
      );
    }

    if (e.code == 'network-request-failed') {
      throw Exception(
        'Network error. Please check your internet connection and try again.',
      );
    }

    throw Exception(
      e.message ?? 'Unable to sign in. Please try again.',
    );
  }
}


  /// Signs in with Google and creates a student profile on first sign-in.
  /// Google sign-in never grants administrator access.
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      _googleSignInInitialization ??= googleSignIn.initialize();
      await _googleSignInInitialization;

      final googleAccount = await googleSignIn.authenticate();
      final googleAuthentication = googleAccount.authentication;
      final idToken = googleAuthentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google did not return an authentication token. '
          'Please check the Google sign-in setup and try again.',
        );
      }

      final oauthCredential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Google sign-in could not be completed. Please try again.');
      }

      final usersCollection = FirebaseFirestore.instance.collection('users');
      final userDocument = await usersCollection.doc(firebaseUser.uid).get();

      late final UserModel user;
      if (userDocument.exists && userDocument.data() != null) {
        user = UserModel.fromMap(firebaseUser.uid, userDocument.data()!);

        if (user.role == 'admin') {
          await _auth.signOut();
          await googleSignIn.signOut();
          throw Exception(
            'Google sign-in is available for student accounts only. '
            'Please use the administrator login.',
          );
        }
      } else {
        user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: (firebaseUser.displayName?.trim().isNotEmpty ?? false)
              ? firebaseUser.displayName!.trim()
              : (firebaseUser.email ?? 'Student').split('@').first,
          role: 'student',
          photoUrl: firebaseUser.photoURL,
          isSuspended: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await usersCollection.doc(firebaseUser.uid).set(user.toMap());
      }

      if (user.isSuspended) {
        await _auth.signOut();
        await googleSignIn.signOut();
        throw Exception(
          'ACCOUNT_SUSPENDED: Your account is currently suspended. '
          '${user.suspensionReason ?? 'Please contact the administrator.'}',
        );
      }

      _currentUser = user;
      FirestoreService().watchSubscription(user.uid);
      _usersDb[user.uid] = user;
      _usersDb[user.email.toLowerCase()] = user;
      _userStreamController.add(_currentUser);
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'An account already exists with this email using another sign-in method. '
          'Please sign in with your email and password.',
        );
      }
      if (e.code == 'network-request-failed') {
        throw Exception(
          'Network error. Please check your internet connection and try again.',
        );
      }
      throw Exception(e.message ?? 'Google sign-in failed. Please try again.');
    } catch (e) {
      final message = e.toString();
      if (message.toLowerCase().contains('cancel')) {
        throw Exception('Google sign-in was cancelled.');
      }
      if (message.startsWith('Exception:')) rethrow;
      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  /// Send Firebase's real password reset email.
Future<void> sendPasswordResetEmail(String email) async {
  final cleanEmail = email.trim().toLowerCase();

  if (cleanEmail.isEmpty) {
    throw Exception('Please enter your email address.');
  }

  try {
    await _auth.sendPasswordResetEmail(
      email: cleanEmail,
    );
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'invalid-email':
        throw Exception('Please enter a valid email address.');

      case 'user-not-found':
        throw Exception(
          'No account was found with this email address.',
        );

      default:
        throw Exception(
          e.message ?? 'Unable to send the password reset email.',
        );
    }
  }
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
  final cleanName = name.trim();
  final cleanPassword = password.trim();

  if (cleanEmail == _adminEmail.toLowerCase()) {
    throw Exception('This email is reserved for the administrator.');
  }

  UserCredential? credential;

  try {
    // ============================================================
    // 1. CREATE ACCOUNT IN FIREBASE AUTHENTICATION
    // ============================================================
    credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception(
        'Firebase could not create the account. Please try again.',
      );
    }

    // ============================================================
    // 2. CREATE THE USER PROFILE
    // ============================================================
    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: cleanEmail,
      name: cleanName,
      role: 'student',
      year: year,
      program: program,
      institution: institution,
      phoneNumber: phoneNumber,
      isSuspended: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // ============================================================
    // 3. SAVE USER PROFILE TO FIRESTORE
    // ============================================================
    await FirebaseFirestore.instance
    .collection('users')
    .doc(firebaseUser.uid)
    .set(userModel.toMap());

    // ============================================================
    // 4. UPDATE CURRENT APP USER
    // ============================================================
    _currentUser = userModel;

    // Keep the local cache updated.
    _usersDb[userModel.uid] = userModel;
    _usersDb[cleanEmail] = userModel;


    // Notify the rest of the application.
    _userStreamController.add(_currentUser);

    return userModel;
  } on FirebaseAuthException catch (e) {
    // ============================================================
    // FIREBASE AUTHENTICATION ERRORS
    // ============================================================

    if (e.code == 'email-already-in-use') {
      throw Exception(
        'An account already exists with this email. Please sign in.',
      );
    }

    if (e.code == 'weak-password') {
      throw Exception(
        'The password is too weak. Please use a stronger password.',
      );
    }

    if (e.code == 'invalid-email') {
      throw Exception(
        'Please enter a valid email address.',
      );
    }

    if (e.code == 'operation-not-allowed') {
      throw Exception(
        'Email and password registration is not enabled in Firebase.',
      );
    }

    if (e.code == 'network-request-failed') {
      throw Exception(
        'Network error. Please check your internet connection and try again.',
      );
    }

    throw Exception(
      e.message ?? 'Unable to create your account. Please try again.',
    );
  } catch (e) {
    // ============================================================
    // FIRESTORE ERROR / OTHER ERROR
    // ============================================================

    // Firebase Authentication may have successfully created the
    // account while Firestore failed to save the profile.
    //
    // Remove the Firebase account so we don't leave an incomplete
    // account behind.
    if (credential?.user != null) {
      try {
        await credential!.user!.delete();
      } catch (_) {
        // Ignore cleanup failure.
      }
    }

    debugPrint('Registration error: $e');

    throw Exception(
      'Account creation failed. Please check your internet connection and try again.',
    );
  }
}
        

  /// Reactivate / Activate a suspended account (admin action)
  Future<void> reactivateAccount(String uid) async {
    final user = _usersDb[uid];
    if (user == null) return;

    final reactivated = user.copyWith(
      isSuspended: false,
      clearSuspensionReason: true,
      updatedAt: DateTime.now(),
    );
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isSuspended': false,
      'suspensionReason': FieldValue.delete(),
      'suspendedAt': FieldValue.delete(),
      'updatedAt': reactivated.updatedAt,
    });
    _usersDb[uid] = reactivated;
    _usersDb[reactivated.email.toLowerCase()] = reactivated;
    if (_currentUser?.uid == uid) _currentUser = reactivated;
    _userStreamController.add(_currentUser);
  }

  /// Activate suspended user (alias for reactivateAccount)
  Future<void> activateUser(String uid) => reactivateAccount(uid);

  /// Suspend a user account for Terms & Conditions breach (admin action)
  Future<void> suspendUser(String uid, {required String reason}) async {
    final user = _usersDb[uid];
    if (user == null) return;

    final now = DateTime.now();
    final suspended = user.copyWith(
      isSuspended: true,
      suspensionReason: reason,
      suspendedAt: now,
      updatedAt: now,
    );
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isSuspended': true,
      'suspensionReason': reason,
      'suspendedAt': now,
      'updatedAt': now,
    });
    _usersDb[uid] = suspended;
    _usersDb[suspended.email.toLowerCase()] = suspended;
    if (_currentUser?.uid == uid) _currentUser = suspended;
    _userStreamController.add(_currentUser);
  }

  Future<void> signOut() async {
    final signedOutUserId = _currentUser?.uid;
    try {
      await _auth.signOut();
    } catch (_) {}
    FirestoreService().clearPremiumContentForSignOut(signedOutUserId);
    _currentUser = null;
    _userStreamController.add(null);
  }

  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (_) {}
  }

  /// Load real student and administrator profiles from Firestore.
  /// This replaces the old in-memory demo accounts.
  Future<void> loadAllUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    _usersDb.clear();
    for (final document in snapshot.docs) {
      final user = UserModel.fromMap(document.id, document.data());
      _usersDb[user.uid] = user;
      _usersDb[user.email.toLowerCase()] = user;
    }
    final current = _currentUser;
    if (current != null) {
      _usersDb[current.uid] = current;
      _usersDb[current.email.toLowerCase()] = current;
    }
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
    _listenToFirestoreContent();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory data store with reactive StreamControllers
  final Map<String, CourseModel> _courses = {};
  final Map<String, VideoModel> _videos = {};
  final Map<String, BookModel> _books = {};
  final Map<String, PastPaperModel> _pastPapers = {};
  final Map<String, SubscriptionModel> _subscriptions = {};
  final Map<String, PaymentModel> _payments = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subscriptionWatchers = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _videosContentSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _booksContentSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pastPapersContentSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _appSettingsSubscription;
  String? _premiumContentUserId;
  bool _legacySubscriptionMigrationStarted = false;
  final Map<String, UserModel> _users = {};
  final Set<String> _remoteCourseIds = {};
  final Set<String> _remoteVideoIds = {};
  final Set<String> _remoteBookIds = {};
  final Set<String> _remotePastPaperIds = {};
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

  void _listenToFirestoreContent() {
    // Course metadata and basic settings are available after sign-in.
    // Premium lesson and document records are attached only after the current
    // user is confirmed as an administrator or an active subscriber.
    _db.collection('courses').snapshots().listen((snapshot) {
      final ids = snapshot.docs.map((doc) => doc.id).toSet();
      _courses.removeWhere((id, _) => _remoteCourseIds.contains(id) && !ids.contains(id));
      _remoteCourseIds
        ..clear()
        ..addAll(ids);
      for (final doc in snapshot.docs) {
        _courses[doc.id] = CourseModel.fromMap(doc.id, doc.data());
      }
      _coursesController.add(getCoursesSync());
    }, onError: (_) {});

  }

  void _listenToAppSettings() {
    if (_appSettingsSubscription != null) return;
    _appSettingsSubscription =
        _db.collection('app_settings').doc('current').snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        _appSettings = AppSettingsModel.fromMap(doc.data()!);
      }
    }, onError: (_) {
      _appSettingsSubscription = null;
    });
  }

  void _refreshPremiumContentAccess(String userId) {
    final user = AuthService().currentUser;
    if (user == null || user.uid != userId) return;
    if (user.role == 'admin' || hasActiveSubscription(userId)) {
      _listenToPremiumContent(userId);
    } else if (_premiumContentUserId == userId) {
      _stopPremiumContentListeners();
    }
  }

  void _listenToPremiumContent(String userId) {
    final user = AuthService().currentUser;
    if (user == null || user.uid != userId) return;
    if (user.role != 'admin' && !hasActiveSubscription(userId)) return;

    // Keep healthy listeners running. If one collection fails, it must not
    // cancel the other premium-content listeners.
    if (_premiumContentUserId != userId) {
      _stopPremiumContentListeners();
      _premiumContentUserId = userId;
    }

    if (_videosContentSubscription == null) {
      _videosContentSubscription =
          _db.collection('videos').snapshots().listen((snapshot) {
        final ids = snapshot.docs.map((doc) => doc.id).toSet();
        _videos.removeWhere(
            (id, _) => _remoteVideoIds.contains(id) && !ids.contains(id));
        _remoteVideoIds
          ..clear()
          ..addAll(ids);
        for (final doc in snapshot.docs) {
          try {
            _videos[doc.id] = VideoModel.fromMap(doc.id, doc.data());
          } catch (error, stackTrace) {
            debugPrint('Unable to parse video ${doc.id}: $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        }
        _videosController.add(getVideosSync());
      }, onError: (Object error, StackTrace stackTrace) {
        debugPrint('Firestore videos listener failed: $error');
        _videosContentSubscription?.cancel();
        _videosContentSubscription = null;
      });
    }

    if (_booksContentSubscription == null) {
      _booksContentSubscription =
          _db.collection('books').snapshots().listen((snapshot) {
        final ids = snapshot.docs.map((doc) => doc.id).toSet();
        _books.removeWhere(
            (id, _) => _remoteBookIds.contains(id) && !ids.contains(id));
        _remoteBookIds
          ..clear()
          ..addAll(ids);
        for (final doc in snapshot.docs) {
          try {
            _books[doc.id] = BookModel.fromMap(doc.id, doc.data());
          } catch (error, stackTrace) {
            debugPrint('Unable to parse book ${doc.id}: $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        }
        _booksController.add(getBooksSync());
      }, onError: (Object error, StackTrace stackTrace) {
        debugPrint('Firestore books listener failed: $error');
        _booksContentSubscription?.cancel();
        _booksContentSubscription = null;
      });
    }

    if (_pastPapersContentSubscription == null) {
      _pastPapersContentSubscription =
          _db.collection('past_papers').snapshots().listen((snapshot) {
        final ids = snapshot.docs.map((doc) => doc.id).toSet();
        _pastPapers.removeWhere(
            (id, _) => _remotePastPaperIds.contains(id) && !ids.contains(id));
        _remotePastPaperIds
          ..clear()
          ..addAll(ids);
        for (final doc in snapshot.docs) {
          try {
            _pastPapers[doc.id] = PastPaperModel.fromMap(doc.id, doc.data());
          } catch (error, stackTrace) {
            debugPrint('Unable to parse past paper ${doc.id}: $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        }
        _pastPapersController.add(getPastPapersSync());
      }, onError: (Object error, StackTrace stackTrace) {
        debugPrint('Firestore past-papers listener failed: $error');
        _pastPapersContentSubscription?.cancel();
        _pastPapersContentSubscription = null;
      });
    }
  }

  void _stopPremiumContentListeners() {
    _videosContentSubscription?.cancel();
    _booksContentSubscription?.cancel();
    _pastPapersContentSubscription?.cancel();
    _videosContentSubscription = null;
    _booksContentSubscription = null;
    _pastPapersContentSubscription = null;
    _premiumContentUserId = null;

    _videos.removeWhere((id, _) => _remoteVideoIds.contains(id));
    _books.removeWhere((id, _) => _remoteBookIds.contains(id));
    _pastPapers.removeWhere((id, _) => _remotePastPaperIds.contains(id));
    _remoteVideoIds.clear();
    _remoteBookIds.clear();
    _remotePastPaperIds.clear();
    _videosController.add(getVideosSync());
    _booksController.add(getBooksSync());
    _pastPapersController.add(getPastPapersSync());
  }

  void clearPremiumContentForSignOut(String? userId) {
    _stopPremiumContentListeners();
    _appSettingsSubscription?.cancel();
    _appSettingsSubscription = null;
    if (userId != null) {
      _subscriptionWatchers.remove(userId)?.cancel();
      _subscriptions.remove(userId);
      _subscriptionsController.add(_subscriptions.values.toList());
    }
  }

  void _initializeSeedData() {
    // Keep only application defaults. Courses, videos, books, past papers,
    // subscriptions, and payments must come from real Firestore records.
    _appSettings = AppSettingsModel(
      appName: 'Engineering Drawing City',
      logo: 'assets/images/logo.png',
      welcomeMessage:
          'Master Engineering Drawing, CAD & Technical Graphics with Pro Video Modules',
      subscriptionPrice: 50.0,
      subscriptionDuration: '30 days',
      paymentInstructions:
          'Secure mobile money payment setup is in progress. The subscription price is K50 per month. Payments will be enabled after the payment gateway is configured.',
      aiEnabled: true,
      contactInformation: 'Official support contact details pending confirmation.',
      maintenanceMode: false,
    );
  }

  // ================= USERS =================
  Future<void> saveUser(UserModel user) async {
    // Persist first so the UI never reports a successful profile update
    // when Firestore rejected the write.
    await _db.collection('users').doc(user.uid).set(user.toMap());
    _users[user.uid] = user;
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
    await _db.collection('courses').doc(course.id).set(course.toMap());
    _courses[course.id] = course;
    _coursesController.add(_courses.values.toList()..sort((a, b) => a.order.compareTo(b.order)));
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
    await _db.collection('videos').doc(video.id).set(video.toMap());
    _videos[video.id] = video;
    _videosController.add(_videos.values.toList()..sort((a, b) => a.order.compareTo(b.order)));
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
    await _db.collection('videos').doc(video.id).update(video.toMap());
    _videos[video.id] = video;
    _videosController.add(
      _videos.values.toList()..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  Future<void> deleteVideo(String videoId) async {
    await _db.collection('videos').doc(videoId).delete();
    _videos.remove(videoId);
    _remoteVideoIds.remove(videoId);
    _videosController.add(
      _videos.values.toList()..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  // ================= BOOKS =================
  Future<void> saveBook(BookModel book) async {
    await _db.collection('books').doc(book.id).set(book.toMap());
    _books[book.id] = book;
    _booksController.add(_books.values.toList());
  }

  Stream<List<BookModel>> getBooks() => _booksController.stream;

  List<BookModel> getBooksSync() {
    return _books.values.toList();
  }

  List<BookModel> getBooksByCourseSync(String courseId) {
    return _books.values.where((b) => b.courseId == courseId).toList();
  }

  Future<void> updateBook(BookModel book) async {
    await _db.collection('books').doc(book.id).update(book.toMap());
    _books[book.id] = book;
    _booksController.add(getBooksSync());
  }

  Future<void> deleteBook(String bookId) async {
    await _db.collection('books').doc(bookId).delete();
    _books.remove(bookId);
    _remoteBookIds.remove(bookId);
    _booksController.add(getBooksSync());
  }

  // ================= PAST PAPERS =================
  Future<void> savePastPaper(PastPaperModel paper) async {
    await _db.collection('past_papers').doc(paper.id).set(paper.toMap());
    _pastPapers[paper.id] = paper;
    _pastPapersController.add(_pastPapers.values.toList());
  }

  Stream<List<PastPaperModel>> getPastPapers() => _pastPapersController.stream;

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
    await _db.collection('past_papers').doc(paper.id).update(paper.toMap());
    _pastPapers[paper.id] = paper;
    _pastPapersController.add(getPastPapersSync());
  }

  Future<void> deletePastPaper(String paperId) async {
    await _db.collection('past_papers').doc(paperId).delete();
    _pastPapers.remove(paperId);
    _remotePastPaperIds.remove(paperId);
    _pastPapersController.add(getPastPapersSync());
  }

  // ================= SUBSCRIPTIONS =================
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    await _db
        .collection('subscriptions')
        .doc(subscription.userId)
        .set(subscription.toMap());
    _subscriptions[subscription.userId] = subscription;
    _subscriptionsController.add(_subscriptions.values.toList());
  }

  Future<void> _migrateLegacySubscriptionDates() async {
    final snapshot = await _db.collection('subscriptions').get();
    for (final document in snapshot.docs) {
      final data = document.data();
      final updates = <String, dynamic>{};
      for (final field in ['startDate', 'expiryDate', 'createdAt']) {
        final value = data[field];
        if (value is String) {
          final parsed = DateTime.tryParse(value);
          if (parsed != null) {
            updates[field] = Timestamp.fromDate(parsed);
          }
        }
      }
      if (updates.isNotEmpty) {
        await document.reference.update(updates);
      }
    }
  }

  void watchSubscription(String userId) {
    _listenToAppSettings();
    // Admin access must not depend on a subscription query succeeding.
    // Students are rechecked again when their subscription snapshot arrives.
    _refreshPremiumContentAccess(userId);
    if (AuthService().currentUser?.role == 'admin' &&
        !_legacySubscriptionMigrationStarted) {
      _legacySubscriptionMigrationStarted = true;
      unawaited(_migrateLegacySubscriptionDates().catchError((_) {}));
    }
    if (_subscriptionWatchers.containsKey(userId)) {
      _refreshPremiumContentAccess(userId);
      return;
    }
    _subscriptionWatchers[userId] = _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        _subscriptions.remove(userId);
      } else {
        final doc = snapshot.docs.first;
        _subscriptions[userId] = SubscriptionModel.fromMap(doc.id, doc.data());
      }
      _subscriptionsController.add(_subscriptions.values.toList());
      _refreshPremiumContentAccess(userId);
    }, onError: (_) {});
  }

  Stream<SubscriptionModel?> getSubscription(String userId) {
    return _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        _subscriptions.remove(userId);
        _subscriptionsController.add(_subscriptions.values.toList());
        return null;
      }
      final doc = snapshot.docs.first;
      final subscription = SubscriptionModel.fromMap(doc.id, doc.data());
      _subscriptions[userId] = subscription;
      _subscriptionsController.add(_subscriptions.values.toList());
      return subscription;
    });
  }

  SubscriptionModel? getSubscriptionSync(String userId) {
    return _subscriptions[userId];
  }

  Stream<List<SubscriptionModel>> getAllSubscriptions() {
    return _db.collection('subscriptions').snapshots().map((snapshot) {
      _subscriptions
        ..clear()
        ..addEntries(snapshot.docs.map((doc) {
          final subscription = SubscriptionModel.fromMap(doc.id, doc.data());
          return MapEntry(subscription.userId, subscription);
        }));
      return _subscriptions.values.toList();
    });
  }

  bool hasActiveSubscription(String userId) {
    // Administrators have complimentary access to every premium feature.
    final user = AuthService().currentUser;
    if (user?.uid == userId && user?.role == 'admin') {
      return true;
    }
    final sub = _subscriptions[userId];
    return sub != null &&
        sub.status == 'active' &&
        sub.expiryDate.isAfter(DateTime.now());
  }

  // Activate 30 days subscription for user
  Future<SubscriptionModel> activateSubscription({
    required String userId,
    required String paymentReference,
    double amount = 50.0,
    String approvedBy = 'admin',
  }) async {
    final sub = SubscriptionModel(
      id: userId,
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
  // Payment references remain pending until a trusted administrator or
  // verified payment provider confirms the transaction.
  Future<void> savePayment(PaymentModel payment) async {
    final pending = PaymentModel(
      id: payment.id,
      userId: payment.userId,
      amount: payment.amount,
      paymentReference: payment.paymentReference,
      proofUrl: payment.proofUrl,
      status: 'pending',
      submittedAt: payment.submittedAt,
    );
    await _db.collection('payments').doc(pending.id).set(pending.toMap());
    _payments[pending.id] = pending;
    _paymentsController.add(_payments.values.toList());
  }

  Stream<List<PaymentModel>> getPaymentsByUser(String userId) {
    return _db
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final payments = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      for (final payment in payments) {
        _payments[payment.id] = payment;
      }
      return payments;
    });
  }

  Stream<List<PaymentModel>> getAllPayments() {
    return _db.collection('payments').snapshots().map((snapshot) {
      final payments = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      _payments
        ..clear()
        ..addEntries(payments.map((payment) => MapEntry(payment.id, payment)));
      _paymentsController.add(payments);
      return payments;
    });
  }

  List<PaymentModel> getAllPaymentsSync() {
    return _payments.values
        .where((payment) => payment.userId != 'student_01')
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  Future<void> approvePayment(String paymentId, {String approvedBy = 'admin'}) async {
    final document = await _db.collection('payments').doc(paymentId).get();
    if (!document.exists || document.data() == null) {
      throw Exception('Payment record not found.');
    }

    final payment = PaymentModel.fromMap(document.id, document.data()!);
    if (payment.status != 'pending') {
      throw Exception('This payment has already been reviewed.');
    }

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

    await _db.collection('payments').doc(paymentId).set(updated.toMap());
    _payments[paymentId] = updated;
    await activateSubscription(
      userId: payment.userId,
      paymentReference: payment.paymentReference,
      amount: payment.amount,
      approvedBy: approvedBy,
    );
    _paymentsController.add(_payments.values.toList());
  }

  Future<void> rejectPayment(String paymentId, {String rejectedBy = 'admin'}) async {
    final document = await _db.collection('payments').doc(paymentId).get();
    if (!document.exists || document.data() == null) {
      throw Exception('Payment record not found.');
    }

    final payment = PaymentModel.fromMap(document.id, document.data()!);
    if (payment.status != 'pending') {
      throw Exception('This payment has already been reviewed.');
    }

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

    await _db.collection('payments').doc(paymentId).set(updated.toMap());
    _payments[paymentId] = updated;
    _paymentsController.add(_payments.values.toList());
  }

  // ================= APP SETTINGS =================
  Future<AppSettingsModel> getAppSettings() async {
    return _appSettings;
  }

  AppSettingsModel getAppSettingsSync() {
    return _appSettings;
  }

  Future<void> updateAppSettings(AppSettingsModel settings) async {
    await _db.collection('app_settings').doc('current').set(settings.toMap());
    _appSettings = settings;
  }
}
