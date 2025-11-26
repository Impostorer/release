class Task {
  final int id;
  final int idPractice;
  final String description;
  final String file;
  // dateComplete УДАЛЕНО

  Task({
    required this.id,
    required this.idPractice,
    required this.description,
    required this.file,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      idPractice: json['idPractice'],
      description: json['description'],
      file: json['file'],
      // dateComplete УДАЛЕНО
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idPractice': idPractice,
      'description': description,
      'file': file,
    };
  }
}

class CreateTask {
  final int idPractice;
  final String description;
  final String file;

  CreateTask({
    required this.idPractice,
    required this.description,
    required this.file,
  });

  Map<String, dynamic> toJson() {
    return {
      'idPractice': idPractice,
      'description': description,
      'file': file,
    };
  }
}