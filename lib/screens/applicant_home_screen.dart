import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:pronto/services/job_service.dart';
import 'package:pronto/models/job_model.dart';
import 'package:pronto/widgets/job_card.dart';
import 'package:pronto/screens/job_filters_screen.dart';
import 'package:pronto/router.dart';
import 'dart:async';

class ApplicantHomeScreen extends StatefulWidget {
  final String userId;

  const ApplicantHomeScreen({super.key, required this.userId});

  @override
  _ApplicantHomeScreenState createState() => _ApplicantHomeScreenState();
}

class _ApplicantHomeScreenState extends State<ApplicantHomeScreen> {
  final JobService _jobService = JobService();
  final CardSwiperController _cardController = CardSwiperController();

  List<Job> _jobs = [];
  List<Map<String, String?>> _jobCompanyData = [];
  bool _isLoading = true;
  Map<String, dynamic>? _currentFilters;
  String? _resume;

  // Auto-swipe functionality
  bool _isAutoSwipeEnabled = false;
  Timer? _autoSwipeTimer;
  static const Duration _autoSwipeInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _loadFiltersAndJobs();
  }

  void _loadFiltersAndJobs() async {
    // Load user filters first
    _currentFilters = await _jobService.getUserFilters(widget.userId);
    if (_currentFilters != null) {
      _resume = _currentFilters!['resume'];
    }
    _loadJobs();
  }

  void _loadJobs() {
    // Apply filters from user preferences
    Stream<List<Job>> jobStream = _jobService.getJobs(
      industry: _currentFilters?['industry'],
      jobType: _currentFilters?['jobType'],
      workArrangement: _currentFilters?['workArrangement'],
      duration: _currentFilters?['duration'],
      minSalary: _currentFilters?['minSalary']?.toDouble(),
      maxSalary: _currentFilters?['maxSalary']?.toDouble(),
      jobTitles: _currentFilters?['jobTitles'] != null
          ? List<String>.from(_currentFilters!['jobTitles'])
          : null,
      userId: widget.userId,
    );

    jobStream.listen((jobs) async {
      List<Job> jobList = [];
      List<Map<String, String?>> jobCompanyData = [];

      for (var job in jobs) {
        final companyData = await _jobService.getCompanyInfoFromJob(job);
        if (companyData != null) {
          jobList.add(job);
          jobCompanyData.add({
            'company': companyData['name'],
            'companyLogoUrl': companyData['logoUrl'],
          });
        }
      }

      if (mounted) {
        setState(() {
          _jobs = jobList;
          _jobCompanyData = jobCompanyData;
          _isLoading = false;
        });
      }
    });
  }

  void _toggleAutoSwipe() {
    setState(() {
      _isAutoSwipeEnabled = !_isAutoSwipeEnabled;
    });

    if (_isAutoSwipeEnabled) {
      _startAutoSwipe();
    } else {
      _stopAutoSwipe();
    }
  }

  void _startAutoSwipe() {
    _autoSwipeTimer = Timer.periodic(_autoSwipeInterval, (timer) {
      if (_jobs.isNotEmpty && mounted) {
        _cardController.swipe(CardSwiperDirection.right);
      } else {
        _stopAutoSwipe();
      }
    });
  }

  void _stopAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = null;
  }

  @override
  void dispose() {
    _stopAutoSwipe();
    _cardController.dispose();
    super.dispose();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (previousIndex >= _jobs.length) return false;

    switch (direction) {
      case CardSwiperDirection.right:
        _handleApply(previousIndex);
        break;
      case CardSwiperDirection.left:
        _handleReject(previousIndex);
        break;
      case CardSwiperDirection.top:
        break;
      case CardSwiperDirection.bottom:
        break;
      case CardSwiperDirection.none:
        // No action needed for 'none'
        break;
    }

    // Stop auto-swipe if we've run out of jobs
    if (currentIndex == null && _isAutoSwipeEnabled) {
      _toggleAutoSwipe();
    }

    return true;
  }

  void _handleApply(int index) async {
    await _jobService.applyToJob(_jobs[index].jobID, widget.userId, _resume);
  }

  void _handleReject(int index) async {
    // Mark job as rejected so it won't show up again
    await _jobService.markJobAsRejected(_jobs[index].jobID, widget.userId);
  }

  void _navigateToFilters() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobFiltersScreen(userId: widget.userId),
      ),
    );

    // Reload jobs with updated filters when returning from filters screen
    if (result != null || result == true) {
      setState(() {
        _isLoading = true;
      });
      _loadFiltersAndJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left: Auto-swipe toggle
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Auto',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _isAutoSwipeEnabled
                                ? Colors.green
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Switch(
                          value: _isAutoSwipeEnabled,
                          onChanged: (_) => _toggleAutoSwipe(),
                          activeColor: Colors.white,
                          activeTrackColor: Colors.green,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey[300],
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),

                  // Center: Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo_blue_word.png',
                      height: 30,
                    ),
                  ),

                  // Right: Filter button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: _navigateToFilters,
                      icon: const Icon(Icons.tune),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active filters display
            if (_currentFilters != null && _hasActiveFilters())
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getActiveFiltersText(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToFilters,
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Card swiper
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _jobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.work_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No jobs available!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _navigateToFilters,
                            child: const Text('Update Filters'),
                          ),
                        ],
                      ),
                    )
                  : CardSwiper(
                      controller: _cardController,
                      cardsCount: _jobs.length,
                      onSwipe: _onSwipe,
                      numberOfCardsDisplayed: 3,
                      backCardOffset: const Offset(0, -40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      cardBuilder:
                          (
                            context,
                            index,
                            horizontalThresholdPercentage,
                            verticalThresholdPercentage,
                          ) => JobCard(
                            job: _jobs[index],
                            company: _jobCompanyData[index]['company'],
                            companyLogoUrl:
                                _jobCompanyData[index]['companyLogoUrl'],
                            onTap: () => NavigationHelper.navigateTo(
                              '/job-details',
                              arguments: _jobs[index],
                            ),
                          ),
                    ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.red,
                    onPressed: () {
                      _cardController.swipe(CardSwiperDirection.left);
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.skip_next,
                    color: Colors.orange,
                    onPressed: () {
                      _cardController.swipe(CardSwiperDirection.top);
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.check,
                    color: Colors.green,
                    onPressed: () {
                      _cardController.swipe(CardSwiperDirection.right);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 28),
      ),
    );
  }

  bool _hasActiveFilters() {
    if (_currentFilters == null) return false;

    return (_currentFilters!['industry'] != null &&
            _currentFilters!['industry'].isNotEmpty) ||
        (_currentFilters!['jobType'] != null &&
            _currentFilters!['jobType'].isNotEmpty) ||
        (_currentFilters!['workArrangement'] != null &&
            _currentFilters!['workArrangement'].isNotEmpty) ||
        (_currentFilters!['duration'] != null &&
            _currentFilters!['duration'].isNotEmpty) ||
        (_currentFilters!['jobTitles'] != null &&
            (_currentFilters!['jobTitles'] as List).isNotEmpty) ||
        (_currentFilters!['minSalary'] != null &&
            _currentFilters!['minSalary'] > 0) ||
        (_currentFilters!['maxSalary'] != null &&
            _currentFilters!['maxSalary'] < 200000) ||
        (_currentFilters!['resume'] != null &&
            _currentFilters!['resume'].isNotEmpty);
  }

  String _getActiveFiltersText() {
    List<String> activeFilters = [];

    if (_currentFilters!['industry'] != null &&
        _currentFilters!['industry'].isNotEmpty) {
      activeFilters.add(_currentFilters!['industry']);
    }
    if (_currentFilters!['jobType'] != null &&
        _currentFilters!['jobType'].isNotEmpty) {
      activeFilters.add(_currentFilters!['jobType']);
    }
    if (_currentFilters!['workArrangement'] != null &&
        _currentFilters!['workArrangement'].isNotEmpty) {
      activeFilters.add(_currentFilters!['workArrangement']);
    }
    if (_currentFilters!['jobTitles'] != null &&
        (_currentFilters!['jobTitles'] as List).isNotEmpty) {
      activeFilters.add(
        '${(_currentFilters!['jobTitles'] as List).length} job titles',
      );
    }

    if (activeFilters.isEmpty) {
      return 'Filters applied';
    }

    if (activeFilters.length <= 2) {
      return activeFilters.join(', ');
    } else {
      return '${activeFilters.take(2).join(', ')} +${activeFilters.length - 2} more';
    }
  }
}
