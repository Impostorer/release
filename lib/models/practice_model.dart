class Practice {
  final int id;
  final int idSubject;
  final String name;
  final int numberPractice;
  final String description;
  final String condition;
  final String createdPracticeAt;
  final String? dateComplete; // ДОБАВЛЕНО

  Practice({
    required this.id,
    required this.idSubject,
    required this.name,
    required this.numberPractice,
    required this.description,
    required this.condition,
    required this.createdPracticeAt,
    this.dateComplete, // ДОБАВЛЕНО
  });

  factory Practice.fromJson(Map<String, dynamic> json) {
    return Practice(
      id: json['id'],
      idSubject: json['idSubject'],
      name: json['name'],
      numberPractice: json['numberPractice'],
      description: json['description'],
      condition: json['condition'],
      createdPracticeAt: json['createdPracticeAt'],
      dateComplete: json['dateComplete'] ?? null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idSubject': idSubject,
      'name': name,
      'numberPractice': numberPractice,
      'description': description,
      'condition': condition,
      'createdPracticeAt': createdPracticeAt,
    };
  }

  Practice copyWith({
  String? condition,
  String? dateComplete, // ДОБАВИТЬ
}) {
  return Practice(
    id: id,
    idSubject: idSubject,
    name: name,
    numberPractice: numberPractice,
    description: description,
    condition: condition ?? this.condition,
    createdPracticeAt: createdPracticeAt,
    dateComplete: dateComplete ?? this.dateComplete, // ДОБАВИТЬ
  );
}
}

class CreatePractice {
  final int idSubject;
  final String name;
  final String description;

  CreatePractice({
    required this.idSubject,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'idSubject': idSubject,
      'name': name,
      'description': description,
    };
  }
}