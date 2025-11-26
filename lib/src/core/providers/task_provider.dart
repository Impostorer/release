import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../../models/task_model.dart';
import '../../../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  TaskProvider(this._apiService);

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTasksByPractice(int practiceId) async {
    _setLoading(true);
    _error = null;

    try {
      _tasks = await _apiService.getTasksByPractice(practiceId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createTask(CreateTask task) async {
    _setLoading(true);
    _error = null;

    try {
      final newTask = await _apiService.createTask(task);
      _tasks.add(newTask);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ДОБАВИТЬ метод для создания задачи с файлом
  Future<void> createTaskWithFile(CreateTask task, Uint8List fileBytes, String fileName) async {
  _setLoading(true);
  _error = null;

  try {
    final newTask = await _apiService.createTaskWithFile(task, fileBytes, fileName);
    _tasks.add(newTask);
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  } finally {
    _setLoading(false);
  }
}

  Future<void> deleteTask(int id) async {
    _setLoading(true);
    _error = null;

    try {
      await _apiService.deleteTask(id);
      _tasks.removeWhere((task) => task.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
