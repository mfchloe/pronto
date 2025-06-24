import 'package:flutter/material.dart';
import 'package:pronto/services/application_service.dart';
import 'package:pronto/services/job_service.dart';
import 'package:pronto/models/application_model.dart';
import 'package:pronto/models/job_model.dart';
import 'package:pronto/constants/colours.dart';
import 'package:pronto/widgets/custom_dropdown_field.dart';
import 'package:pronto/widgets/application_card.dart';

class ApplicantApplicationsScreen extends StatefulWidget {
  final String userId;

  const ApplicantApplicationsScreen({super.key, required this.userId});

  @override
  _ApplicantApplicationsScreenState createState() =>
      _ApplicantApplicationsScreenState();
}

class _ApplicantApplicationsScreenState
    extends State<ApplicantApplicationsScreen> {
  final ApplicationService _applicationService = ApplicationService();
  final JobService _jobService = JobService();
  final TextEditingController _searchController = TextEditingController();

  List<Application> _applications = [];
  List<Application> _filteredApplications = [];
  Map<String, Job> _jobsCache = {};
  Map<String, Map<String, String?>> _companyDataCache = {};
  bool _isLoading = true;

  // Filter states
  String? _statusFilter;
  String? _jobTypeFilter;
  bool? _favoriteFilter;
  String _sortBy = 'newest'; // newest, oldest

  final List<String> _statusOptions = [
    'applied',
    'interview',
    'offer',
    'rejected',
    'withdrawn',
  ];

  final List<String> _jobTypeOptions = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
    'Temporary',
  ];

  final List<String> _sortOptions = ['newest', 'oldest'];

  @override
  void initState() {
    super.initState();
    _loadApplications();
    _searchController.addListener(_filterApplications);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshApplications() async {
    _loadApplications();
  }

  void _loadApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Stream<List<Application>> applicationStream = _applicationService
          .getUserApplications(widget.userId);

      applicationStream.listen((applications) async {
        // Load job data for each application
        for (var application in applications) {
          if (!_jobsCache.containsKey(application.jobID)) {
            try {
              Job? job = await _jobService.getJobById(application.jobID);
              if (job != null) {
                _jobsCache[application.jobID] = job;

                // Get company data
                final companyData = await _jobService.getCompanyInfoFromJob(
                  job,
                );
                if (companyData != null) {
                  _companyDataCache[application.jobID] = {
                    'company': companyData['name'],
                    'companyLogoUrl': companyData['logoUrl'],
                  };
                }
              }
            } catch (e) {
              print('Error loading job ${application.jobID}: $e');
            }
          }
        }

        if (mounted) {
          setState(() {
            _applications = applications;
            _isLoading = false;
          });
          _filterApplications();
        }
      });
    } catch (e) {
      print('Error loading applications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterApplications() {
    List<Application> filtered = List.from(_applications);

    // Search filter
    String searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        Job? job = _jobsCache[app.jobID];
        String? company = _companyDataCache[app.jobID]?['company'];

        return (job?.title.toLowerCase().contains(searchQuery) ?? false) ||
            (company?.toLowerCase().contains(searchQuery) ?? false) ||
            (job?.location.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }

    // Status filter
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered
          .where(
            (app) => app.status.toLowerCase() == _statusFilter!.toLowerCase(),
          )
          .toList();
    }

    // Job type filter
    if (_jobTypeFilter != null && _jobTypeFilter!.isNotEmpty) {
      filtered = filtered.where((app) {
        Job? job = _jobsCache[app.jobID];
        return job?.jobType.toLowerCase() == _jobTypeFilter!.toLowerCase();
      }).toList();
    }

    // Favorite filter
    if (_favoriteFilter != null) {
      filtered = filtered
          .where((app) => app.favorite == _favoriteFilter)
          .toList();
    }

    // Sort by date applied
    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
    } else {
      filtered.sort((a, b) => a.appliedAt.compareTo(b.appliedAt));
    }

    setState(() {
      _filteredApplications = filtered;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Applications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _statusFilter = null;
                          _jobTypeFilter = null;
                          _favoriteFilter = null;
                          _sortBy = 'newest';
                        });
                        setState(() {
                          _statusFilter = null;
                          _jobTypeFilter = null;
                          _favoriteFilter = null;
                          _sortBy = 'newest';
                        });
                        _filterApplications();
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Status Filter Dropdown
                CustomDropdownField(
                  label: 'Status',
                  value: _statusFilter,
                  options: _statusOptions,
                  onChanged: (value) {
                    setSheetState(() {
                      _statusFilter = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Job Type Filter Dropdown
                CustomDropdownField(
                  label: 'Job Type',
                  value: _jobTypeFilter,
                  options: _jobTypeOptions,
                  onChanged: (value) {
                    setSheetState(() {
                      _jobTypeFilter = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Favorites Filter Dropdown
                CustomDropdownField(
                  label: 'Favorites',
                  value: _favoriteFilter == null
                      ? 'all'
                      : _favoriteFilter!
                      ? 'favorites'
                      : 'all', // You only support true or null in your current logic
                  options: ['all', 'favorites'],
                  hint: 'Select Favorite Filter',
                  onChanged: (value) {
                    setSheetState(() {
                      _favoriteFilter = value == 'favorites' ? true : null;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Sort By Dropdown
                CustomDropdownField(
                  label: 'Sort By Date Applied',
                  value: _sortBy,
                  options: _sortOptions,
                  onChanged: (value) {
                    setSheetState(() {
                      _sortBy = value ?? 'newest';
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Apply the filter states from the sheet to the main widget
                      });
                      _filterApplications();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
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
        ),
      ),
    );
  }

  void _toggleFavorite(Application application) async {
    try {
      await _applicationService.updateApplicationFavorite(
        widget.userId,
        application.applicationID,
        !application.favorite,
      );
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  void _updateApplicationStatus(
    Application application,
    String newStatus,
  ) async {
    try {
      await _applicationService.updateApplicationStatus(
        widget.userId,
        application.applicationID,
        newStatus,
      );
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<void> _deleteApplication(Application application) async {
    try {
      await _applicationService.deleteApplication(
        widget.userId,
        application.applicationID,
      );

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting application: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteOption(
    BuildContext context,
    Application application,
    Job? job,
    Map<String, String?>? companyData,
  ) {
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
              'Delete application for "${job?.title ?? 'Unknown Position'}" at ${companyData?['company'] ?? 'Unknown Company'}?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
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
                      _deleteApplication(application);
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Colors.blue;
      case 'interview':
        return Colors.orange;
      case 'offer':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search applications...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              25,
                            ), // More rounded
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter button
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: Colors.grey[700],
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Applications List with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshApplications,
                // Custom refresh indicator styling (not working rn)
                color: AppColors.primary,
                backgroundColor: Colors.white,
                displacement: 40,
                strokeWidth: 2.5,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredApplications.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No applications found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search or filters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredApplications.length,
                        itemBuilder: (context, index) {
                          final application = _filteredApplications[index];
                          final job = _jobsCache[application.jobID];
                          final companyData =
                              _companyDataCache[application.jobID];

                          return ApplicationCard(
                            application: application,
                            job: job,
                            companyData: companyData,
                            statusOptions: _statusOptions,
                            onDelete: () => _showDeleteOption(
                              context,
                              application,
                              job,
                              companyData,
                            ),
                            onToggleFavorite: () =>
                                _toggleFavorite(application),
                            onUpdateStatus: (newStatus) =>
                                _updateApplicationStatus(
                                  application,
                                  newStatus,
                                ),
                            timeAgo: _getTimeAgo(application.appliedAt),
                            getStatusColor: _getStatusColor,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
