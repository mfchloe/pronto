import 'package:cloud_firestore/cloud_firestore.dart';

class WorkExperience {
  String company;
  String title;
  DateTime startDate;
  DateTime endDate;
  String description;

  WorkExperience({
    required this.company,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'company': company,
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'description': description,
    };
  }

  factory WorkExperience.fromMap(Map<String, dynamic> map) {
    return WorkExperience(
      company: map['company'] ?? '',
      title: map['title'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      description: map['description'] ?? '',
    );
  }
}
