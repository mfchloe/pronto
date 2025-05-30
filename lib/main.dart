import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/screens/onboarding/splash_screen.dart';
import 'package:pronto/screens/onboarding/welcome_screen.dart';
import 'package:pronto/screens/home_screen.dart';
import 'package:pronto/screens/profile_setup/personal_details_screen.dart';
import 'package:pronto/screens/profile_setup/designation_screen.dart';
import 'package:pronto/screens/profile_setup/disabilities_screen.dart';
import 'package:pronto/screens/profile_setup/location_screen.dart';
import 'package:pronto/screens/profile_setup/intro_screen.dart';
import 'package:pronto/screens/profile_setup/skills_screen.dart';
import 'package:pronto/screens/profile_setup/social_screen.dart';
import 'package:pronto/screens/profile_setup/resume_screen.dart';
import 'package:pronto/screens/profile_setup/education_screen.dart';
import 'package:pronto/screens/profile_setup/work_screen.dart';
import 'package:pronto/screens/profile_setup/project_screen.dart';
import 'package:pronto/screens/profile_setup/award_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pronto',
      theme: ThemeData(
        primaryColor: Color(0xFF0057B7),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF0057B7),
          secondary: Color(0xFFA6D3F2),
        ),
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
      // Set up named routes with arguments
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const AuthWrapper());
          case '/welcome':
            return MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            );
          case '/home':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => HomeScreen(userId: userId),
            );
          case '/personal-details':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => PersonalDetailsScreen(userId: userId),
            );
          case '/designation':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => DesignationScreen(userId: userId),
            );
          case '/disabilities':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => DisabilityScreen(userId: userId),
            );
          case '/location':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => LocationScreen(userId: userId),
            );
          case '/intro':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => IntroScreen(userId: userId),
            );
          case '/skills':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => SkillsScreen(userId: userId),
            );
          case '/social':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => SocialsScreen(userId: userId),
            );
          case '/resume':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ResumeScreen(userId: userId),
            );
          case '/education':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => EducationScreen(userId: userId),
            );
          case '/work':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => WorkExperienceScreen(userId: userId),
            );
          case '/project':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ProjectExperienceScreen(userId: userId),
            );
          case '/award':
            final String userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => AwardsScreen(userId: userId),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            );
        }
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        // User is not signed in
        if (snapshot.data == null) {
          return const WelcomeScreen();
        }
        // User is signed in, check onboarding completion
        return OnboardingChecker(user: snapshot.data!);
      },
    );
  }
}

class OnboardingChecker extends StatelessWidget {
  final User user;

  const OnboardingChecker({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        // Show loading screen while fetching user data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        // Handle error
        if (snapshot.hasError) {
          return const WelcomeScreen();
        }
        // User document doesn't exist or no data - shouldn't happen after signup
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const WelcomeScreen();
        }
        // User document exists, check completed steps
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final int completedSteps =
            userData['completedSteps'] ?? 1; // Default to 1 after signup

        // Navigate based on completed steps
        return _getScreenForStep(completedSteps);
      },
    );
  }

  Widget _getScreenForStep(int completedSteps) {
    final String userId = user.uid;

    switch (completedSteps) {
      case 1:
        return PersonalDetailsScreen(userId: userId);
      case 2:
        return DesignationScreen(userId: userId);
      case 3:
        return DisabilityScreen(userId: userId);
      case 4:
        return LocationScreen(userId: userId);
      case 5:
        return IntroScreen(userId: userId);
      case 6:
        return SkillsScreen(userId: userId);
      case 7:
        return SocialsScreen(userId: userId);
      case 8:
        return ResumeScreen(userId: userId);
      case 9:
        return EducationScreen(userId: userId);
      case 10:
        return WorkExperienceScreen(userId: userId);
      case 11:
        return ProjectExperienceScreen(userId: userId);
      case 12:
        return AwardsScreen(userId: userId);
      default:
        return HomeScreen(userId: userId);
    }
  }
}

// Navigation Helper Class
class NavigationHelper {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Navigate to a named route
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  // Replace current route with a new one
  static Future<dynamic> navigateAndReplace(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  // Clear all routes and navigate to a new one
  static Future<dynamic> navigateAndClearStack(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  // Go back to previous screen
  static void goBack() {
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
    }
  }
}
