import 'package:flutter/material.dart';
import 'package:pronto/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/widgets/custom_dropdown_field.dart';
import 'package:pronto/widgets/progress_indicator.dart';
import 'disabilities_screen.dart';

class DesignationScreen extends StatefulWidget {
  final String? userId;

  const DesignationScreen({super.key, required this.userId});

  @override
  State<DesignationScreen> createState() => _DesignationScreenState();
}

class _DesignationScreenState extends State<DesignationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedDesignation = '';
  bool _isLoading = false;

  final List<String> _designations = [
    'Secondary School Student',
    'Junior College Student',
    'ITE Student',
    'Polytechnic Student',
    'University Student',
    'Recent Graduate',
    'Working Professional',
    'Career Changer',
    'Freelancer',
    'Entrepreneur',
    'Others',
  ];

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'designation': _selectedDesignation,
            'completedSteps': 2,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisabilityScreen(userId: widget.userId),
        ),
      );
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
        title: const CustomProgressIndicator(currentStep: 2),
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
                'What describes you best?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This helps us tailor opportunities to your current situation',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomDropdownField(
                label: 'Designation',
                value: _selectedDesignation,
                options: _designations,
                onChanged: (value) =>
                    setState(() => _selectedDesignation = value ?? ''),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please select your designation';
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
