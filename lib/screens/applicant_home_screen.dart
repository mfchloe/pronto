import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:pronto/services/job_service.dart';
import 'package:pronto/models/job_model.dart';
import 'package:pronto/widgets/job_card.dart';
import 'package:pronto/screens/job_filters_screen.dart';
import 'package:pronto/router.dart';
import 'package:pronto/constants/colours.dart';
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
  String? _resumeUrl;
  int _currentCardIndex = 0;

  // Track jobs that have been swiped in this session
  Set<String> _swipedJobIds = {};

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
      _resumeUrl = _currentFilters!['resumeUrl'];
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
      jobRecency: _currentFilters?['jobRecency'],
      minSalary: _currentFilters?['minSalary']?.toDouble(),
      maxSalary: _currentFilters?['maxSalary']?.toDouble(),
      jobTitles: _currentFilters?['jobTitles'] != null
          ? List<String>.from(_currentFilters!['jobTitles'])
          : null,
      userId: widget.userId,
    );

    jobStream.listen(
      (jobs) async {
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
          // Calculate how many jobs we've lost due to filtering
          int previousJobCount = _jobs.length;
          int currentJobCount = jobList.length;

          setState(() {
            _jobs = jobList;
            _jobCompanyData = jobCompanyData;
            _isLoading = false;

            // Adjust current index based on how many jobs were removed
            if (previousJobCount > currentJobCount && _currentCardIndex > 0) {
              int jobsRemoved = previousJobCount - currentJobCount;
              _currentCardIndex = (_currentCardIndex - jobsRemoved).clamp(
                0,
                jobList.length,
              );
              print(
                'Jobs reduced from $previousJobCount to $currentJobCount, adjusted index to $_currentCardIndex',
              );
            }

            // If we have no more jobs, stop auto-swipe
            if (jobList.isEmpty || _currentCardIndex >= jobList.length) {
              print('No more jobs available, stopping auto-swipe');
              _stopAutoSwipe();
            }
          });
        }
      },
      onError: (error) {
        print('Error loading jobs: $error');
        if (mounted) {
          setState(() {
            _jobs = [];
            _jobCompanyData = [];
            _isLoading = false;
            _currentCardIndex = 0;
          });
          _stopAutoSwipe();
        }
      },
    );
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
      if (!mounted || !_isAutoSwipeEnabled) {
        _stopAutoSwipe();
        return;
      }

      // Check if there are still cards to swipe
      if (_jobs.isEmpty || _currentCardIndex >= _jobs.length) {
        print(
          'No more cards to swipe. Current index: $_currentCardIndex, Jobs length: ${_jobs.length}',
        );
        _stopAutoSwipe();
        return;
      }

      print('Auto-swiping at index $_currentCardIndex of ${_jobs.length}');
      _cardController.swipe(CardSwiperDirection.right);
    });
  }

  void _stopAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = null;
    if (_isAutoSwipeEnabled) {
      setState(() {
        _isAutoSwipeEnabled = false;
      });
    }
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
    print(
      'Swipe event - Previous: $previousIndex, Current: $currentIndex, Direction: $direction, Jobs length: ${_jobs.length}',
    );

    // Validate previousIndex to prevent out-of-bounds access
    if (previousIndex < 0 || previousIndex >= _jobs.length) {
      print(
        'Invalid previousIndex: $previousIndex for jobs length: ${_jobs.length}',
      );
      return false;
    }

    // Track this job as swiped
    String swipedJobId = _jobs[previousIndex].jobID;
    _swipedJobIds.add(swipedJobId);
    print(
      'Added job ${swipedJobId} to swiped jobs. Total swiped: ${_swipedJobIds.length}',
    );

    // Handle the swipe action
    switch (direction) {
      case CardSwiperDirection.right:
        _handleApply(previousIndex);
        break;
      case CardSwiperDirection.left:
        _handleReject(previousIndex);
        break;
      case CardSwiperDirection.top:
        // Skip action - no backend call needed but still track as swiped
        break;
      case CardSwiperDirection.bottom:
        break;
      case CardSwiperDirection.none:
        break;
    }

    // Update current card index
    if (currentIndex != null && currentIndex >= 0) {
      _currentCardIndex = currentIndex;
    } else {
      // If currentIndex is null, we've reached the end
      _currentCardIndex = _jobs.length;
    }

    print('Updated current card index to: $_currentCardIndex');

    // Stop auto-swipe if we've run out of cards
    if (_currentCardIndex >= _jobs.length) {
      print('Reached end of cards, stopping auto-swipe');
      _stopAutoSwipe();
    }

    return true;
  }

  void _handleApply(int index) async {
    // Double-check bounds before accessing
    if (index >= 0 && index < _jobs.length) {
      try {
        await _jobService.applyToJob(
          _jobs[index].jobID,
          widget.userId,
          _resumeUrl,
        );
        print('Applied to job at index $index');
      } catch (e) {
        print('Error applying to job: $e');
      }
    } else {
      print('Invalid index for apply: $index');
    }
  }

  void _handleReject(int index) async {
    // Double-check bounds before accessing
    if (index >= 0 && index < _jobs.length) {
      try {
        await _jobService.markJobAsRejected(_jobs[index].jobID, widget.userId);
        print('Rejected job at index $index');
      } catch (e) {
        print('Error rejecting job: $e');
      }
    } else {
      print('Invalid index for reject: $index');
    }
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
      // Stop auto-swipe when reloading and clear swiped jobs
      _stopAutoSwipe();
      _swipedJobIds.clear(); // Reset swiped jobs when changing filters
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
                            _swipedJobIds.isEmpty
                                ? 'No jobs available!'
                                : 'No more jobs!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _swipedJobIds.isEmpty
                                ? 'Try adjusting your filters'
                                : 'You\'ve seen all available jobs',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _swipedJobIds.clear(); // Clear swiped jobs
                              _navigateToFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _swipedJobIds.isEmpty
                                  ? 'Update Filters'
                                  : 'Change Filters',
                            ),
                          ),
                        ],
                      ),
                    )
                  : CardSwiper(
                      controller: _cardController,
                      cardsCount: _jobs.length,
                      onSwipe: _onSwipe,
                      numberOfCardsDisplayed: _jobs.length >= 3
                          ? 3
                          : _jobs.length,
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
                          ) {
                            // Additional safety check in cardBuilder
                            if (index < 0 ||
                                index >= _jobs.length ||
                                index >= _jobCompanyData.length) {
                              return Container(); // Return empty container for invalid indices
                            }

                            return JobCard(
                              job: _jobs[index],
                              company: _jobCompanyData[index]['company'],
                              companyLogoUrl:
                                  _jobCompanyData[index]['companyLogoUrl'],
                              onTap: () => NavigationHelper.navigateTo(
                                '/job-details',
                                arguments: _jobs[index],
                              ),
                            );
                          },
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
                    onPressed: _jobs.isEmpty
                        ? null
                        : () {
                            _cardController.swipe(CardSwiperDirection.left);
                          },
                  ),
                  _buildActionButton(
                    icon: Icons.skip_next,
                    color: Colors.orange,
                    onPressed: _jobs.isEmpty
                        ? null
                        : () {
                            _cardController.swipe(CardSwiperDirection.top);
                          },
                  ),
                  _buildActionButton(
                    icon: Icons.check,
                    color: Colors.green,
                    onPressed: _jobs.isEmpty
                        ? null
                        : () {
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
    required VoidCallback? onPressed, // Made nullable
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(onPressed != null ? 0.1 : 0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: onPressed != null ? color : color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null ? color : color.withOpacity(0.3),
          size: 28,
        ),
      ),
    );
  }
}
