class Subject {
  final int id;
  final String title;
  final int practiceCount;
  final String createdAt;

  Subject({
    required this.id,
    required this.title,
    required this.practiceCount,
    required this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      title: json['title'],
      practiceCount: json['practiceCount'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'practiceCount': practiceCount,
      'createdAt': createdAt,
    };
  }
}

class CreateSubject {
  final String title;

  CreateSubject({required this.title});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
    };
  }
}