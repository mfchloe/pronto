import 'package:flutter/material.dart';
import 'package:pronto/constants.dart';
import 'package:pronto/router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/logo_blue_no_words.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to Pronto',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Swipe your way to the perfect internship.\nFast, simple, and designed for students.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              _buildButton(
                context,
                'Get Started',
                AppColors.primary,
                Colors.white,
                () => NavigationHelper.navigateTo('/sign-up'),
              ),

              const SizedBox(height: 16),
              _buildButton(
                context,
                'I already have an account',
                Colors.transparent,
                AppColors.textSecondary,
                () => NavigationHelper.navigateTo('/sign-in'),
                outlined: true,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: outlined ? 0 : 2,
          shadowColor: AppColors.primary.withValues(alpha: 77),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: outlined
                ? const BorderSide(color: AppColors.textSecondary, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
