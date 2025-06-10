import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pronto/widgets/custom_text_field.dart';
import 'package:pronto/widgets/custom_dropdown_field.dart';
import 'package:pronto/constants/colours.dart';
import 'package:pronto/models/userType_model.dart';
import 'package:pronto/router.dart';

class CreateCompanyScreen extends StatefulWidget {
  final String? recruiterId;
  final String? initialCompanyName;

  const CreateCompanyScreen({
    super.key,
    required this.recruiterId,
    this.initialCompanyName,
  });

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _industryController = TextEditingController();

  bool _isLoading = false;
  File? _logoImage;
  final ImagePicker _picker = ImagePicker();

  // Common industries list
  final List<String> _industries = [
    'Technology',
    'Finance',
    'Healthcare',
    'Education',
    'Retail',
    'Manufacturing',
    'Consulting',
    'Marketing',
    'Real Estate',
    'Food & Beverage',
    'Transportation',
    'Entertainment',
    'Non-profit',
    'Government',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill company name if provided
    if (widget.initialCompanyName != null) {
      _companyNameController.text = widget.initialCompanyName!;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _logoImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error picking image')));
    }
  }

  Future<String?> _uploadLogo(String companyId) async {
    if (_logoImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('company_logos')
          .child('$companyId.jpg');

      await storageRef.putFile(_logoImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading logo: $e');
      return null;
    }
  }

  Future<void> _createCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create company document
      final companyRef = FirebaseFirestore.instance
          .collection('companies')
          .doc();
      final companyId = companyRef.id;

      // Upload logo if selected
      String? logoUrl;
      if (_logoImage != null) {
        logoUrl = await _uploadLogo(companyId);
      }

      // Save company to Firestore (without domain validation for now)
      await companyRef.set({
        'name': _companyNameController.text.trim(),
        'nameLower': _companyNameController.text.trim().toLowerCase(),
        'industry': _industryController.text.trim(),
        'logoUrl': logoUrl,
        'createdBy': widget.recruiterId,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
      });

      // Update recruiter document with company information
      await FirebaseFirestore.instance
          .collection('recruiters')
          .doc(widget.recruiterId)
          .update({
            'companyId': companyId,
            'isVerified': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company created successfully!')),
        );
        // Navigate to home screen
        Navigator.pop(context);
        NavigationHelper.navigateAndClearStack(
          '/home',
          arguments: {
            'userId': widget.recruiterId,
            'userType': UserType.recruiter,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error creating company')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(automaticallyImplyLeading: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Create Company',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your company',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // Company Logo Section
                Center(
                  child: GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.textSecondary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: _logoImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                _logoImage!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 32,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Logo',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Form fields
                CustomTextField(
                  controller: _companyNameController,
                  label: 'Company Name',
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                CustomDropdownField(
                  label: 'Industry',
                  value: _industryController.text.isEmpty
                      ? null
                      : _industryController.text,
                  options: _industries,
                  onChanged: (value) {
                    if (value != null) {
                      _industryController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an industry';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Create button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createCompany,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Create Company',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
