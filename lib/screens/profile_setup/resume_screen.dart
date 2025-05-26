import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/progress_indicator.dart';
import 'package:pronto/constants.dart';
import 'education_screen.dart';

class ResumeScreen extends StatefulWidget {
  final String userEmail;

  const ResumeScreen({super.key, required this.userEmail});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  Map<String, String> _resumes = {};
  bool _isLoading = false;

  final List<String> _resumeTypes = [
    'General',
    'Technical',
    'Creative',
    'Sales & Marketing',
    'Finance',
    'Healthcare',
    'Education',
    'Hospitality',
    'Others',
  ];

  Future<void> _uploadResume(String type) async {
    // This would typically open a file picker
    // For now, we'll simulate with a dialog
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload $type Resume'),
        content: const Text(
          'Resume upload functionality would be implemented here',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'resume_url_placeholder'),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _resumes[type] = result;
      });
    }
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .update({
            'resumes': _resumes,
            'completedSteps': 8,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EducationScreen(userEmail: widget.userEmail),
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
        title: const CustomProgressIndicator(currentStep: 8),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload your resumes',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload different versions of your resume for different job types',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ...(_resumeTypes.map(
              (type) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 51),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$type Resume',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (_resumes.containsKey(type))
                            Text(
                              'Uploaded',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.green),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _uploadResume(type),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _resumes.containsKey(type)
                            ? Colors.green
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _resumes.containsKey(type) ? 'Replace' : 'Upload',
                      ),
                    ),
                  ],
                ),
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
