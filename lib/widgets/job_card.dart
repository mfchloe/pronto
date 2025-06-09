import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pronto/models/job_model.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;
  final double scale;
  final String? company;
  final String? companyLogoUrl;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.scale = 1.0,
    this.company,
    this.companyLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.7;

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: cardHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with days ago and share button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Posted ${job.daysAgo}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    IconButton(
                      onPressed: () => _launchURL(job.link),
                      icon: const Icon(Icons.share, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                // Job title
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Company info
                Row(
                  children: [
                    companyLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              companyLogoUrl!,
                              width: 45,
                              height: 45,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.business,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        company ?? 'Company Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${job.location} (${job.workArrangement})',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (job.payString.isNotEmpty)
                      _buildTag(
                        icon: Icons.attach_money,
                        text: job.payString,
                        color: Colors.green,
                      ),
                    if (job.duration.isNotEmpty)
                      _buildTag(
                        icon: Icons.access_time,
                        text: job.duration,
                        color: Colors.blue,
                      ),
                    if (job.jobType.isNotEmpty)
                      _buildTag(
                        icon: Icons.work,
                        text: job.jobType,
                        color: Colors.purple,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Job description - Expanded to take remaining space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Job Description:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            job.description,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay at bottom to indicate more content
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 30,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
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
