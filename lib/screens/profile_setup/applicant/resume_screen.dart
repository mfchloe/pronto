import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:pronto/widgets/progress_indicator.dart';
import 'package:pronto/widgets/custom_text_field.dart';
import 'package:pronto/constants.dart';
import 'education_screen.dart';

class ResumeScreen extends StatefulWidget {
  final String? userId;

  const ResumeScreen({super.key, required this.userId});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  Map<String, Map<String, String>> _resumes = {
    'General': {'url': '', 'fileName': ''},
  };
  bool _isLoading = false;
  Map<String, bool> _uploadingStates = {};
  final TextEditingController _customTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingResumes();
  }

  @override
  void dispose() {
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingResumes() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && doc.data()?['resumes'] != null) {
        final resumesData = doc.data()!['resumes'] as Map<String, dynamic>;
        setState(() {
          _resumes = resumesData.map<String, Map<String, String>>((key, value) {
            final nestedMap = value as Map<String, dynamic>;
            return MapEntry(
              key,
              Map<String, String>.from(nestedMap), // Convert dynamic to String
            );
          });
        });
      }
    } catch (e) {
      print('Error loading existing resumes: $e');
    }
  }

  Future<void> _uploadResume(String type) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _uploadingStates[type] = true;
        });

        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // Create a unique file name
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageFileName =
            '${widget.userId}_${type}_${timestamp}_$fileName';

        // Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('resumes')
            .child(widget.userId!)
            .child(storageFileName);

        final uploadTask = storageRef.putFile(file);

        // Show upload progress (optional)
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        });

        await uploadTask;
        final downloadUrl = await storageRef.getDownloadURL();

        setState(() {
          _resumes[type] = {'url': downloadUrl, 'fileName': fileName};
          _uploadingStates[type] = false;
        });
      }
    } catch (e) {
      setState(() {
        _uploadingStates[type] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading resume: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addCustomResumeType() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Resume Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the type of resume you want to add:'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _customTypeController,
              label: "Resume Type",
              hint: 'e.g., Technical, Creative, Sales...',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a resume type';
                }
                if (_resumes.containsKey(value.trim())) {
                  return 'This resume type already exists';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _customTypeController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final customType = _customTypeController.text.trim();
              if (customType.isNotEmpty && !_resumes.containsKey(customType)) {
                setState(() {
                  _resumes[customType] = {'url': '', 'fileName': ''};
                });
                _customTypeController.clear();
                Navigator.pop(context);
              } else if (_resumes.containsKey(customType)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This resume type already exists'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _removeResumeType(String type) {
    if (type == 'General') return; // Don't allow removing general resume

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Resume Type'),
        content: Text('Are you sure you want to remove the $type resume?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final fileUrl = _resumes[type]?['url'];

              setState(() {
                _resumes.remove(type);
              });

              Navigator.pop(context);

              // Delete from Firebase Storage
              if (fileUrl != null && fileUrl.isNotEmpty) {
                try {
                  final ref = FirebaseStorage.instance.refFromURL(fileUrl);
                  await ref.delete();
                  print('File: $fileUrl deleted successfully');
                } catch (e) {
                  print('Error deleting file: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting file: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToFirebase() async {
    // Check if at least the general resume is uploaded
    if (_resumes['General']?['url']?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least a General resume to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'resumes': _resumes,
            'completedSteps': 8,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EducationScreen(userId: widget.userId),
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

  Widget _buildResumeCard(String type) {
    final resume = _resumes[type]!;
    final isUploaded = resume['url']?.isNotEmpty ?? false;
    final isUploading = _uploadingStates[type] ?? false;

    return Container(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$type Resume',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (type != 'General')
                      IconButton(
                        onPressed: () => _removeResumeType(type),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.red,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                if (isUploaded)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploaded: ${resume['fileName']}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.green),
                      ),
                    ],
                  )
                else if (isUploading)
                  Text(
                    'Uploading...',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: isUploading ? null : () => _uploadResume(type),
            style: ElevatedButton.styleFrom(
              backgroundColor: isUploaded ? Colors.green : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isUploaded ? 'Replace' : 'Upload'),
          ),
        ],
      ),
    );
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
              'Upload different versions of your resume for different job types. Start with a general resume, then add specialized versions as needed.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Display resume cards
            ...(_resumes.keys.map((type) => _buildResumeCard(type))),

            // Add more resume types button
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: OutlinedButton.icon(
                onPressed: _addCustomResumeType,
                icon: const Icon(Icons.add),
                label: const Text('Add Resume Type'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

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
