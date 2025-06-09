import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pronto/models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Job>> getJobs({
    String? industry,
    String? location,
    String? jobType,
    String? workArrangement,
  }) {
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

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Job.fromFirestore(doc)).toList();
    });
  }

  Future<void> applyToJob(String jobID, String userID) async {
    await _firestore.collection('jobs').doc(jobID).update({
      'usersApplied': FieldValue.arrayUnion([userID]),
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
}
