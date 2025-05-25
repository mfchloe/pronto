import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  String notificationID;
  String applicationID;
  String type;
  String message;
  bool read;
  DateTime timeStamp;

  Notification({
    required this.notificationID,
    required this.applicationID,
    required this.type,
    required this.message,
    required this.read,
    required this.timeStamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationID': notificationID,
      'applicationID': applicationID,
      'type': type,
      'message': message,
      'read': read,
      'timeStamp': Timestamp.fromDate(timeStamp),
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      notificationID: map['notificationID'] ?? '',
      applicationID: map['applicationID'] ?? '',
      type: map['type'] ?? '',
      message: map['message'] ?? '',
      read: map['read'] ?? false,
      timeStamp: (map['timeStamp'] as Timestamp).toDate(),
    );
  }
}
