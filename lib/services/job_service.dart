import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/models/job_model.dart';
import 'package:pronto/services/application_service.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Job>> getJobs({
    String? userId,
    List<String>? jobTitles,
    String? industry,
    String? workArrangement,
    String? jobType,
    String? duration,
    String? jobRecency,
    double? minSalary,
    double? maxSalary,
  }) {
    // Start with the base query for status = open jobs
    Query query = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open');

    // Apply filters from firebase
    if (industry != null && industry.isNotEmpty) {
      query = query.where('industry', isEqualTo: industry);
    }
    if (workArrangement != null && workArrangement.isNotEmpty) {
      query = query.where('workArrangement', isEqualTo: workArrangement);
    }
    if (jobType != null && jobType.isNotEmpty) {
      query = query.where('jobType', isEqualTo: jobType);
    }
    if (duration != null && duration.isNotEmpty) {
      query = query.where('duration', isEqualTo: duration);
    }

    // Apply job recency filter if specified
    if (jobRecency != null && jobRecency != 'Any time') {
      DateTime cutoffDate = _getJobRecencyCutoffDate(jobRecency);
      query = query.where('datePosted', isGreaterThanOrEqualTo: cutoffDate);
    }

    return query.snapshots().map((snapshot) {
      List<Job> jobs = snapshot.docs
          .map((doc) => Job.fromFirestore(doc))
          .toList();

      jobs = jobs.where((job) {
        // Filter out jobs user has already applied or declined
        if (userId != null) {
          if (job.usersApplied.contains(userId) ||
              job.usersDeclined.contains(userId)) {
            return false;
          }
        }

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

      // Sort jobs by date posted (newest first)
      jobs.sort((a, b) => b.datePosted.compareTo(a.datePosted));

      return jobs;
    });
  }

  DateTime _getJobRecencyCutoffDate(String jobRecency) {
    final now = DateTime.now();
    switch (jobRecency) {
      case 'Last 24 hours':
        return now.subtract(const Duration(days: 1));
      case 'Last 3 days':
        return now.subtract(const Duration(days: 3));
      case 'Last week':
        return now.subtract(const Duration(days: 7));
      case 'Last 2 weeks':
        return now.subtract(const Duration(days: 14));
      case 'Last month':
        return now.subtract(const Duration(days: 30));
      case 'Any time':
      default:
        return DateTime.fromMillisecondsSinceEpoch(0); // Very old date
    }
  }

  Future<Job?> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();

      if (doc.exists) {
        return Job.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching job by ID: $e');
      return null;
    }
  }

  Future<void> applyToJob(
    String jobID,
    String userID,
    String? resumeUrl,
  ) async {
    // Update usersApplied array in the job document
    await _firestore.collection('jobs').doc(jobID).update({
      'usersApplied': FieldValue.arrayUnion([userID]),
    });
    // Create an application document in application subcollection
    await ApplicationService().createApplication(
      userId: userID,
      jobId: jobID,
      resumeUrl: resumeUrl,
    );
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
