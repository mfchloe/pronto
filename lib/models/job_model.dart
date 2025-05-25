import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  String jobID;
  String employerID;
  String title;
  String description;
  String jobType;
  List<String> skills;
  String location;
  int duration;
  double pay;
  DateTime datePosted;
  String status;
  List<String> usersApplied;

  Job({
    required this.jobID,
    required this.employerID,
    required this.title,
    required this.description,
    required this.jobType,
    required this.skills,
    required this.location,
    required this.duration,
    required this.pay,
    required this.datePosted,
    required this.status,
    this.usersApplied = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'jobID': jobID,
      'employerID': employerID,
      'title': title,
      'description': description,
      'jobType': jobType,
      'skills': skills,
      'location': location,
      'duration': duration,
      'pay': pay,
      'datePosted': Timestamp.fromDate(datePosted),
      'status': status,
      'usersApplied': usersApplied,
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      jobID: map['jobID'] ?? '',
      employerID: map['employerID'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      jobType: map['jobType'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      location: map['location'] ?? '',
      duration: map['duration'] ?? 0,
      pay: (map['pay'] ?? 0).toDouble(),
      datePosted: (map['datePosted'] as Timestamp).toDate(),
      status: map['status'] ?? '',
      usersApplied: List<String>.from(map['usersApplied'] ?? []),
    );
  }
}
