import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pronto/widgets/progress_indicator.dart';
import 'package:pronto/constants/colours.dart';
import 'package:pronto/widgets/custom_text_field.dart';
import 'package:pronto/router.dart';

class SocialsScreen extends StatefulWidget {
  final String? userId;

  const SocialsScreen({super.key, required this.userId});

  @override
  State<SocialsScreen> createState() => _SocialsScreenState();
}

class _SocialsScreenState extends State<SocialsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkedInController = TextEditingController();
  final _githubController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _linkedInController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'socials': {
              'linkedIn': _linkedInController.text,
              'gitHub': _githubController.text,
            },
            'completedSteps': 7,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      NavigationHelper.navigateTo('/resume', arguments: widget.userId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const CustomProgressIndicator(currentStep: 7),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect your profiles',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Link your professional and portfolio accounts',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _linkedInController,
                label: 'LinkedIn Profile',
                hint: 'https://linkedin.com/in/your-profile',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: FaIcon(
                    FontAwesomeIcons.linkedin,
                    color: Colors.black,
                    size: 20,
                  ),
                ),

                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(
                      r'^https?://.*linkedin\.com/.*',
                    ).hasMatch(value)) {
                      return 'Please enter a valid LinkedIn URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _githubController,
                label: 'GitHub Profile',
                hint: 'https://github.com/your-username',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: FaIcon(
                    FontAwesomeIcons.github,
                    color: Colors.black,
                    size: 20,
                  ),
                ),

                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(
                      r'^https?://.*github\.com/.*',
                    ).hasMatch(value)) {
                      return 'Please enter a valid GitHub URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _saveToFirebase();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
