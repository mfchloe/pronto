import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/constants/colours.dart';
import 'package:pronto/widgets/custom_text_field.dart';
import 'package:pronto/widgets/custom_dropdown_field.dart';
import 'package:pronto/constants/job_attributes.dart';

class JobFiltersScreen extends StatefulWidget {
  final String userId;

  const JobFiltersScreen({super.key, required this.userId});

  @override
  _JobFiltersScreenState createState() => _JobFiltersScreenState();
}

class _JobFiltersScreenState extends State<JobFiltersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Filter values
  List<String> _jobTitles = [];
  String? _selectedIndustry;
  String? _selectedWorkArrangement;
  String? _selectedJobType;
  String? _selectedDuration;
  String? _selectedJobRecency;
  double _minSalary = 0;
  double _maxSalary = 50000;
  String? _selectedResumeKey;
  String? _selectedResumeUrl;
  Map<String, dynamic> _userResumes = {};

  // Controllers
  final TextEditingController _jobTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserResumes();
    _loadSavedFilters();
  }

  void _loadUserResumes() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['resumes'] != null) {
          setState(() {
            _userResumes = userData['resumes'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user resumes: $e');
    }
  }

  void _loadSavedFilters() async {
    try {
      final filtersDoc = await _firestore
          .collection('userFilters')
          .doc(widget.userId)
          .get();

      if (filtersDoc.exists) {
        final filters = filtersDoc.data()!;
        setState(() {
          _jobTitles = List<String>.from(filters['jobTitles'] ?? []);
          _selectedIndustry = filters['industry'];
          _selectedWorkArrangement = filters['workArrangement'];
          _selectedJobType = filters['jobType'];
          _selectedDuration = filters['duration'];
          _selectedJobRecency = filters['jobRecency'] ?? 'Any time';
          _minSalary = (filters['minSalary'] ?? 0).toDouble();
          _maxSalary = (filters['maxSalary'] ?? 50000).toDouble();

          // Handle resume data - check for both old and new format
          if (filters['resumeUrl'] != null) {
            _selectedResumeUrl = filters['resumeUrl'];
            _selectedResumeKey = filters['resumeType'] ?? 'General';
          } else if (filters['selectedResume'] != null) {
            // Legacy format - try to find matching resume URL
            _selectedResumeKey = filters['selectedResume'];
            if (_userResumes.containsKey(_selectedResumeKey)) {
              _selectedResumeUrl = _userResumes[_selectedResumeKey]?['url'];
            }
          } else {
            // Default to General Resume
            _selectedResumeKey = 'General';
            if (_userResumes.containsKey('General')) {
              _selectedResumeUrl = _userResumes['General']?['url'];
            }
          }
        });
      } else {
        // Set default values if no saved filters
        setState(() {
          _selectedResumeKey = 'General';
          _selectedJobRecency = 'Any time';
          if (_userResumes.containsKey('General')) {
            _selectedResumeUrl = _userResumes['General']?['url'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved filters: $e');
      // Set default values on error
      setState(() {
        _selectedResumeKey = 'General';
        _selectedJobRecency = 'Any time';
        if (_userResumes.containsKey('General')) {
          _selectedResumeUrl = _userResumes['General']?['url'];
        }
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _jobTitles.clear();
      _selectedIndustry = null;
      _selectedWorkArrangement = null;
      _selectedJobType = null;
      _selectedDuration = null;
      _selectedJobRecency = 'Any time';
      _minSalary = 0;
      _maxSalary = 50000;
      _selectedResumeKey = 'General';
      if (_userResumes.containsKey('General')) {
        _selectedResumeUrl = _userResumes['General']?['url'];
      }
    });
    _jobTitleController.clear();
  }

  void _saveFilters() async {
    try {
      await _firestore.collection('userFilters').doc(widget.userId).set({
        'jobTitles': _jobTitles,
        'industry': _selectedIndustry,
        'workArrangement': _selectedWorkArrangement,
        'jobType': _selectedJobType,
        'duration': _selectedDuration,
        'jobRecency': _selectedJobRecency,
        'minSalary': _minSalary,
        'maxSalary': _maxSalary,
        'resumeType': _selectedResumeKey,
        'resumeUrl': _selectedResumeUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filters saved successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving filters: $e')));
    }
  }

  void _addJobTitle() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Job Title'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: controller,
                  label: 'Job Title',
                  hint: 'Enter job title...',
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isNotEmpty && !_jobTitles.contains(title)) {
                  setState(() => _jobTitles.add(title));
                }
                Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        automaticallyImplyLeading: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: TextButton(
              onPressed: _clearAllFilters,
              child: Text(
                'Clear',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Titles Section
            _buildJobTitlesSection(),
            const SizedBox(height: 24),

            // Industry Section
            const SizedBox(height: 12),
            CustomDropdownField(
              label: 'Industry',
              value: _selectedIndustry,
              hint: 'Select Industry',
              options: kIndustries,
              onChanged: (value) => setState(() => _selectedIndustry = value),
            ),
            const SizedBox(height: 24),

            // Work Arrangement Section
            const SizedBox(height: 12),
            CustomDropdownField(
              label: 'Work Arrangement',
              value: _selectedWorkArrangement,
              hint: 'Select Work Arrangement',
              options: kWorkArrangements,
              onChanged: (value) =>
                  setState(() => _selectedWorkArrangement = value),
            ),
            const SizedBox(height: 24),

            // Job Type Section
            const SizedBox(height: 12),
            CustomDropdownField(
              label: 'Job Type',
              value: _selectedJobType,
              hint: 'Select Job Type',
              options: kJobTypes,
              onChanged: (value) => setState(() => _selectedJobType = value),
            ),
            const SizedBox(height: 24),

            // Duration Section
            const SizedBox(height: 12),
            CustomDropdownField(
              label: 'Duration',
              value: _selectedDuration,
              hint: 'Select Duration',
              options: kDurations,
              onChanged: (value) => setState(() => _selectedDuration = value),
            ),
            const SizedBox(height: 24),

            // Job Recency Section
            const SizedBox(height: 12),
            CustomDropdownField(
              label: 'Job Recency',
              value: _selectedJobRecency,
              hint: 'Select when job was posted',
              options: kJobRecencyOptions,
              onChanged: (value) => setState(() => _selectedJobRecency = value),
            ),
            const SizedBox(height: 24),

            // Salary Range Section
            _buildSalarySlider(),
            const SizedBox(height: 24),

            // Select Resume Section
            _buildResumeSection(),
            const SizedBox(height: 32),

            // Apply Filters Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSalarySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salary Range (per month)',
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
                    'Salary: \$${_minSalary.toInt()} - \$${_maxSalary.toInt()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '0 - 50,000',
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
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                ),
                child: RangeSlider(
                  values: RangeValues(_minSalary, _maxSalary),
                  min: 0,
                  max: 50000,
                  divisions: 50,
                  onChanged: (values) {
                    setState(() {
                      _minSalary = values.start;
                      _maxSalary = values.end;
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

  Widget _buildResumeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Resume',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
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
          child: _userResumes.isEmpty
              ? Text(
                  'No resumes available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _userResumes.keys.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final key = _userResumes.keys.elementAt(index);
                      final resume = _userResumes[key];
                      final isSelected = _selectedResumeKey == key;

                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedResumeKey = key;
                          _selectedResumeUrl = resume['url'];
                        }),
                        child: Container(
                          width: 180,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withValues(
                                      alpha: 51,
                                    ),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  key,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  resume['fileName'] ?? '',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.8)
                                            : AppColors.textSecondary,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildJobTitlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Job Titles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _addJobTitle,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
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
          child: _jobTitles.isEmpty
              ? Text(
                  'No job titles added yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _jobTitles
                      .map(
                        (title) => Chip(
                          label: Text(title),
                          backgroundColor: AppColors.primary,
                          deleteIcon: const Icon(Icons.close, size: 16),
                          deleteIconColor: Colors.white,
                          labelStyle: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                          onDeleted: () {
                            setState(() => _jobTitles.remove(title));
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    super.dispose();
  }
}
