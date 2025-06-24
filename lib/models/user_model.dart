import 'education_model.dart';
import 'work_experience_model.dart';
import 'project_experience_model.dart';
import 'award_model.dart';
import 'application_model.dart';
import 'notification_model.dart';

class UserModel {
  String? userID;
  String name;
  String preferredName;
  String email;
  String? profilePicURL;
  String phoneNumber;
  String designation;
  int age;
  String gender;
  String race;
  List<String> disabilities;
  String address;
  int postalCode;
  Map<String, String> languages;
  String selfIntro;
  List<String> skills;
  String? linkedIn;
  String? gitHub;
  Map<String, String> resumes;
  List<Education> education;
  List<WorkExperience> workExperience;
  List<ProjectExperience> projectExperience;
  List<Award> awards;
  List<Application> applications;
  List<Notification> notifications;

  UserModel({
    this.userID,
    required this.name,
    required this.preferredName,
    required this.email,
    this.profilePicURL,
    required this.phoneNumber,
    required this.designation,
    required this.age,
    required this.gender,
    required this.race,
    this.disabilities = const [],
    required this.address,
    required this.postalCode,
    this.languages = const {},
    required this.selfIntro,
    this.skills = const [],
    this.linkedIn,
    this.gitHub,
    this.resumes = const {},
    this.education = const [],
    this.workExperience = const [],
    this.projectExperience = const [],
    this.awards = const [],
    this.applications = const [],
    this.notifications = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'name': name,
      'preferredName': preferredName,
      'email': email,
      'profilePicURL': profilePicURL,
      'phoneNumber': phoneNumber,
      'designation': designation,
      'age': age,
      'gender': gender,
      'race': race,
      'disabilities': disabilities,
      'address': address,
      'postalCode': postalCode,
      'languages': languages,
      'selfIntro': selfIntro,
      'skills': skills,
      'linkedIn': linkedIn,
      'gitHub': gitHub,
      'resumes': resumes,
      'education': education.map((e) => e.toMap()).toList(),
      'workExperience': workExperience.map((e) => e.toMap()).toList(),
      'projectExperience': projectExperience.map((e) => e.toMap()).toList(),
      'awards': awards.map((e) => e.toMap()).toList(),
      'applications': applications.map((e) => e.toMap()).toList(),
      'notifications': notifications.map((e) => e.toMap()).toList(),
    };
  }

  factory UserModel.fromMap(
    Map<String, dynamic> map, {
    required List<Application> applications,
    required List<Notification> notifications,
    required List<Education> education,
    required List<WorkExperience> workExperience,
    required List<ProjectExperience> projectExperience,
    required List<Award> awards,
  }) {
    return UserModel(
      userID: map['userID'],
      name: map['name'] ?? '',
      preferredName: map['preferredName'] ?? '',
      email: map['email'] ?? '',
      profilePicURL: map['profilePicURL'],
      phoneNumber: map['phoneNumber'] ?? '',
      designation: map['designation'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      race: map['race'] ?? '',
      disabilities: List<String>.from(map['disabilities'] ?? []),
      address: map['address'] ?? '',
      postalCode: map['postalCode'] ?? 0,
      languages: Map<String, String>.from(map['languages'] ?? {}),
      selfIntro: map['selfIntro'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      linkedIn: map['linkedIn'],
      gitHub: map['gitHub'],
      resumes: Map<String, String>.from(map['resumes'] ?? {}),
      education: education,
      workExperience: workExperience,
      projectExperience: projectExperience,
      awards: awards,
      applications: applications,
      notifications: notifications,
    );
  }
}
