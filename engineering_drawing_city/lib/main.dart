import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import 'package:engineering_drawing_city/firebase_options.dart';
import 'package:engineering_drawing_city/models/course_model.dart';
import 'package:engineering_drawing_city/models/video_model.dart';
import 'package:engineering_drawing_city/screens/admin/admin_login_screen.dart';
import 'package:engineering_drawing_city/screens/ai/ai_assistant_screen.dart';
import 'package:engineering_drawing_city/screens/auth/forgot_password_screen.dart';
import 'package:engineering_drawing_city/screens/auth/login_screen.dart';
import 'package:engineering_drawing_city/screens/auth/register_screen.dart';
import 'package:engineering_drawing_city/screens/courses/courses_screen.dart';
import 'package:engineering_drawing_city/screens/home/home_screen.dart';
import 'package:engineering_drawing_city/screens/profile/profile_screen.dart';
import 'package:engineering_drawing_city/screens/splash/splash_screen.dart';
import 'package:engineering_drawing_city/screens/video/video_player_screen.dart';
import 'package:engineering_drawing_city/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Phase 1: secure the Android app only. Web App Check will be configured
    // separately after Android has been tested and its debug token registered.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
      );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      debugPrint('Firebase App Check initialized for Android.');
    }
  } catch (e, stackTrace) {
    // Keep local development possible while App Check is being configured.
    // Do not enable Firebase enforcement until Android tokens are verified.
    debugPrint('Firebase/App Check initialization warning: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
  runApp(const EngineeringDrawingCityApp());
}

class EngineeringDrawingCityApp extends StatefulWidget {
  const EngineeringDrawingCityApp({super.key});

  @override
  State<EngineeringDrawingCityApp> createState() =>
      _EngineeringDrawingCityAppState();
}

class _EngineeringDrawingCityAppState extends State<EngineeringDrawingCityApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Engineering Drawing City',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        ForgotPasswordScreen.routeName: (context) =>
            const ForgotPasswordScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        CoursesScreen.routeName: (context) => const CoursesScreen(),
        VideoPlayerScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map<String, dynamic>) {
            return VideoPlayerScreen(
              video: args['video'] as VideoModel,
              course: args['course'] as CourseModel?,
            );
          } else if (args is VideoModel) {
            return VideoPlayerScreen(video: args);
          }
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No video lesson was selected. Please choose a published lesson from Courses.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
        AIAssistantScreen.routeName: (context) => const AIAssistantScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        AdminLoginScreen.routeName: (context) => const AdminLoginScreen(),
        AdminDashboardScreen.routeName: (context) =>
            const AdminDashboardScreen(),
      },
    );
  }
}