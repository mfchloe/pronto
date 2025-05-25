class Employer {
  String employerID;
  String company;
  String logoURL;
  String industry;
  List<String> postedJobs;

  Employer({
    required this.employerID,
    required this.company,
    required this.logoURL,
    required this.industry,
    this.postedJobs = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'employerID': employerID,
      'company': company,
      'logoURL': logoURL,
      'industry': industry,
      'postedJobs': postedJobs,
    };
  }

  factory Employer.fromMap(Map<String, dynamic> map) {
    return Employer(
      employerID: map['employerID'] ?? '',
      company: map['company'] ?? '',
      logoURL: map['logoURL'] ?? '',
      industry: map['industry'] ?? '',
      postedJobs: List<String>.from(map['postedJobs'] ?? []),
    );
  }
}
