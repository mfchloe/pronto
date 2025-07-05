import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String notificationID;
  final String applicationID;
  final String type;
  final bool read;
  final DateTime timeStamp;
  final String? jobID;
  final String? jobTitle;
  final String? companyName;

  Notification({
    required this.notificationID,
    required this.applicationID,
    required this.type,
    required this.read,
    required this.timeStamp,
    this.jobID,
    this.jobTitle,
    this.companyName,
  });

  factory Notification.fromMap(Map<String, dynamic> data, String id) {
    return Notification(
      notificationID: id,
      applicationID: data['applicationId'] ?? '',
      type: data['type'] ?? '',
      read: data['read'] ?? false,
      timeStamp: (data['timeStamp'] as Timestamp).toDate(),
      jobID: data['jobId'],
      jobTitle: data['jobTitle'],
      companyName: data['companyName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationID,
      'type': type,
      'read': read,
      'timeStamp': Timestamp.fromDate(timeStamp),
      if (jobID != null) 'jobId': jobID,
      if (jobTitle != null) 'jobTitle': jobTitle,
      if (companyName != null) 'companyName': companyName,
    };
  }

  Notification copyWith({
    String? notificationID,
    String? applicationID,
    String? type,
    String? message,
    bool? read,
    DateTime? timeStamp,
    String? jobID,
    String? jobTitle,
    String? companyName,
  }) {
    return Notification(
      notificationID: notificationID ?? this.notificationID,
      applicationID: applicationID ?? this.applicationID,
      type: type ?? this.type,
      read: read ?? this.read,
      timeStamp: timeStamp ?? this.timeStamp,
      jobID: jobID ?? this.jobID,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
    );
  }
}
