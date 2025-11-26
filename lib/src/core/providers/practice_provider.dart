import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // ДОБАВИТЬ для BuildContext
import '../../../models/practice_model.dart';
import '../../../models/subject_model.dart';
import '../../../services/api_service.dart';
import 'package:provider/provider.dart';
import 'subject_provider.dart'; // ДОБАВИТЬ импорт SubjectProvider

class PracticeProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Practice> _practices = [];
  bool _isLoading = false;
  String? _error;

  PracticeProvider(this._apiService);

  List<Practice> get practices => _practices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ДОБАВИТЬ МЕТОД ДЛЯ ДОСТУПА К CONTEXT
  BuildContext? _context;
  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> loadPracticesBySubject(int subjectId) async {
    _setLoading(true);
    _error = null;

    try {
      _practices = await _apiService.getPracticesBySubject(subjectId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createPractice(CreatePractice practice) async {
    _setLoading(true);
    _error = null;

    try {
      final newPractice = await _apiService.createPractice(practice);
      _practices.add(newPractice);
      notifyListeners();

      // ОБНОВИТЬ СЧЁТЧИК ПРЕДМЕТА
      if (_context != null && _context!.mounted && hasListeners) {
        final subjectProvider =
            Provider.of<SubjectProvider>(_context!, listen: false);
        await subjectProvider.refreshSubjectPracticeCount(practice.idSubject);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> togglePracticeCondition(int practiceId) async {
    final practice = _practices.firstWhere((p) => p.id == practiceId);
    // Убедитесь, что значения соответствуют тому, что ожидает API
    final newCondition =
        practice.condition == 'проверено' ? 'не проверено' : 'проверено';

    try {
      final updatedPractice =
          await _apiService.updatePracticeCondition(practiceId, newCondition);
      final index = _practices.indexWhere((p) => p.id == practiceId);
      if (index != -1) {
        _practices[index] = updatedPractice;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> completePractice(int practiceId) async {
    try {
      final updatedPractice = await _apiService.completePractice(practiceId);
      final index = _practices.indexWhere((p) => p.id == practiceId);
      if (index != -1) {
        _practices[index] = updatedPractice;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePractice(int id) async {
    _setLoading(true);
    _error = null;

    try {
      // СОХРАНИТЬ ID ПРЕДМЕТА ПЕРЕД УДАЛЕНИЕМ
      final practice = _practices.firstWhere((p) => p.id == id);
      final subjectId = practice.idSubject;

      await _apiService.deletePractice(id);
      _practices.removeWhere((practice) => practice.id == id);
      notifyListeners();

      // ОБНОВИТЬ СЧЁТЧИК ПРЕДМЕТА
      if (_context != null && _context!.mounted) {
        final subjectProvider =
            Provider.of<SubjectProvider>(_context!, listen: false);
        await subjectProvider.refreshSubjectPracticeCount(subjectId);
      }
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
