import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/widgets/progress_indicator.dart';
import 'package:pronto/widgets/custom_text_field.dart';
import 'package:pronto/constants/colours.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pronto/router.dart';

class WorkExperienceScreen extends StatefulWidget {
  final String? userId;

  const WorkExperienceScreen({super.key, required this.userId});

  @override
  State<WorkExperienceScreen> createState() => _WorkExperienceScreenState();
}

class _WorkExperienceScreenState extends State<WorkExperienceScreen> {
  List<Map<String, dynamic>> _workExperiences = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkExperienceData();
  }

  Future<void> _loadWorkExperienceData() async {
    try {
      final workSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('workExperience')
          .get();

      if (workSnapshot.docs.isNotEmpty) {
        setState(() {
          _workExperiences = workSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading work experience data: $e')),
      );
    }
  }

  void _addWorkExperience() {
    showDialog(
      context: context,
      builder: (context) => _WorkExperienceDialog(
        onSave: (workExperience) async {
          try {
            final docRef = await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('workExperience')
                .add({
                  ...workExperience,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

            setState(() {
              workExperience['id'] = docRef.id;
              _workExperiences.add(workExperience);
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding work experience: $e')),
            );
          }
        },
      ),
    );
  }

  void _editWorkExperience(int index) {
    showDialog(
      context: context,
      builder: (context) => _WorkExperienceDialog(
        workExperience: _workExperiences[index],
        onSave: (workExperience) async {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('workExperience')
                .doc(_workExperiences[index]['id'])
                .update({
                  ...workExperience,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

            setState(() {
              workExperience['id'] = _workExperiences[index]['id'];
              _workExperiences[index] = workExperience;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating work experience: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteWorkExperience(int index) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('workExperience')
          .doc(_workExperiences[index]['id'])
          .delete();

      setState(() {
        _workExperiences.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work experience deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting work experience: $e')),
      );
    }
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'completedSteps': 10,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      NavigationHelper.navigateTo('/project', arguments: widget.userId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteOption(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete "${_workExperiences[index]['company']}"?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteWorkExperience(index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        title: const CustomProgressIndicator(currentStep: 10),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Work Experience',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your professional work experience',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_workExperiences.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 51),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No work experience added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _addWorkExperience,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Icon(Icons.add, size: 24),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ...(_workExperiences.asMap().entries.map((entry) {
                    final index = entry.key;
                    final workExperience = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Slidable(
                        key: Key(workExperience['id'] ?? index.toString()),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (context) =>
                                  _showDeleteOption(context, index),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(0),
                                bottomLeft: Radius.circular(0),
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () => _editWorkExperience(index),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                topRight: Radius.circular(0),
                                bottomRight: Radius.circular(0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        workExperience['company'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _editWorkExperience(index),
                                      icon: const Icon(Icons.edit, size: 20),
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                                Text(
                                  workExperience['title'],
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.textPrimary),
                                ),
                                if (workExperience['description'] != null &&
                                    workExperience['description']
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    workExperience['description'],
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${workExperience['startDate']} - ${workExperience['endDate']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  })),
                ],
              ),
            if (_workExperiences.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _addWorkExperience,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Icon(Icons.add, size: 24),
                ),
              ),
            ],
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

class _WorkExperienceDialog extends StatefulWidget {
  final Map<String, dynamic>? workExperience;
  final Function(Map<String, dynamic>) onSave;

  const _WorkExperienceDialog({this.workExperience, required this.onSave});

  @override
  State<_WorkExperienceDialog> createState() => _WorkExperienceDialogState();
}

class _WorkExperienceDialogState extends State<_WorkExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyController;
  late final TextEditingController _titleController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(
      text: widget.workExperience?['company'] ?? '',
    );
    _titleController = TextEditingController(
      text: widget.workExperience?['title'] ?? '',
    );
    _startDateController = TextEditingController(
      text: widget.workExperience?['startDate'] ?? '',
    );
    _endDateController = TextEditingController(
      text: widget.workExperience?['endDate'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.workExperience?['description'] ?? '',
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _titleController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'company': _companyController.text,
        'title': _titleController.text,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'description': _descriptionController.text,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.workExperience == null
                    ? 'Add Work Experience'
                    : 'Edit Work Experience',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _companyController,
                        label: 'Company',
                        hint: 'e.g., Google',
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _titleController,
                        label: 'Job Title',
                        hint: 'e.g., Software Engineer',
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _startDateController,
                        label: 'Start Date',
                        hint: 'e.g., Jan 2022',
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _endDateController,
                        label: 'End Date',
                        hint: 'e.g., Present or Dec 2023',
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Brief description of your role and achievements',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
