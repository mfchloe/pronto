class Award {
  String title;
  int year;
  String description;

  Award({required this.title, required this.year, required this.description});

  Map<String, dynamic> toMap() {
    return {'title': title, 'year': year, 'description': description};
  }

  factory Award.fromMap(Map<String, dynamic> map) {
    return Award(
      title: map['title'] ?? '',
      year: map['year'] ?? 0,
      description: map['description'] ?? '',
    );
  }
}
