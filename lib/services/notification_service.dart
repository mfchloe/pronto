import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/models/notification_model.dart';
import 'package:pronto/services/job_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // HELPER: Determine user type
  Future<bool> _isRecruiter(String userId) async {
    final doc = await _firestore.collection('recruiters').doc(userId).get();
    return doc.exists;
  }

  // Get notifications for a specific user
  Stream<List<Notification>> getNotifications(String userId) async* {
    final isRecruiter = await _isRecruiter(userId);
    final collectionName = isRecruiter ? 'recruiters' : 'users';

    yield* _firestore
        .collection(collectionName)
        .doc(userId)
        .collection('notifications')
        .orderBy('timeStamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Notification> notifications = [];

          for (var doc in snapshot.docs) {
            var notification = Notification.fromMap(doc.data(), doc.id);

            // If it's a status update notification, try to fetch job and company info
            if ((notification.type == 'interview' ||
                    notification.type == 'offer' ||
                    notification.type == 'rejected' ||
                    notification.type == 'status_update') &&
                notification.jobID != null) {
              try {
                var job = await JobService().getJobById(notification.jobID!);

                if (job != null) {
                  String jobTitle = job.title;
                  String companyName = 'Unknown Company';

                  var recruiterDoc = await _firestore
                      .collection('recruiters')
                      .doc(job.recruiterId)
                      .get();

                  if (recruiterDoc.exists) {
                    var recruiterData = recruiterDoc.data()!;
                    String? companyId = recruiterData['companyId'];

                    if (companyId != null) {
                      var companyDoc = await _firestore
                          .collection('companies')
                          .doc(companyId)
                          .get();

                      if (companyDoc.exists) {
                        companyName =
                            companyDoc.data()?['name'] ?? 'Unknown Company';
                      }
                    }
                  }

                  // Update notification with job + company details
                  notification = notification.copyWith(
                    jobTitle: jobTitle,
                    companyName: companyName,
                  );
                }
              } catch (e) {
                print('Error fetching job details for notification: $e');
              }
            }

            notifications.add(notification);
          }

          return notifications;
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    final isRecruiter = await _isRecruiter(userId);
    final collectionName = isRecruiter ? 'recruiters' : 'users';

    try {
      await _firestore
          .collection(collectionName)
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      throw e;
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    final isRecruiter = await _isRecruiter(userId);
    final collectionName = isRecruiter ? 'recruiters' : 'users';

    try {
      var batch = _firestore.batch();
      var notifications = await _firestore
          .collection(collectionName)
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw e;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    final isRecruiter = await _isRecruiter(userId);
    final collectionName = isRecruiter ? 'recruiters' : 'users';

    try {
      await _firestore
          .collection(collectionName)
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
      throw e;
    }
  }
}
