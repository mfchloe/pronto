import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/progress_indicator.dart';
import 'package:pronto/constants.dart';
import '../../widgets/custom_text_field.dart';
import 'social_screen.dart';

class SkillsScreen extends StatefulWidget {
  final String userEmail;

  const SkillsScreen({super.key, required this.userEmail});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final _skillController = TextEditingController();
  List<String> _skills = [];
  bool _isLoading = false;

  final List<String> _suggestedSkills = [
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
    'Customer Service',
    'Social Media',
  ];

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill(String skill) {
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
      });
      _skillController.clear();
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .update({
            'skills': _skills,
            'completedSteps': 6,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SocialsScreen(userEmail: widget.userEmail),
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
              'Add skills that showcase your abilities and expertise',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _skillController,
                    label: 'Add Skill',
                    hint: 'Type a skill and press Add',
                    onFieldSubmitted: _addSkill,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _addSkill(_skillController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_suggestedSkills.isNotEmpty) ...[
              Text(
                'Suggested Skills',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedSkills
                    .where((skill) => !_skills.contains(skill))
                    .map(
                      (skill) => GestureDetector(
                        onTap: () => _addSkill(skill),
                        child: Chip(
                          label: Text(skill),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 128),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (_skills.isNotEmpty) ...[
              Text(
                'Your Skills',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 26,
                        ),
                        onDeleted: () => _removeSkill(skill),
                        deleteIconColor: AppColors.primary,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 40),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _skills.isEmpty
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
