import 'package:flutter/material.dart';
import 'package:pronto/services/job_service.dart';
import 'package:pronto/models/job_model.dart';
import 'package:pronto/widgets/job_card.dart';

class ApplicantHomeScreen extends StatefulWidget {
  final String userId;

  const ApplicantHomeScreen({super.key, required this.userId});

  @override
  _ApplicantHomeScreenState createState() => _ApplicantHomeScreenState();
}

class _ApplicantHomeScreenState extends State<ApplicantHomeScreen>
    with TickerProviderStateMixin {
  final JobService _jobService = JobService();
  List<Job> _jobs = [];
  List<Map<String, String?>> _jobCompanyData = [];
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(2.0, 0.0)).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadJobs();
  }

  void _loadJobs() {
    _jobService.getJobs().listen((jobs) async {
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
      setState(() {
        _jobs = jobList;
        _jobCompanyData = jobCompanyData;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSwipe(SwipeDirection direction) async {
    if (_currentIndex >= _jobs.length) return;

    await _animationController.forward();

    if (direction == SwipeDirection.right) {
      // Apply to job
      await _jobService.applyToJob(_jobs[_currentIndex].jobID, widget.userId);
      _showSnackBar('Applied to ${_jobs[_currentIndex].title}!', Colors.green);
    } else if (direction == SwipeDirection.left) {
      // Reject job
      _showSnackBar('Job rejected', Colors.red);
    } else {
      // Skip job
      _showSnackBar('Job skipped', Colors.orange);
    }

    setState(() {
      _currentIndex++;
    });

    _animationController.reset();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // Spacer
                  Image.asset('assets/images/logo_blue_word.png', height: 30),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/job-filters');
                    },
                    icon: const Icon(Icons.tune),
                  ),
                ],
              ),
            ),

            // Card stack
            Expanded(
              child: _jobs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _currentIndex >= _jobs.length
                  ? const Center(
                      child: Text(
                        'No more jobs!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : Stack(
                      children: [
                        // Background cards (stacked effect)
                        for (int i = _currentIndex + 2; i >= _currentIndex; i--)
                          if (i < _jobs.length)
                            Positioned.fill(
                              child: Transform.translate(
                                offset: Offset(0, (i - _currentIndex) * 4.0),
                                child: JobCard(
                                  job: _jobs[i],
                                  scale: 1.0 - (i - _currentIndex) * 0.05,
                                  company: _jobCompanyData[i]['company'],
                                  companyLogoUrl:
                                      _jobCompanyData[i]['companyLogoUrl'],
                                  onTap: i == _currentIndex
                                      ? () {
                                          Navigator.pushNamed(
                                            context,
                                            '/job-details',
                                            arguments: _jobs[_currentIndex],
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ),

                        // Animated top card
                        if (_currentIndex < _jobs.length)
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset:
                                    _slideAnimation.value *
                                    MediaQuery.of(context).size.width,
                                child: Transform.rotate(
                                  angle: _rotateAnimation.value,
                                  child: Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        // Handle swipe gestures here if needed
                                      },
                                      child: JobCard(
                                        job: _jobs[_currentIndex],
                                        company:
                                            _jobCompanyData[_currentIndex]['company'],
                                        companyLogoUrl:
                                            _jobCompanyData[_currentIndex]['companyLogoUrl'],
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/job-details',
                                            arguments: _jobs[_currentIndex],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.red,
                    onPressed: () => _handleSwipe(SwipeDirection.left),
                  ),
                  _buildActionButton(
                    icon: Icons.skip_next,
                    color: Colors.orange,
                    onPressed: () => _handleSwipe(SwipeDirection.up),
                  ),
                  _buildActionButton(
                    icon: Icons.check,
                    color: Colors.green,
                    onPressed: () => _handleSwipe(SwipeDirection.right),
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
}

enum SwipeDirection { left, right, up }
