class Application {
  final String applicationID;
  final String jobID;
  final String status;
  final DateTime appliedAt;
  final String? resumeUrl;
  final String? rejectionReason;
  final bool favorite;

  Application({
    required this.applicationID,
    required this.jobID,
    required this.status,
    required this.appliedAt,
    this.resumeUrl,
    this.rejectionReason,
    required this.favorite,
  });

  factory Application.fromMap(Map<String, dynamic> map, String docId) {
    return Application(
      applicationID: docId,
      jobID: map['jobId'] ?? '',
      status: map['status'] ?? 'applied',
      appliedAt: map['appliedAt']?.toDate() ?? DateTime.now(),
      resumeUrl: map['resumeUrl'],
      rejectionReason: map['rejectionReason'],
      favorite: map['favorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobID': jobID,
      'status': status,
      'appliedAt': appliedAt,
      'resumeUrl': resumeUrl,
      'rejectionReason': rejectionReason,
      'favorite': favorite,
    };
  }

  Application copyWith({
    String? applicationID,
    String? jobID,
    String? status,
    DateTime? appliedAt,
    String? resumeUrl,
    String? rejectionReason,
    bool? favorite,
  }) {
    return Application(
      applicationID: applicationID ?? this.applicationID,
      jobID: jobID ?? this.jobID,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      favorite: favorite ?? this.favorite,
    );
  }
}
