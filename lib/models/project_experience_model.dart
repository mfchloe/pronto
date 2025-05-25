import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectExperience {
  String title;
  String organisation;
  DateTime startDate;
  DateTime endDate;
  String description;

  ProjectExperience({
    required this.title,
    required this.organisation,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'organisation': organisation,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'description': description,
    };
  }

  factory ProjectExperience.fromMap(Map<String, dynamic> map) {
    return ProjectExperience(
      title: map['title'] ?? '',
      organisation: map['organisation'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      description: map['description'] ?? '',
    );
  }
}
