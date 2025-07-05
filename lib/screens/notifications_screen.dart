import 'package:flutter/material.dart';
import 'package:pronto/services/notification_service.dart';
import 'package:pronto/services/job_service.dart';
import 'package:pronto/models/notification_model.dart' as pronto;
import 'package:pronto/widgets/notification_card.dart';
import 'package:pronto/router.dart';
import 'package:visibility_detector/visibility_detector.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final JobService _jobService = JobService();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _viewedNotifications =
      <String>{}; // Track viewed notifications

  bool _isLoading = true;
  List<pronto.Notification> _notifications = [];
  List<pronto.Notification> _filteredNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _markAllAsReadAfterDelay();
    _searchController.addListener(_filterNotifications);
  }

  // Mark all notifications as read after a short delay when user opens the page
  void _markAllAsReadAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _notificationService.markAllNotificationsAsRead(widget.userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotifications() {
    _notificationService
        .getNotifications(widget.userId)
        .listen(
          (notifications) {
            if (mounted) {
              setState(() {
                _notifications = notifications;
                _filteredNotifications = notifications;
                _isLoading = false;
              });
              // Run after the first frame to ensure visibility detection works (ts not working bruh)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                for (var n in notifications) {
                  if (!n.read) {
                    _markNotificationAsRead(n);
                  }
                }
              });
            }
          },
          onError: (error) {
            print('Error loading notifications: $error');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        );
  }

  void _filterNotifications() {
    String searchQuery = _searchController.text.toLowerCase();

    setState(() {
      if (searchQuery.isEmpty) {
        _filteredNotifications = _notifications;
      } else {
        _filteredNotifications = _notifications.where((notification) {
          return (notification.jobTitle?.toLowerCase().contains(searchQuery) ??
                  false) ||
              (notification.companyName?.toLowerCase().contains(searchQuery) ??
                  false) ||
              (notification.type.toLowerCase().contains(searchQuery));
        }).toList();
      }
    });
  }

  // Mark notification as read when it becomes visible
  void _markNotificationAsRead(pronto.Notification notification) {
    // Only mark as read if it hasn't been read yet and we haven't already processed it
    if (!notification.read &&
        !_viewedNotifications.contains(notification.notificationID)) {
      _viewedNotifications.add(notification.notificationID);

      // Update the notification service
      _notificationService
          .markNotificationAsRead(widget.userId, notification.notificationID)
          .catchError((error) {
            print('Error marking notification as read: $error');
            // Remove from viewed set if update failed
            _viewedNotifications.remove(notification.notificationID);
          });
    }
  }

  void _handleNotificationTap(pronto.Notification notification) async {
    // Mark as read when tapped
    _markNotificationAsRead(notification);

    // Only navigate for status update notifications with valid job IDs
    if ((notification.type == 'interview' ||
            notification.type == 'offer' ||
            notification.type == 'rejected') &&
        notification.jobID != null) {
      try {
        final job = await _jobService.getJobById(notification.jobID!);
        if (job != null && mounted) {
          NavigationHelper.navigateTo('/job-details', arguments: job);
        } else {
          _showJobNotFoundSnackBar();
        }
      } catch (e) {
        print('Error fetching job details: $e');
        _showJobNotFoundSnackBar();
      }
    }
  }

  void _showJobNotFoundSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job no longer available'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearAllNotifications() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Delete all notifications
                try {
                  for (var notification in _notifications) {
                    await _notificationService.deleteNotification(
                      widget.userId,
                      notification.notificationID,
                    );
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications cleared'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error clearing notifications: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to clear notifications'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Search and Clear All Bar
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
                          hintText: 'Search notifications...',
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
                            borderRadius: BorderRadius.circular(25),
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
                  // Clear All icon button
                  if (_notifications.isNotEmpty)
                    GestureDetector(
                      onTap: _clearAllNotifications,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _notifications.isEmpty
                ? 'No notifications yet'
                : 'No notifications found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _notifications.isEmpty
                ? 'You\'ll see updates about your job applications here'
                : 'Try adjusting your search',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = _filteredNotifications[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: VisibilityDetector(
            key: Key('notification_${notification.notificationID}'),
            onVisibilityChanged: (visibilityInfo) {
              if (visibilityInfo.visibleFraction >= 0.5) {
                _markNotificationAsRead(notification);
              }
            },
            child: NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onDelete: () => NotificationService().deleteNotification(
                widget.userId,
                notification.notificationID,
              ),
            ),
          ),
        );
      },
    );
  }
}
