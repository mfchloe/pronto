import 'package:cloud_firestore/cloud_firestore.dart';

class Education {
  String school;
  String degree;
  String fieldOfStudy;
  double grade;
  double totalGrade;
  DateTime startDate;
  DateTime endDate;

  Education({
    required this.school,
    required this.degree,
    required this.fieldOfStudy,
    required this.grade,
    required this.totalGrade,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'school': school,
      'degree': degree,
      'fieldOfStudy': fieldOfStudy,
      'grade': grade,
      'totalGrade': totalGrade,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      school: map['school'] ?? '',
      degree: map['degree'] ?? '',
      fieldOfStudy: map['fieldOfStudy'] ?? '',
      grade: map['grade']?.toDouble() ?? 0.0,
      totalGrade: map['totalGrade']?.toDouble() ?? 0.0,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
    );
  }
}
