import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_dropdown_field.dart';
import '../../../widgets/progress_indicator.dart';
import 'package:pronto/constants.dart';
import 'designation_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String userEmail;

  const PersonalDetailsScreen({super.key, required this.userEmail});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _preferredNameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedAge = 18;
  String _selectedGender = '';
  String _selectedRace = '';
  Map<String, String> _languages = {};
  bool _isLoading = false;

  final List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  final List<String> _races = [
    'Chinese',
    'Malay',
    'Indian',
    'Eurasian',
    'Others',
    'Prefer not to say',
  ];

  final List<String> _availableLanguages = [
    'English',
    'Mandarin',
    'Malay',
    'Tamil',
    'Japanese',
    'Korean',
    'Spanish',
    'French',
    'German',
  ];

  final List<String> _proficiencyLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Native',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _preferredNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveToFirebase() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .set({
            'personalDetails': {
              'name': _nameController.text,
              'preferredName': _preferredNameController.text,
              'email': widget.userEmail,
              'phoneNumber': _phoneController.text,
              'age': _selectedAge,
              'gender': _selectedGender,
              'race': _selectedRace,
              'languages': _languages,
            },
            'completedSteps': 1,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DesignationScreen(userEmail: widget.userEmail),
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

  void _addLanguage() {
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
                    options: _availableLanguages
                        .where((lang) => !_languages.containsKey(lang))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedLanguage = value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  CustomDropdownField(
                    label: 'Proficiency',
                    value: selectedProficiency,
                    options: _proficiencyLevels,
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
                          setState(() {
                            _languages[selectedLanguage] = selectedProficiency;
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const CustomProgressIndicator(currentStep: 1),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about yourself',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We need some basic information to personalize your experience',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full legal name',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _preferredNameController,
                label: 'Preferred Name',
                hint: 'What should we call you?',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your preferred name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+65 XXXX XXXX',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(
                    r'^\+65\s?\d{4}\s?\d{4}$|^\d{8}$',
                  ).hasMatch(value!)) {
                    return 'Please enter a valid Singapore phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildAgeSlider(),
              const SizedBox(height: 24),
              CustomDropdownField(
                label: 'Gender',
                value: _selectedGender,
                options: _genders,
                onChanged: (value) =>
                    setState(() => _selectedGender = value ?? ''),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomDropdownField(
                label: 'Race',
                value: _selectedRace,
                options: _races,
                onChanged: (value) =>
                    setState(() => _selectedRace = value ?? ''),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please select your race';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildLanguagesSection(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _saveToFirebase();
                          }
                        },
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 51),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Age: $_selectedAge',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '16 - 80',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.textSecondary.withValues(
                    alpha: 51,
                  ),
                  thumbColor: AppColors.primary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _selectedAge.toDouble(),
                  min: 16,
                  max: 80,
                  divisions: 64,
                  onChanged: (value) {
                    setState(() {
                      _selectedAge = value.round();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Languages',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _addLanguage,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
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
          child: _languages.isEmpty
              ? Text(
                  'No languages added yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _languages.entries
                      .map(
                        (entry) => Chip(
                          label: Text('${entry.key} - ${entry.value}'),
                          onDeleted: () {
                            setState(() {
                              _languages.remove(entry.key);
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}
