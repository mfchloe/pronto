import 'package:flutter/material.dart';

class ApplicantApplicationsScreen extends StatelessWidget {
  final String userId;

  const ApplicantApplicationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User ID: $userId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '5 Active',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Applications list
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                  final companies = [
                    'Google',
                    'Apple',
                    'Microsoft',
                    'Meta',
                    'Netflix',
                    'Amazon',
                    'Tesla',
                  ];
                  final positions = [
                    'Software Engineer',
                    'Product Manager',
                    'UI/UX Designer',
                    'Data Scientist',
                    'DevOps Engineer',
                    'Frontend Developer',
                    'Backend Developer',
                  ];
                  final statuses = [
                    'Under Review',
                    'Interview Scheduled',
                    'Pending',
                    'Shortlisted',
                    'Rejected',
                    'Accepted',
                    'Applied',
                  ];
                  final statusColors = [
                    Colors.orange,
                    Colors.blue,
                    Colors.grey,
                    Colors.purple,
                    Colors.red,
                    Colors.green,
                    Colors.teal,
                  ];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: statusColors[index],
                        child: Text(
                          companies[index][0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        positions[index],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(companies[index]),
                          const SizedBox(height: 4),
                          Text(
                            'Applied ${index + 1} days ago',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColors[index].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColors[index].withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          statuses[index],
                          style: TextStyle(
                            color: statusColors[index],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
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
}
