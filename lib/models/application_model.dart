import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  String applicationID;
  String jobID;
  String status;
  DateTime submittedAt;
  String rejectionReason;

  Application({
    required this.applicationID,
    required this.jobID,
    required this.status,
    required this.submittedAt,
    required this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'applicationID': applicationID,
      'jobID': jobID,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'rejectionReason': rejectionReason,
    };
  }

  factory Application.fromMap(Map<String, dynamic> map) {
    return Application(
      applicationID: map['applicationID'] ?? '',
      jobID: map['jobID'] ?? '',
      status: map['status'] ?? '',
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      rejectionReason: map['rejectionReason'] ?? '',
    );
  }
}
