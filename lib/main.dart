import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/router.dart';
import 'firebase_options.dart';
import 'package:pronto/constants/colours.dart';
import 'package:pronto/models/userType_model.dart';
import 'package:pronto/screens/onboarding/splash_screen.dart';
import 'package:pronto/screens/onboarding/welcome_screen.dart';
import 'package:pronto/widgets/navbar.dart';

// Entry point of app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pronto',
      navigatorKey: NavigationHelper.navigatorKey, // for global navigation
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
          bodyMedium: TextStyle(fontSize: 14, fontFamily: 'Inter'),
          labelSmall: TextStyle(fontSize: 10, fontFamily: 'Inter'),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: generateRoute,
    );
  }
}

// Determines what to show based on the user's authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        // User is not signed in
        if (snapshot.data == null) {
          return const WelcomeScreen();
        }
        // User is signed in, proceed to onboarding check
        return OnboardingChecker(user: snapshot.data!);
      },
    );
  }
}

// Checks if the user has completed onboarding and returns the appropriate screen
class OnboardingChecker extends StatelessWidget {
  final User user;

  const OnboardingChecker({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _fetchUserDocument(user.uid),
      builder: (context, snapshot) {
        // Show splash screen while fetching user data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        // Handle errors or no data
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const WelcomeScreen();
        }
        // User data exists, determine user type and completed steps
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String? userTypeStr = userData['userType'] as String?;
        final userType = UserType.values.firstWhere(
          (e) => e.toString().split('.').last == userTypeStr,
          orElse: () => UserType.applicant,
        );
        // If user is a recruiter, go straight to navigation bar
        if (userType == UserType.recruiter) {
          return NavBar(userId: user.uid, userType: userType);
        }
        // If user is an applicant, check completed steps
        final int completedSteps = userData['completedSteps'] ?? 1;
        return getScreenForStep(
          completedSteps: completedSteps,
          userId: user.uid,
          userType: userType,
        );
      },
    );
  }

  // Fetches user document from Firestore (checks both 'users' and 'recruiters' collections)
  Future<DocumentSnapshot> _fetchUserDocument(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists) return userDoc;

    final recruiterDoc = await FirebaseFirestore.instance
        .collection('recruiters')
        .doc(uid)
        .get();
    return recruiterDoc;
  }
}
