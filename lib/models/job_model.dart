import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String jobID;
  final String recruiterId;
  final String title;
  final String description;
  final String link;
  final String jobType;
  final String industry;
  final String location;
  final String workArrangement;
  final String duration;
  final double pay;
  final DateTime datePosted;
  final String status;
  final List<String> usersApplied;
  final List<String> usersDeclined;

  Job({
    required this.jobID,
    required this.recruiterId,
    required this.title,
    required this.description,
    required this.link,
    required this.jobType,
    required this.industry,
    required this.location,
    required this.workArrangement,
    required this.duration,
    required this.pay,
    required this.datePosted,
    required this.status,
    required this.usersApplied,
    required this.usersDeclined,
  });

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      jobID: map['jobID'] ?? '',
      recruiterId: map['recruiterId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      link: map['link'] ?? '',
      jobType: map['jobType'] ?? '',
      industry: map['industry'] ?? '',
      location: map['location'] ?? '',
      workArrangement: map['workArrangement'] ?? '',
      duration: map['duration'] ?? '',
      pay: (map['pay'] ?? 0).toDouble(),
      datePosted: map['datePosted']?.toDate() ?? DateTime.now(),
      status: map['status'] ?? '',
      usersApplied: List<String>.from(map['usersApplied'] ?? []),
      usersDeclined: List<String>.from(map['usersDeclined'] ?? []),
    );
  }

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job(
      jobID: doc.id,
      recruiterId: data['recruiterId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      link: data['link'] ?? '',
      jobType: data['jobType'] ?? '',
      industry: data['industry'] ?? '',
      location: data['location'] ?? '',
      workArrangement: data['workArrangement'] ?? '',
      duration: data['duration'] ?? '',
      pay: (data['pay'] ?? 0).toDouble(),
      datePosted: data['datePosted']?.toDate() ?? DateTime.now(),
      status: data['status'] ?? '',
      usersApplied: List<String>.from(data['usersApplied'] ?? []),
      usersDeclined: List<String>.from(data['usersDeclined'] ?? []),
    );
  }

  String get daysAgo {
    final now = DateTime.now();
    final difference = now.difference(datePosted).inDays;
    if (difference == 0) return 'today';
    if (difference == 1) return '1 day ago';
    return '$difference days ago';
  }

  String get payString {
    if (pay >= 1000) {
      return '${(pay / 1000).toStringAsFixed(1)}k/month';
    }
    return '${pay.toStringAsFixed(0)}/month';
  }
}
