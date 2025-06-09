import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:pronto/services/job_service.dart';
import 'package:pronto/models/job_model.dart';
import 'package:pronto/widgets/job_card.dart';

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

  @override
  void initState() {
    super.initState();
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

      if (mounted) {
        setState(() {
          _jobs = jobList;
          _jobCompanyData = jobCompanyData;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
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
        _handleSkip(previousIndex);
        break;
      case CardSwiperDirection.bottom:
        _handleSkip(previousIndex);
        break;
      case CardSwiperDirection.none:
        // No action needed for 'none'
        break;
    }

    return true;
  }

  void _handleApply(int index) async {
    await _jobService.applyToJob(_jobs[index].jobID, widget.userId);
  }

  void _handleReject(int index) {
    // make sure job won't show up again
  }

  void _handleSkip(int index) {
    // job can still show up again
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

            // Card swiper
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _jobs.isEmpty
                  ? const Center(
                      child: Text(
                        'No jobs available!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
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
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/job-details',
                                arguments: _jobs[index],
                              );
                            },
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
}
