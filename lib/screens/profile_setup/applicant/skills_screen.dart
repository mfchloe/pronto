import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/widgets/progress_indicator.dart';
import 'package:pronto/constants.dart';
import 'package:pronto/router.dart';

class SkillsScreen extends StatefulWidget {
  final String? userId;

  const SkillsScreen({super.key, required this.userId});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final _customSkillController = TextEditingController();
  List<String> _selectedSkills = [];
  bool _isLoading = false;

  final List<String> _availableSkills = [
    'Programming',
    'Web Development',
    'Mobile Development',
    'Data Analysis',
    'Digital Marketing',
    'Graphic Design',
    'UI/UX Design',
    'Project Management',
    'Communication',
    'Leadership',
    'Problem Solving',
    'Critical Thinking',
    'Teamwork',
    'Time Management',
    'Public Speaking',
    'Writing',
    'Research',
    'Sales',
    'Social Media',
  ];

  @override
  void dispose() {
    _customSkillController.dispose();
    super.dispose();
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  void _addCustomSkill() {
    final customSkill = _customSkillController.text.trim();
    if (customSkill.isNotEmpty &&
        !_selectedSkills.contains(customSkill) &&
        !_availableSkills.contains(customSkill)) {
      setState(() {
        _selectedSkills.add(customSkill);
        _customSkillController.clear();
      });
    }
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'skills': _selectedSkills,
            'completedSteps': 6,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      NavigationHelper.navigateTo('/social', arguments: widget.userId);
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
        title: const CustomProgressIndicator(currentStep: 6),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What are your skills?',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select skills that showcase your abilities and expertise',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Available skills (predefined)
                ..._availableSkills.map(
                  (skill) => GestureDetector(
                    onTap: () => _toggleSkill(skill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedSkills.contains(skill)
                            ? AppColors.primary
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          color: _selectedSkills.contains(skill)
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                // Custom skills (user added)
                ..._selectedSkills
                    .where((skill) => !_availableSkills.contains(skill))
                    .map(
                      (skill) => GestureDetector(
                        onTap: () => _toggleSkill(skill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 24),
            // Custom skill input field (always visible)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 51),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customSkillController,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add your own skill',
                        hintStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onSubmitted: (_) => _addCustomSkill(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: _addCustomSkill,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(60, 40),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedSkills.isEmpty
                    ? null
                    : _saveToFirebase,
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
