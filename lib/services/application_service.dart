import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/models/application_model.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all applications (from subcollection) of a user
  Stream<List<Application>> getUserApplications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('applications')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Application.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get a specific application by ID
  Future<Application?> getApplicationById(
    String userId,
    String applicationId,
  ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('applications')
          .doc(applicationId)
          .get();

      if (doc.exists) {
        return Application.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting application: $e');
      return null;
    }
  }

  // Create a new application
  Future<String> createApplication({
    required String userId,
    required String jobId,
    String? resumeUrl,
  }) async {
    try {
      final applicationRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('applications')
          .add({
            'jobId': jobId,
            'status': 'applied',
            'appliedAt': FieldValue.serverTimestamp(),
            'resumeUrl': resumeUrl,
            'favorite': false,
          });

      return applicationRef.id;
    } catch (e) {
      print('Error creating application: $e');
      throw e;
    }
  }

  // Update application status
  Future<void> updateApplicationStatus(
    String userId,
    String applicationId,
    String newStatus,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('applications')
          .doc(applicationId)
          .update({'status': newStatus});
    } catch (e) {
      print('Error updating application status: $e');
      throw e;
    }
  }

  // Update application favorite
  Future<void> updateApplicationFavorite(
    String userId,
    String applicationId,
    bool favorite,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('applications')
          .doc(applicationId)
          .update({'favorite': favorite});
    } catch (e) {
      print('Error updating application favorite: $e');
      throw e;
    }
  }

  // Delete an application
  Future<void> deleteApplication(String userId, String applicationId) async {
    try {
      final application = await getApplicationById(userId, applicationId);
      if (application == null) {
        throw Exception('Application not found');
      }

      final jobId = application.jobID;

      final jobRef = _firestore.collection('jobs').doc(jobId);
      final appRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('applications')
          .doc(applicationId);

      final batch = _firestore.batch();

      batch.update(jobRef, {
        'usersApplied': FieldValue.arrayRemove([userId]),
        'usersDeclined': FieldValue.arrayUnion([userId]),
      });

      batch.delete(appRef);

      await batch.commit();
    } catch (e) {
      print('Error deleting application: $e');
      throw e;
    }
  }

  // Get applications filtered by status
  Stream<List<Application>> getApplicationsByStatus(
    String userId,
    String status,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('applications')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Application.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get favorite applications
  Stream<List<Application>> getFavoriteApplications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('applications')
        .where('favorite', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Application.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get applications count by status
  Future<Map<String, int>> getApplicationsCountByStatus(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('applications')
          .get();

      Map<String, int> statusCounts = {};

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'applied';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      return statusCounts;
    } catch (e) {
      print('Error getting applications count: $e');
      return {};
    }
  }
}
