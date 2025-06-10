import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Job>> getJobs({
    String? industry,
    String? location,
    String? jobType,
    String? workArrangement,
    String? duration,
    double? minSalary,
    double? maxSalary,
    List<String>? jobTitles,
    String? userId,
  }) {
    // Start with the base query for status = open jobs
    Query query = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open');

    if (industry != null && industry.isNotEmpty) {
      query = query.where('industry', isEqualTo: industry);
    }
    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }
    if (jobType != null && jobType.isNotEmpty) {
      query = query.where('jobType', isEqualTo: jobType);
    }
    if (workArrangement != null && workArrangement.isNotEmpty) {
      query = query.where('workArrangement', isEqualTo: workArrangement);
    }
    if (duration != null && duration.isNotEmpty) {
      query = query.where('duration', isEqualTo: duration);
    }

    return query.snapshots().map((snapshot) {
      List<Job> jobs = snapshot.docs
          .map((doc) => Job.fromFirestore(doc))
          .toList();

      jobs = jobs.where((job) {
        // Filter by salary range if specified
        if (minSalary != null || maxSalary != null) {
          double jobSalary = job.pay;
          if (minSalary != null && jobSalary < minSalary) return false;
          if (maxSalary != null && jobSalary > maxSalary) return false;
        }

        // Filter by job titles if specified
        if (jobTitles != null && jobTitles.isNotEmpty) {
          bool titleMatches = jobTitles.any(
            (title) => job.title.toLowerCase().contains(title.toLowerCase()),
          );
          if (!titleMatches) return false;
        }

        return true;
      }).toList();

      return jobs;
    });
  }

  Future<void> applyToJob(String jobID, String userID, String? resume) async {
    // Update usersApplied array in the job document
    await _firestore.collection('jobs').doc(jobID).update({
      'usersApplied': FieldValue.arrayUnion([userID]),
    });

    // Create an application document in application subcollection
    await _firestore
        .collection('users')
        .doc(userID)
        .collection('applications')
        .add({
          'jobId': jobID,
          'status': 'applied',
          'appliedAt': FieldValue.serverTimestamp(),
          'resume': resume,
        });
  }

  Future<void> markJobAsRejected(String jobID, String userID) async {
    await _firestore.collection('jobs').doc(jobID).update({
      'usersDeclined': FieldValue.arrayUnion([userID]),
    });
  }

  Future<Map<String, dynamic>?> getCompanyInfoFromJob(Job job) async {
    try {
      final recruiterSnapshot = await _firestore
          .collection('recruiters')
          .doc(job.recruiterId)
          .get();

      // Recruiter not found
      if (!recruiterSnapshot.exists) {
        return null;
      }

      final recruiterData = recruiterSnapshot.data();
      final companyId = recruiterData?['companyId'];

      final companySnapshot = await _firestore
          .collection('companies')
          .doc(companyId)
          .get();

      // Company not found
      if (!companySnapshot.exists) {
        return null;
      }

      return companySnapshot.data();
    } catch (e) {
      print('Error fetching company info: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserFilters(String userId) async {
    try {
      final filtersDoc = await _firestore
          .collection('userFilters')
          .doc(userId)
          .get();

      if (filtersDoc.exists) {
        return filtersDoc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user filters: $e');
      return null;
    }
  }
}
