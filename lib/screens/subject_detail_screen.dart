import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject_model.dart';
import '../models/practice_model.dart';
import '../src/core/providers/practice_provider.dart';
import '../src/core/providers/subject_provider.dart';

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({super.key});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  late Subject _subject;
  bool _isLoading = true;
  List<Practice> _practices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubjectExists();
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subject = ModalRoute.of(context)!.settings.arguments as Subject;
  }

  Future<void> _checkSubjectExists() async {
    final subjectProvider =
        Provider.of<SubjectProvider>(context, listen: false);
    await subjectProvider.loadSubjects();

    final subjectExists =
        subjectProvider.subjects.any((s) => s.id == _subject.id);
    if (!subjectExists && mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Предмет "${_subject.title}" был удален'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
  }

  Future<void> _loadData() async {
    final practiceProvider =
        Provider.of<PracticeProvider>(context, listen: false);
    await practiceProvider.loadPracticesBySubject(_subject.id);

    if (mounted) {
      setState(() {
        _practices = List.from(practiceProvider.practices);
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    await _loadData();
  }

  Future<void> _deletePractice(int practiceId, String practiceName) async {
    // УБИРАЕМ подтверждение здесь, так как оно уже было в confirmDismiss
    try {
      final practiceProvider =
          Provider.of<PracticeProvider>(context, listen: false);
      await practiceProvider.deletePractice(practiceId);

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Практическая работа "$practiceName" удалена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // В случае ошибки возвращаем элемент в список
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _togglePracticeCondition(int practiceId) {
    final practiceProvider =
        Provider.of<PracticeProvider>(context, listen: false);
    practiceProvider.togglePracticeCondition(practiceId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_subject.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubjectInfo(),
                  const SizedBox(height: 24),
                  _buildPracticesSection(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/create-practice',
            arguments: _subject.id,
          ).then((_) {
            _refreshData();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Информация о предмете',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      'Практических работ', _subject.practiceCount.toString()),
                  _buildInfoRow('Дата создания', _subject.createdAt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[800],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticesSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Практические работы',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(_practices.length.toString()),
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _practices.isEmpty
                ? _buildEmptyPractices()
                : _buildPracticesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPractices() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет практических работ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте первую практическую работу',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticesList() {
    return ListView.builder(
      itemCount: _practices.length,
      itemBuilder: (context, index) {
        final practice = _practices[index];
        return Dismissible(
          key: Key('practice-${practice.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          // confirmDismiss показывает диалог подтверждения
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(context, practice.name);
          },
          onDismissed: (direction) {
            final practiceId = practice.id;
            final practiceName = practice.name;

            setState(() {
              _practices.removeWhere((p) => p.id == practiceId);
            });

            // УБИРАЕМ подтверждение здесь, так как оно уже было в confirmDismiss
            _deletePractice(practiceId, practiceName);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/practice-detail',
                  arguments: practice,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getPracticeColor(practice.condition),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _getPracticeIcon(practice.condition),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                practice.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Практическая работа №${practice.numberPractice}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _togglePracticeCondition(practice.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: practice.condition == 'проверено'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: practice.condition == 'проверено'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  practice.condition == 'проверено'
                                      ? Icons.check_circle
                                      : Icons.access_time,
                                  size: 14,
                                  color: practice.condition == 'проверено'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  practice.condition,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: practice.condition == 'проверено'
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      practice.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Создана: ${practice.createdPracticeAt}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                        ),
                      ],
                    ),
                    if (practice.dateComplete != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Выполнено: ${practice.dateComplete}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(
      BuildContext context, String practiceName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить практическую работу?'),
        content: Text(
            'Практическая работа "$practiceName" и все связанные задачи будут удалены безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Color _getPracticeColor(String condition) {
    return condition == 'проверено' ? Colors.green : Colors.orange;
  }

  IconData _getPracticeIcon(String condition) {
    return condition == 'проверено' ? Icons.check : Icons.access_time;
  }
}
