import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/widgets/progress_indicator.dart';
import 'package:pronto/widgets/custom_text_field.dart';
import 'package:pronto/constants/colours.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pronto/router.dart';

class ProjectExperienceScreen extends StatefulWidget {
  final String? userId;

  const ProjectExperienceScreen({super.key, required this.userId});

  @override
  State<ProjectExperienceScreen> createState() =>
      _ProjectExperienceScreenState();
}

class _ProjectExperienceScreenState extends State<ProjectExperienceScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    try {
      // Load existing project data from subcollection
      final projectSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('projects')
          .get();

      if (projectSnapshot.docs.isNotEmpty) {
        setState(() {
          _projects = projectSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Store document ID for updates/deletes
            return data;
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading project data: $e')));
    }
  }

  void _addProject() {
    showDialog(
      context: context,
      builder: (context) => _ProjectDialog(
        onSave: (project) async {
          try {
            // Add to Firestore subcollection
            final docRef = await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('projects')
                .add({
                  ...project,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

            // Add to local list with document ID
            setState(() {
              project['id'] = docRef.id;
              _projects.add(project);
            });
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error adding project: $e')));
          }
        },
      ),
    );
  }

  void _editProject(int index) {
    showDialog(
      context: context,
      builder: (context) => _ProjectDialog(
        project: _projects[index],
        onSave: (project) async {
          try {
            // Update in Firestore subcollection
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('projects')
                .doc(_projects[index]['id'])
                .update({
                  ...project,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

            // Update local list
            setState(() {
              project['id'] = _projects[index]['id']; // Keep the same ID
              _projects[index] = project;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating project: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteProject(int index) async {
    try {
      // Delete from Firestore subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('projects')
          .doc(_projects[index]['id'])
          .delete();

      // Remove from local list
      setState(() {
        _projects.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting project: $e')));
    }
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      // Update user document to mark this step as completed
      // Adjust the step number based on your flow
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'completedSteps': 11, // Adjust this number
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      NavigationHelper.navigateTo('/award', arguments: widget.userId);

      // For now, just show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projects saved successfully!')),
      );
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
              'Delete "${_projects[index]['title']}"?',
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
                      _deleteProject(index);
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
        title: const CustomProgressIndicator(
          currentStep: 11,
        ), // Adjust step number
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
                        'Add your project experiences',
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
            if (_projects.isEmpty)
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
                      'No projects added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _addProject,
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
                  // Project list with swipe to delete
                  ...(_projects.asMap().entries.map((entry) {
                    final index = entry.key;
                    final project = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Slidable(
                        key: Key(project['id'] ?? index.toString()),
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
                          onTap: () => _editProject(index),
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
                                        project['title'] ?? '',
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
                                      onPressed: () => _editProject(index),
                                      icon: const Icon(Icons.edit, size: 20),
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                                if (project['organisation']?.isNotEmpty ==
                                    true) ...[
                                  Text(
                                    project['organisation'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (project['description']?.isNotEmpty ==
                                    true) ...[
                                  Text(
                                    project['description'],
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${project['startDate'] ?? ''} - ${project['endDate'] ?? ''}',
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
            // Add Project button (only shows if at least one project is added)
            if (_projects.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _addProject,
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

class _ProjectDialog extends StatefulWidget {
  final Map<String, dynamic>? project;
  final Function(Map<String, dynamic>) onSave;

  const _ProjectDialog({this.project, required this.onSave});

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
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
      text: widget.project?['title'] ?? '',
    );
    _organisationController = TextEditingController(
      text: widget.project?['organisation'] ?? '',
    );
    _startDateController = TextEditingController(
      text: widget.project?['startDate'] ?? '',
    );
    _endDateController = TextEditingController(
      text: widget.project?['endDate'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.project?['description'] ?? '',
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
                widget.project == null ? 'Add Project' : 'Edit Project',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _titleController,
                        label: 'Project Title',
                        hint: 'e.g., E-commerce Mobile App',
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _organisationController,
                        label: 'Organisation',
                        hint: 'e.g., Tech Company Pte Ltd',
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _startDateController,
                              label: 'Start Date',
                              hint: 'e.g., Jan 2023',
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _endDateController,
                              label: 'End Date',
                              hint: 'e.g., Dec 2023',
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Describe your project and contributions...',
                        maxLines: 4,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
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
