import 'package:flutter/material.dart';

class RecruiterJobsScreen extends StatelessWidget {
  final String userId;

  const RecruiterJobsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Job Posts'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Employer ID: $userId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '6 Active Jobs',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Job posts list
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) {
                  final jobTitles = [
                    'Senior Flutter Developer',
                    'Product Manager',
                    'UI/UX Designer',
                    'Data Scientist',
                    'DevOps Engineer',
                    'Marketing Specialist',
                  ];
                  final departments = [
                    'Engineering',
                    'Product',
                    'Design',
                    'Data',
                    'Infrastructure',
                    'Marketing',
                  ];
                  final applicantCounts = [12, 8, 15, 6, 4, 10];
                  final salaryRanges = [
                    '\$80k-120k',
                    '\$90k-130k',
                    '\$70k-100k',
                    '\$100k-150k',
                    '\$85k-125k',
                    '\$60k-80k',
                  ];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        jobTitles[index],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(departments[index]),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${applicantCounts[index]} applicants',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.attach_money,
                                size: 16,
                                color: Colors.green,
                              ),
                              Text(
                                salaryRanges[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    'View Applications',
                                    Icons.visibility,
                                    Colors.blue,
                                    context,
                                  ),
                                  _buildActionButton(
                                    'Edit Job',
                                    Icons.edit,
                                    Colors.orange,
                                    context,
                                  ),
                                  _buildActionButton(
                                    'Analytics',
                                    Icons.analytics,
                                    Colors.green,
                                    context,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    'Share',
                                    Icons.share,
                                    Colors.purple,
                                    context,
                                  ),
                                  _buildActionButton(
                                    'Pause',
                                    Icons.pause,
                                    Colors.grey,
                                    context,
                                  ),
                                  _buildActionButton(
                                    'Delete',
                                    Icons.delete,
                                    Colors.red,
                                    context,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label feature coming soon!')));
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
