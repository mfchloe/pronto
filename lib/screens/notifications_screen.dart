import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Move this list outside itemBuilder
    final notifications = [
      {
        'title': 'New job match found!',
        'subtitle': 'Software Engineer position at Google matches your profile',
        'time': '5m ago',
        'isNew': true,
      },
      {
        'title': 'Application status update',
        'subtitle': 'Your application for Product Manager role was reviewed',
        'time': '1h ago',
        'isNew': true,
      },
      {
        'title': 'Interview invitation',
        'subtitle': 'You\'ve been invited for an interview on Monday at 2 PM',
        'time': '2h ago',
        'isNew': true,
      },
      {
        'title': 'Profile view',
        'subtitle': 'A recruiter viewed your profile',
        'time': '4h ago',
        'isNew': false,
      },
      {
        'title': 'Job recommendation',
        'subtitle': '5 new jobs match your skills and preferences',
        'time': '6h ago',
        'isNew': false,
      },
      {
        'title': 'Application reminder',
        'subtitle':
            'Don\'t forget to complete your application for UI/UX Designer',
        'time': '1d ago',
        'isNew': false,
      },
      {
        'title': 'Skills assessment',
        'subtitle':
            'Complete your Flutter skills assessment to boost your profile',
        'time': '2d ago',
        'isNew': false,
      },
      {
        'title': 'Weekly job digest',
        'subtitle': '15 new jobs posted in your area this week',
        'time': '3d ago',
        'isNew': false,
      },
    ];

    final newCount = notifications.where((n) => n['isNew'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                ),
              );
              // If needed, implement mark-as-read logic here
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User ID: $userId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (newCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$newCount New',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notification List
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final isNew = notification['isNew'] as bool;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isNew ? 3 : 1,
                    color: isNew ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isNew
                            ? Colors.blue
                            : Colors.grey.shade300,
                        child: Icon(
                          _getNotificationIcon(index),
                          color: isNew ? Colors.white : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notification['title'] as String,
                        style: TextStyle(
                          fontWeight: isNew
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        notification['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            notification['time'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (isNew) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
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

  IconData _getNotificationIcon(int index) {
    final icons = [
      Icons.work,
      Icons.update,
      Icons.calendar_today,
      Icons.visibility,
      Icons.recommend,
      Icons.alarm,
      Icons.quiz,
      Icons.email,
    ];
    return icons[index % icons.length];
  }
}
