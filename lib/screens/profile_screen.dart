import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pronto/models/userType_model.dart';
import 'package:pronto/router.dart';
import 'package:pronto/widgets/custom_text_field.dart';
import 'package:pronto/widgets/custom_dropdown_field.dart';
import 'package:pronto/constants/colours.dart';
import 'dart:io';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class ProfileScreen extends StatefulWidget {
  final String userId;
  final UserType userType;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic> userData = {};
  Map<String, int> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection(
            widget.userType == UserType.applicant ? 'users' : 'recruiters',
          )
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() ?? {};
        });
      }

      // Load statistics
      await _loadStatistics();
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      if (widget.userType == UserType.applicant) {
        // For applicants: count applications, interviews, rejections
        final applicationsQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('applications')
            .get();

        int applications = applicationsQuery.docs.length;
        int interviews = applicationsQuery.docs
            .where((doc) => doc.data()['status'] == 'interview')
            .length;
        int rejections = applicationsQuery.docs
            .where(
              (doc) =>
                  doc.data()['status'] == 'rejected' ||
                  doc.data()['status'] == 'declined',
            )
            .length;

        setState(() {
          stats = {
            'applications': applications,
            'interviews': interviews,
            'rejections': rejections,
          };
        });
      } else {
        // For recruiters: count job posts, offers, etc.
        final jobsQuery = await FirebaseFirestore.instance
            .collection('jobs')
            .where('recruiterID', isEqualTo: widget.userId)
            .get();

        int jobPosts = jobsQuery.docs.length;
        int totalOffers = 0;
        int totalApplications = 0;

        for (var job in jobsQuery.docs) {
          final jobData = job.data();
          totalOffers += (jobData['usersOffered'] as List?)?.length ?? 0;
          totalApplications += (jobData['usersApplied'] as List?)?.length ?? 0;
        }

        setState(() {
          stats = {
            'jobPosts': jobPosts,
            'offers': totalOffers,
            'applications': totalApplications,
          };
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final uid = user.uid;
        final oldPicURL = userData['profilePicURL'];
        final storageRef = FirebaseStorage.instance.ref();
        final userFolder = storageRef.child('profilePictures/$uid');

        // Delete old profile picture if exists
        if (oldPicURL != null && oldPicURL.isNotEmpty) {
          final oldPicRef = FirebaseStorage.instance.refFromURL(oldPicURL);
          await oldPicRef.delete();
        }

        // Upload new profile picture
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
        final uploadRef = userFolder.child(fileName);
        final uploadTask = await uploadRef.putFile(File(image.path));
        final newDownloadURL = await uploadTask.ref.getDownloadURL();

        // Update Firestore with new URL
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profilePicURL': newDownloadURL,
        });

        // Update local userData and refresh UI
        setState(() {
          userData['profilePicURL'] = newDownloadURL;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _updatePersonalInfoSection(
    Map<String, dynamic> updatedFields,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(
            widget.userType == UserType.applicant ? 'users' : 'recruiters',
          )
          .doc(widget.userId)
          .update(updatedFields);

      // Update local userData to reflect changes immediately
      updatedFields.forEach((key, value) {
        if (key.contains('.')) {
          final parts = key.split('.');
          if (userData[parts[0]] == null) {
            userData[parts[0]] = {};
          }
          userData[parts[0]][parts[1]] = value;
        } else {
          userData[key] = value;
        }
      });

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal information updated successfully!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating information: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isApplicant = widget.userType == UserType.applicant;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Profile header with light blue container
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile picture with edit button
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor,
                        backgroundImage: userData['profilePicURL'] != null
                            ? NetworkImage(userData['profilePicURL'])
                            : null,
                        child: userData['profilePicURL'] == null
                            ? Icon(
                                isApplicant ? Icons.person : Icons.business,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    userData['name'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Email instead of ID
                  Text(
                    userData['email'] ?? 'No email provided',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 16),

                  // Statistics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: isApplicant
                        ? [
                            _buildProfileStat(
                              'Applications',
                              stats['applications']?.toString() ?? '0',
                              Colors.blue,
                            ),
                            _buildProfileStat(
                              'Interviews',
                              stats['interviews']?.toString() ?? '0',
                              Colors.green,
                            ),
                            _buildProfileStat(
                              'Rejections',
                              stats['rejections']?.toString() ?? '0',
                              Colors.red,
                            ),
                          ]
                        : [
                            _buildProfileStat(
                              'Job Posts',
                              stats['jobPosts']?.toString() ?? '0',
                              Colors.blue,
                            ),
                            _buildProfileStat(
                              'Offers',
                              stats['offers']?.toString() ?? '0',
                              Colors.green,
                            ),
                            _buildProfileStat(
                              'Applications',
                              stats['applications']?.toString() ?? '0',
                              Colors.orange,
                            ),
                          ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // Profile sections as accordions
            if (isApplicant) ...[
              _buildAccordionSection(
                'Personal Information',
                Icons.person,
                _buildPersonalInfoContent(),
              ),
              _buildAccordionSection(
                'Resume',
                Icons.description,
                _buildResumeContent(),
              ),
              _buildAccordionSection(
                'Education',
                Icons.school,
                _buildEducationContent(),
              ),
              _buildAccordionSection(
                'Work Experience',
                Icons.work,
                _buildWorkExperienceContent(),
              ),
              _buildAccordionSection(
                'Project Experience',
                Icons.code,
                _buildProjectExperienceContent(),
              ),
              _buildAccordionSection(
                'Awards & Achievements',
                Icons.emoji_events,
                _buildAwardsContent(),
              ),
            ] else ...[
              _buildAccordionSection(
                'Company Information',
                Icons.business,
                _buildCompanyInfoContent(),
              ),
            ],

            const SizedBox(height: 24),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SECTIONS
  Widget _buildProfileStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAccordionSection(String title, IconData icon, Widget content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [Padding(padding: const EdgeInsets.all(16), child: content)],
      ),
    );
  }

  late Map<String, String> _languages = userData['languages'] != null
      ? Map<String, String>.from(userData['languages'])
      : {};

  late List<String> _skills = userData['skills'] != null
      ? List<String>.from(userData['skills'])
      : [];

  void _addLanguage(StateSetter rebuildParent) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedLanguage = '';
        String selectedProficiency = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Language'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomDropdownField(
                    label: 'Language',
                    value: selectedLanguage,
                    options: [
                      'English',
                      'Mandarin',
                      'Malay',
                      'Tamil',
                      'Japanese',
                      'Korean',
                      'Spanish',
                      'French',
                      'German',
                    ].where((lang) => !_languages.containsKey(lang)).toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedLanguage = value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  CustomDropdownField(
                    label: 'Proficiency',
                    value: selectedProficiency,
                    options: ['Beginner', 'Intermediate', 'Advanced', 'Native'],
                    onChanged: (value) =>
                        setDialogState(() => selectedProficiency = value ?? ''),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      selectedLanguage.isNotEmpty &&
                          selectedProficiency.isNotEmpty
                      ? () {
                          rebuildParent(() {
                            _languages[selectedLanguage] = selectedProficiency;
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addSkill(StateSetter rebuildParent) {
    final TextEditingController skillController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Skill'),
          content: CustomTextField(
            controller: skillController,
            label: 'Skill',
            hint: 'Enter a skill',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final skill = skillController.text.trim();
                if (skill.isNotEmpty) {
                  rebuildParent(() {
                    _skills.add(skill);
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChipInputSection({
    required String title,
    required VoidCallback onAddPressed,
    required bool hasItems,
    required List<Widget> chips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 51),
              width: 1,
            ),
          ),
          child: hasItems
              ? Wrap(spacing: 8, runSpacing: 8, children: chips)
              : Text(
                  'No $title added yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoContent() {
    final nameController = TextEditingController(text: userData['name'] ?? '');
    final preferredNameController = TextEditingController(
      text: userData['preferredName'] ?? '',
    );
    final phoneController = TextEditingController(
      text: userData['phoneNumber'] ?? '',
    );
    final ageController = TextEditingController(
      text: userData['age']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: userData['location']?['address'] ?? '',
    );
    final postalCodeController = TextEditingController(
      text: userData['location']?['postalCode']?.toString() ?? '',
    );
    final introController = TextEditingController(
      text: userData['selfIntroduction'] ?? '',
    );
    final linkedInController = TextEditingController(
      text: userData['socials']?['linkedIn'] ?? '',
    );
    final githubController = TextEditingController(
      text: userData['socials']?['gitHub'] ?? '',
    );

    String? selectedGender = userData['gender'];
    String? selectedRace = userData['race'];
    String? selectedDesignation = userData['designation'];

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(controller: nameController, label: 'Full Name'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: preferredNameController,
              label: 'Preferred Name',
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: phoneController, label: 'Phone Number'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: ageController,
              label: 'Age',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustomDropdownField(
              label: 'Gender',
              value: selectedGender,
              options: ['Male', 'Female', 'Non-binary', 'Prefer not to say'],
              onChanged: (val) => setState(() => selectedGender = val),
            ),
            const SizedBox(height: 16),
            CustomDropdownField(
              label: 'Race',
              value: selectedRace,
              options: [
                'Chinese',
                'Malay',
                'Indian',
                'Eurasian',
                'Others',
                'Prefer not to say',
              ],
              onChanged: (val) => setState(() => selectedRace = val),
            ),
            const SizedBox(height: 16),
            _buildChipInputSection(
              title: 'Languages',
              onAddPressed: () => _addLanguage(setState),
              hasItems: _languages.isNotEmpty,
              chips: _languages.entries
                  .map(
                    (entry) => Chip(
                      label: Text('${entry.key} - ${entry.value}'),
                      onDeleted: () => setState(() {
                        _languages.remove(entry.key);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            CustomDropdownField(
              label: 'Designation',
              value: selectedDesignation,
              options: [
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
              ],
              onChanged: (val) => setState(() => selectedDesignation = val),
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: addressController, label: 'Address'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: postalCodeController,
              label: 'Postal Code',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: introController,
              label: 'Self Introduction',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildChipInputSection(
              title: 'Skills',
              onAddPressed: () => _addSkill(setState),
              hasItems: _skills.isNotEmpty,
              chips: _skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      onDeleted: () => setState(() {
                        _skills.remove(skill);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: linkedInController,
              label: 'LinkedIn Profile',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: githubController,
              label: 'GitHub Profile',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _updatePersonalInfoSection({
                    'name': nameController.text,
                    'preferredName': preferredNameController.text,
                    'phoneNumber': phoneController.text,
                    'age': int.tryParse(ageController.text) ?? 0,
                    'gender': selectedGender,
                    'race': selectedRace,
                    'languages': _languages,
                    'designation': selectedDesignation,
                    'location.address': addressController.text,
                    'location.postalCode':
                        int.tryParse(postalCodeController.text) ?? 0,
                    'selfIntroduction': introController.text,
                    'skills': _skills,
                    'socials.linkedIn': linkedInController.text,
                    'socials.gitHub': githubController.text,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Personal Information'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumeContent() {
    final resumes = userData['resumes'] as Map<String, dynamic>?;

    // Show dialog to get resume type (only for new uploads)
    Future<String?> showResumeTypeDialog([String? existingType]) async {
      final typeController = TextEditingController();

      return showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resume Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: typeController,
                label: 'What type of resume is this?',
                hint: 'e.g., Software Developer, Marketing, etc.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, typeController.text.trim());
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      );
    }

    // Upload/Re-upload a resume to Firebase Storage and save its URL to Firestore
    Future<void> _uploadResume([String? existingType]) async {
      try {
        // Pick file
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx'],
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(
                    existingType != null
                        ? 'Re-uploading resume...'
                        : 'Uploading resume...',
                  ),
                ],
              ),
            ),
          );

          final file = File(result.files.single.path!);
          final fileName = result.files.single.name;

          // Create a unique file name
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final storageFileName = '${widget.userId}_${timestamp}_$fileName';

          // Upload to Firebase Storage
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('resumes')
              .child(widget.userId)
              .child(storageFileName);

          final uploadTask = storageRef.putFile(file);
          await uploadTask;
          final downloadUrl = await storageRef.getDownloadURL();

          // Show dialog to get resume type (only for uploading resume)
          String? resumeType = existingType ?? await showResumeTypeDialog();

          if (resumeType != null && resumeType.isNotEmpty) {
            // If re-uploading, delete the old file first
            if (existingType != null &&
                resumes?[existingType]?['url'] != null) {
              try {
                final oldFileUrl = resumes![existingType]!['url'] as String;
                final oldRef = FirebaseStorage.instance.refFromURL(oldFileUrl);
                await oldRef.delete();
              } catch (e) {
                print('Error deleting old file: $e');
                // Continue even if old file deletion fails
              }
            }

            // Update Firestore with new resume
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .update({
                  'resumes.$resumeType': {
                    'url': downloadUrl,
                    'fileName': fileName,
                  },
                });

            // Close loading dialog
            Navigator.pop(context);

            // Refresh user data
            await _loadUserData();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    existingType != null
                        ? 'Resume re-uploaded successfully as $resumeType'
                        : 'Resume uploaded successfully as $resumeType',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            // Delete uploaded file if user cancels
            await storageRef.delete();
            Navigator.pop(context);
          }
        }
      } catch (e) {
        // Close loading dialog if open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

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

    // Delete resume function
    Future<void> deleteResume(String type) async {
      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Resume'),
          content: Text('Are you sure you want to delete the $type resume?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Deleting resume...'),
                ],
              ),
            ),
          );

          // Get the file URL before deleting from Firestore
          final fileUrl = resumes?[type]?['url'] as String?;

          // Delete from Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({'resumes.$type': FieldValue.delete()});

          // Delete from Firebase Storage
          if (fileUrl != null && fileUrl.isNotEmpty) {
            try {
              final ref = FirebaseStorage.instance.refFromURL(fileUrl);
              await ref.delete();
            } catch (e) {
              print('Error deleting file from storage: $e');
              // Continue even if file deletion fails
            }
          }

          // Close loading dialog
          Navigator.pop(context);

          // Refresh user data
          await _loadUserData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$type resume deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Close loading dialog if open
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting resume: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumes != null && resumes.isNotEmpty) ...[
          for (int i = 0; i < resumes.length; i++) ...[
            Builder(
              builder: (context) {
                final entry = resumes.entries.elementAt(i);
                final resumeData = entry.value as Map<String, dynamic>;
                final isGeneral = entry.key.toLowerCase() == 'general';

                return isGeneral
                    ? Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            title: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              resumeData['fileName'] ?? 'Unknown file',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () => _uploadResume(entry.key),
                                  tooltip: 'Re-upload resume',
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Slidable(
                        key: ValueKey(entry.key),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                deleteResume(entry.key);
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ],
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              title: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                resumeData['fileName'] ?? 'Unknown file',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () => _uploadResume(entry.key),
                                    tooltip: 'Re-upload resume',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
              },
            ),
            if (i != resumes.length - 1) const SizedBox(height: 8),
          ],
        ] else ...[
          const Text('No resumes uploaded yet'),
        ],
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _uploadResume(),
            icon: const Icon(Icons.add),
            label: const Text('Upload Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('education')
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              const Text('No education records added yet'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Handle add education
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Education'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final startDate = data['startDate'] as Timestamp?;
              final endDate = data['endDate'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.school),
                  title: Text(data['school'] ?? 'Unknown School'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['degree'] ?? 'Unknown Degree'} - ${data['fieldOfStudy'] ?? 'Unknown Field'}',
                      ),
                      if (data['grade'] != null && data['totalGrade'] != null)
                        Text('Grade: ${data['grade']}/${data['totalGrade']}'),
                      if (startDate != null && endDate != null)
                        Text(
                          '${startDate.toDate().year} - ${endDate.toDate().year}',
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Handle edit education
                    },
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Handle add education
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Education'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkExperienceContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('workExperience')
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              const Text('No work experience added yet'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Handle add work experience
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Work Experience'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final startDate = data['startDate'] as Timestamp?;
              final endDate = data['endDate'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.work),
                  title: Text(data['title'] ?? 'Unknown Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['company'] ?? 'Unknown Company'),
                      if (startDate != null && endDate != null)
                        Text(
                          '${startDate.toDate().year} - ${endDate.toDate().year}',
                        ),
                      if (data['description'] != null)
                        Text(
                          data['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Handle edit work experience
                    },
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Handle add work experience
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Work Experience'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectExperienceContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('projectExperience')
          .orderBy('startDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              const Text('No project experience added yet'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Handle add project experience
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Project Experience'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final startDate = data['startDate'] as Timestamp?;
              final endDate = data['endDate'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.code),
                  title: Text(data['title'] ?? 'Unknown Project'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['organisation'] ?? 'Unknown Organization'),
                      if (startDate != null && endDate != null)
                        Text(
                          '${startDate.toDate().year} - ${endDate.toDate().year}',
                        ),
                      if (data['description'] != null)
                        Text(
                          data['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Handle edit project experience
                    },
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Handle add project experience
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Project Experience'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAwardsContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('awards')
          .orderBy('year', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            children: [
              const Text('No awards & achievements added yet'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Handle add award
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Award'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events),
                  title: Text(data['title'] ?? 'Unknown Award'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['year'] != null) Text('Year: ${data['year']}'),
                      if (data['description'] != null)
                        Text(
                          data['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Handle edit award
                    },
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Handle add award
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Award'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompanyInfoContent() {
    return Column(
      children: [
        _buildEditableField(
          'Company Name',
          userData['company'] ?? '',
          'company',
        ),
        _buildEditableField('Industry', userData['industry'] ?? '', 'industry'),
        _buildEditableField(
          'Description',
          userData['description'] ?? '',
          'description',
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, String value, String field) {
    final controller = TextEditingController(text: value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller,
                  label: label,
                  hint: 'Enter $label',
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _updateField(field, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateField(String field, String value) async {
    try {
      Map<String, dynamic> updateData = {};

      // Handle nested fields
      if (field.contains('.')) {
        final parts = field.split('.');
        if (parts[0] == 'location') {
          updateData['location.${parts[1]}'] = parts[1] == 'postalCode'
              ? int.tryParse(value) ?? 0
              : value;
        } else if (parts[0] == 'socials') {
          updateData['socials.${parts[1]}'] = value;
        }
      } else {
        // Handle simple fields
        if (field == 'age') {
          updateData[field] = int.tryParse(value) ?? 0;
        } else {
          updateData[field] = value;
        }
      }

      await FirebaseFirestore.instance
          .collection(
            widget.userType == UserType.applicant ? 'users' : 'recruiters',
          )
          .doc(widget.userId)
          .update(updateData);

      // Update local data
      if (field.contains('.')) {
        final parts = field.split('.');
        if (parts[0] == 'location') {
          if (userData['location'] == null) userData['location'] = {};
          userData['location'][parts[1]] = parts[1] == 'postalCode'
              ? int.tryParse(value) ?? 0
              : value;
        } else if (parts[0] == 'socials') {
          if (userData['socials'] == null) userData['socials'] = {};
          userData['socials'][parts[1]] = value;
        }
      } else {
        userData[field] = field == 'age' ? int.tryParse(value) ?? 0 : value;
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating field: $e')));
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed out successfully')),
          );
          NavigationHelper.navigateAndClearStack('/welcome');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
        }
      }
    }
  }
}
