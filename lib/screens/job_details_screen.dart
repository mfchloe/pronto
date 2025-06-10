import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pronto/models/job_model.dart';
import 'package:pronto/constants/colours.dart';
import 'package:pronto/services/job_service.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  _JobDetailsScreenState createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final JobService _jobService = JobService();
  String? _company;
  String? _companyLogoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  void _loadCompanyInfo() async {
    final companyData = await _jobService.getCompanyInfoFromJob(widget.job);
    if (mounted) {
      setState(() {
        _company = companyData?['name'];
        _companyLogoUrl = companyData?['logoUrl'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _launchURL(widget.job.link),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // Company logo
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _companyLogoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  _companyLogoUrl!,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.business,
                                      color: Colors.grey,
                                      size: 35,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.business,
                                color: Colors.grey,
                                size: 35,
                              ),
                      ),
                const SizedBox(height: 12),
                // Job title
                Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Company name
                Text(
                  _company ?? 'Company Name',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Job details container
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Posted date
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Posted ${widget.job.daysAgo}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location and work arrangement
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.job.location} (${widget.job.workArrangement})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.job.payString.isNotEmpty)
                          _buildTag(
                            icon: Icons.attach_money,
                            text: widget.job.payString,
                            color: Colors.green,
                          ),
                        if (widget.job.duration.isNotEmpty)
                          _buildTag(
                            icon: Icons.access_time,
                            text: widget.job.duration,
                            color: Colors.blue,
                          ),
                        if (widget.job.jobType.isNotEmpty)
                          _buildTag(
                            icon: Icons.work,
                            text: widget.job.jobType,
                            color: Colors.purple,
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Job description
                    const Text(
                      'Job Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.job.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
