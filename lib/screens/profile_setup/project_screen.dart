import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/progress_indicator.dart';
import '../../widgets/custom_text_field.dart';
import 'package:pronto/constants.dart';
import 'award_screen.dart';

class ProjectExperienceScreen extends StatefulWidget {
  final String userEmail;

  const ProjectExperienceScreen({super.key, required this.userEmail});

  @override
  State<ProjectExperienceScreen> createState() =>
      _ProjectExperienceScreenState();
}

class _ProjectExperienceScreenState extends State<ProjectExperienceScreen> {
  List<Map<String, dynamic>> _projectExperiences = [];
  bool _isLoading = false;

  void _addProjectExperience() {
    showDialog(
      context: context,
      builder: (context) => _ProjectExperienceDialog(
        onSave: (projectExperience) {
          setState(() {
            _projectExperiences.add(projectExperience);
          });
        },
      ),
    );
  }

  void _editProjectExperience(int index) {
    showDialog(
      context: context,
      builder: (context) => _ProjectExperienceDialog(
        projectExperience: _projectExperiences[index],
        onSave: (projectExperience) {
          setState(() {
            _projectExperiences[index] = projectExperience;
          });
        },
      ),
    );
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .update({
            'projectExperience': _projectExperiences,
            'completedSteps': 11,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AwardScreen(userEmail: widget.userEmail),
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
        title: const CustomProgressIndicator(currentStep: 11),
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
                        'Project Experience',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Showcase your projects and contributions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _addProjectExperience,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_projectExperiences.isEmpty)
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
                      Icons.folder_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No projects added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _addProjectExperience,
                      child: const Text('Add Project'),
                    ),
                  ],
                ),
              )
            else
              ...(_projectExperiences.asMap().entries.map((entry) {
                final index = entry.key;
                final project = entry.value;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project['title'],
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _editProjectExperience(index),
                                icon: const Icon(Icons.edit, size: 20),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _projectExperiences.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.delete, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        project['organisation'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${project['startDate']} - ${project['endDate']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (project['description'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          project['description'],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              })),
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

class _ProjectExperienceDialog extends StatefulWidget {
  final Map<String, dynamic>? projectExperience;
  final Function(Map<String, dynamic>) onSave;

  const _ProjectExperienceDialog({
    this.projectExperience,
    required this.onSave,
  });

  @override
  State<_ProjectExperienceDialog> createState() =>
      _ProjectExperienceDialogState();
}

class _ProjectExperienceDialogState extends State<_ProjectExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _organisationController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.projectExperience?['title'] ?? '',
    );
    _organisationController = TextEditingController(
      text: widget.projectExperience?['organisation'] ?? '',
    );
    _startDateController = TextEditingController(
      text: widget.projectExperience?['startDate'] ?? '',
    );
    _endDateController = TextEditingController(
      text: widget.projectExperience?['endDate'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.projectExperience?['description'] ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _organisationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'title': _titleController.text,
        'organisation': _organisationController.text,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'description': _descriptionController.text,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.projectExperience == null ? 'Add Project' : 'Edit Project',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Project Title',
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _organisationController,
                label: 'Organisation',
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _startDateController,
                label: 'Start Date',
                hint: 'e.g., Jan 2020',
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _endDateController,
                label: 'End Date',
                hint: 'e.g., Dec 2024 or Present',
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Brief description of the project and your contributions',
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
