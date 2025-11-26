import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/subject_model.dart';
import '../models/practice_model.dart';
import '../models/task_model.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }

  // ===== FILE UPLOAD METHODS =====

  // Загрузка файла
  Future<String> uploadFile(Uint8List fileBytes, String fileName) async {
    try {
      print(
          '🔄 Начинаем загрузку файла: $fileName, размер: ${fileBytes.length} bytes');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-file-bytes/'),
      );

      // Определяем Content-Type по расширению файла
      String contentType = 'application/octet-stream';
      if (fileName.toLowerCase().endsWith('.pdf')) {
        contentType = 'application/pdf';
      } else if (fileName.toLowerCase().endsWith('.doc')) {
        contentType = 'application/msword';
      } else if (fileName.toLowerCase().endsWith('.docx')) {
        contentType =
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (fileName.toLowerCase().endsWith('.xls')) {
        contentType = 'application/vnd.ms-excel';
      } else if (fileName.toLowerCase().endsWith('.xlsx')) {
        contentType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else if (fileName.toLowerCase().endsWith('.txt')) {
        contentType = 'text/plain';
      }

      // Добавляем файл как bytes с правильным content-type
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ));

      // Добавляем имя файла отдельным полем
      request.fields['filename'] = fileName;

      print('📤 Отправляем запрос на $baseUrl/upload-file-bytes/');

      final response = await client.send(request);
      final responseBody = await http.Response.fromStream(response);

      print('📥 Получен ответ: ${response.statusCode}');
      print('📄 Тело ответа: ${responseBody.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody.body);
        final fileUrl = data['url'];
        print('✅ Файл успешно загружен: $fileUrl');
        return fileUrl;
      } else {
        final errorMessage =
            'HTTP ${response.statusCode}: ${responseBody.body}';
        print('❌ Ошибка загрузки: $errorMessage');
        throw ApiException(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }
    } catch (e) {
      print('❌ Исключение при загрузке файла: $e');
      throw ApiException(
        statusCode: 0,
        message: 'File upload failed: $e',
      );
    }
  }

  // Создание задачи с файлом (исправленный метод)
  Future<Task> createTaskWithFile(
      CreateTask task, Uint8List fileBytes, String fileName) async {
    try {
      print('🔄 Создание задачи с файлом: $fileName');

      // Сначала загружаем файл
      final fileUrl = await uploadFile(fileBytes, fileName);

      // Затем создаем задачу с URL файла
      final taskWithFile = CreateTask(
        idPractice: task.idPractice,
        description: task.description,
        file: fileUrl,
      );

      print('📝 Создаем задачу с URL файла: $fileUrl');
      return await createTask(taskWithFile);
    } catch (e) {
      print('❌ Ошибка создания задачи с файлом: $e');

      // Пробуем создать задачу без файла
      print('🔄 Пробуем создать задачу без файла...');
      final taskWithoutFile = CreateTask(
        idPractice: task.idPractice,
        description: task.description,
        file: 'Нет файла',
      );

      return await createTask(taskWithoutFile);
    }
  }

  // ===== SUBJECTS =====
  Future<List<Subject>> getSubjects() async {
    final response = await client.get(Uri.parse('$baseUrl/subjects'));
    await _handleResponse(response);

    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Subject.fromJson(item)).toList();
  }

  Future<Subject> getSubject(int id) async {
    final response = await client.get(Uri.parse('$baseUrl/subjects/$id'));
    await _handleResponse(response);

    return Subject.fromJson(json.decode(response.body));
  }

  Future<Subject> createSubject(CreateSubject subject) async {
    final response = await client.post(
      Uri.parse('$baseUrl/subjects'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(subject.toJson()),
    );
    await _handleResponse(response);

    return Subject.fromJson(json.decode(response.body));
  }

  Future<Subject> updateSubject(int id, String title) async {
    final response = await client.put(
      Uri.parse('$baseUrl/subjects/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title}),
    );
    await _handleResponse(response);

    return Subject.fromJson(json.decode(response.body));
  }

  Future<void> deleteSubject(int id) async {
    final response = await client.delete(Uri.parse('$baseUrl/subjects/$id'));
    await _handleResponse(response);
  }

  // ===== PRACTICES =====
  Future<List<Practice>> getPractices() async {
    final response = await client.get(Uri.parse('$baseUrl/practices'));
    await _handleResponse(response);

    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Practice.fromJson(item)).toList();
  }

  Future<List<Practice>> getPracticesBySubject(int subjectId) async {
    final response =
        await client.get(Uri.parse('$baseUrl/practices/subject/$subjectId'));
    await _handleResponse(response);

    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Practice.fromJson(item)).toList();
  }

  Future<Practice> getPractice(int id) async {
    final response = await client.get(Uri.parse('$baseUrl/practices/$id'));
    await _handleResponse(response);

    return Practice.fromJson(json.decode(response.body));
  }

  Future<Practice> createPractice(CreatePractice practice) async {
    final response = await client.post(
      Uri.parse('$baseUrl/practices'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(practice.toJson()),
    );
    await _handleResponse(response);

    return Practice.fromJson(json.decode(response.body));
  }

  Future<Practice> updatePracticeCondition(
      int practiceId, String condition) async {
    final response = await client.patch(
      Uri.parse(
          '$baseUrl/practices/$practiceId/condition?condition=$condition'),
      headers: {'Content-Type': 'application/json'},
    );
    await _handleResponse(response);

    return Practice.fromJson(json.decode(response.body));
  }

  Future<void> deletePractice(int id) async {
    final response = await client.delete(Uri.parse('$baseUrl/practices/$id'));
    await _handleResponse(response);
  }

  Future<Practice> completePractice(int practiceId) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/practices/$practiceId/complete'),
      headers: {'Content-Type': 'application/json'},
    );
    await _handleResponse(response);

    return Practice.fromJson(json.decode(response.body));
  }

  // ===== TASKS =====
  Future<List<Task>> getTasksByPractice(int practiceId) async {
    final response =
        await client.get(Uri.parse('$baseUrl/tasks/practice/$practiceId'));
    await _handleResponse(response);

    final List<dynamic> data = json.decode(response.body);
    return data.map((item) => Task.fromJson(item)).toList();
  }

  Future<Task> createTask(CreateTask task) async {
    try {
      print('📝 Создание задачи: ${task.description}');
      print('🔧 Practice ID: ${task.idPractice}');
      print('📎 File: ${task.file}');

      final response = await client.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(task.toJson()),
      );

      print('📥 Ответ от сервера: ${response.statusCode}');
      print('📄 Тело ответа: ${response.body}');

      final handledResponse = await _handleResponse(response);
      return Task.fromJson(json.decode(handledResponse.body));
    } catch (e) {
      print('❌ Ошибка создания задачи: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Create task failed: $e',
      );
    }
  }

  Future<void> deleteTask(int id) async {
    final response = await client.delete(Uri.parse('$baseUrl/tasks/$id'));
    await _handleResponse(response);
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() {
    return 'ApiException: $statusCode - $message';
  }
}
