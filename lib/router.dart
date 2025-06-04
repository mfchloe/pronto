import 'package:flutter/material.dart';
import 'package:pronto/main.dart';
import 'package:pronto/screens/onboarding/splash_screen.dart';
import 'package:pronto/screens/onboarding/welcome_screen.dart';
import 'package:pronto/screens/auth/sign_in_screen.dart';
import 'package:pronto/screens/auth/sign_up_screen.dart';
import 'package:pronto/screens/auth/forgot_password_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/personal_details_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/designation_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/disabilities_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/location_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/intro_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/skills_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/social_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/resume_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/education_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/work_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/project_screen.dart';
import 'package:pronto/screens/profile_setup/recruiter/company_selection_screen.dart';
import 'package:pronto/screens/profile_setup/recruiter/create_company_screen.dart';
import 'package:pronto/screens/profile_setup/applicant/award_screen.dart';
import 'package:pronto/widgets/navbar.dart';
import 'package:pronto/models/userType_model.dart' as user_type_model;

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (context) => const AuthWrapper());
    // Onboarding Screens
    case '/splash':
      return MaterialPageRoute(builder: (context) => const SplashScreen());
    case '/welcome':
      return MaterialPageRoute(builder: (context) => const WelcomeScreen());
    // Authentication Screens
    case '/sign-in':
      return MaterialPageRoute(builder: (context) => const SigninScreen());
    case '/sign-up':
      return MaterialPageRoute(builder: (context) => const SignUpScreen());
    case '/forgot-password':
      return MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      );
    // Recruiter Profile Setup Screens
    case '/company-selection':
      final String userId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => CompanySelectionScreen(recruiterId: userId),
      );
    case '/create-company':
      final String userId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => CreateCompanyScreen(recruiterId: userId),
      );
    // Applicant Profile Setup Screens
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
    // Home Screen
    case '/home':
      final Map<String, dynamic> args =
          settings.arguments as Map<String, dynamic>;
      final String userId = args['userId'] as String;
      final user_type_model.UserType userType =
          args['userType'] as user_type_model.UserType;
      return MaterialPageRoute(
        builder: (context) => NavBar(userId: userId, userType: userType),
      );
    default:
      return MaterialPageRoute(builder: (context) => const WelcomeScreen());
  }
}

Widget getScreenForStep({
  required int completedSteps,
  required String userId,
  required user_type_model.UserType userType,
}) {
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
      return NavBar(userId: userId, userType: userType);
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
