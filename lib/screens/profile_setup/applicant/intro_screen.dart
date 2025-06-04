import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/widgets/progress_indicator.dart';
import 'package:pronto/constants.dart';
import 'package:pronto/router.dart';

class IntroScreen extends StatefulWidget {
  final String? userId;

  const IntroScreen({super.key, required this.userId});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _introController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _introController.addListener(() {
      setState(() {}); // This will now properly trigger a rebuild
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
            'selfIntroduction': _introController.text,
            'completedSteps': 3, // Assuming this is step 3 in your flow
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;

      NavigationHelper.navigateTo('/skills', arguments: widget.userId);
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
        title: const CustomProgressIndicator(currentStep: 5),
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
                'Introduce yourself',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about yourself, your interests, and what makes you unique',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _buildIntroductionField(),
              const SizedBox(height: 24),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroductionField() {
    final currentLength =
        _introController.text.length; // Store the length in a variable

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Self Introduction',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 51),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _introController,
            maxLines: 8,
            maxLength: 500,
            textInputAction: TextInputAction.newline,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText:
                  'Tell us about yourself, your hobbies, interests, personality, or anything you\'d like others to know about you...',
              hintStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '', // Hide the default counter
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please write a brief introduction about yourself';
              }
              if (value!.length < 50) {
                return 'Please write at least 50 characters';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$currentLength/500', // Use the stored variable instead of accessing controller directly
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: currentLength > 450
                  ? Colors.orange
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
