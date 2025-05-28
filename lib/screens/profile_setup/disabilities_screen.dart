import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/progress_indicator.dart';
import 'package:pronto/constants.dart';
import 'location_screen.dart';

class DisabilityScreen extends StatefulWidget {
  final String? userId;

  const DisabilityScreen({super.key, required this.userId});

  @override
  State<DisabilityScreen> createState() => _DisabilityScreenState();
}

class _DisabilityScreenState extends State<DisabilityScreen> {
  List<String> _selectedDisabilities = [];
  bool _isLoading = false;

  final List<String> _disabilityOptions = [
    'Visual impairment',
    'Hearing impairment',
    'Physical disability',
    'Learning disability',
    'Autism spectrum disorder',
    'ADHD',
    'Mental health condition',
    'Chronic illness',
    'Others',
    'Prefer not to say',
    'No disabilities',
  ];

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'disabilities': _selectedDisabilities,
            'completedSteps': 3,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationScreen(userId: widget.userId),
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
        title: const CustomProgressIndicator(currentStep: 3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility needs',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This information helps us provide better support and accommodations',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Text(
              'Do you have any disabilities or conditions that may require accommodations?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...(_disabilityOptions.map(
              (disability) => CheckboxListTile(
                title: Text(disability),
                value: _selectedDisabilities.contains(disability),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (disability == 'No disabilities') {
                        _selectedDisabilities.clear();
                      } else {
                        _selectedDisabilities.remove('No disabilities');
                      }
                      _selectedDisabilities.add(disability);
                    } else {
                      _selectedDisabilities.remove(disability);
                    }
                  });
                },
                activeColor: AppColors.primary,
              ),
            )),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveToFirebase,
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
    );
  }
}
