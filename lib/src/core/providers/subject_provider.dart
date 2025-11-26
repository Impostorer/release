import 'package:flutter/foundation.dart';
import '../../../models/subject_model.dart';
import '../../../services/api_service.dart';

class SubjectProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _error;

  SubjectProvider(this._apiService);

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSubjects() async {
    _setLoading(true);
    _error = null;

    try {
      _subjects = await _apiService.getSubjects();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createSubject(String title) async {
    _setLoading(true);
    _error = null;

    try {
      final newSubject =
          await _apiService.createSubject(CreateSubject(title: title));
      _subjects.add(newSubject);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshSubjectPracticeCount(int subjectId) async {
    try {
      final updatedSubject = await _apiService.getSubject(subjectId);
      final index = _subjects.indexWhere((subject) => subject.id == subjectId);
      if (index != -1) {
        _subjects[index] = updatedSubject;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing subject count: $e');
      }
    }
  }

  Future<void> deleteSubject(int id) async {
    _setLoading(true);
    _error = null;

    try {
      await _apiService.deleteSubject(id);
      _subjects.removeWhere((subject) => subject.id == id);
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
