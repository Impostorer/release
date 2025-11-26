import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject_model.dart';
import '../src/core/providers/subject_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // ИСПРАВЛЕНИЕ: Используем addPostFrameCallback вместо прямого вызова
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubjects();
    });
  }

  Future<void> _loadSubjects() async {
    try {
      await Provider.of<SubjectProvider>(context, listen: false).loadSubjects();
    } catch (e) {
      // Обработка ошибки, чтобы приложение не падало
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки предметов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    try {
      await Provider.of<SubjectProvider>(context, listen: false).loadSubjects();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Остальной код без изменений...
  void _checkCurrentScreen(BuildContext context, int deletedSubjectId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = ModalRoute.of(context);
      if (currentRoute != null) {
        final routeSettings = currentRoute.settings;
        if (routeSettings.name == '/subject-detail') {
          final subject = routeSettings.arguments as Subject?;
          if (subject != null && subject.id == deletedSubjectId) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Учебная платформа'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: subjectProvider.isLoading && subjectProvider.subjects.isEmpty
          ? _buildLoadingState()
          : subjectProvider.subjects.isEmpty
              ? _buildEmptyState()
              : _buildSubjectsList(subjectProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-subject').then((_) {
            _refreshData();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Остальные методы без изменений...
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Пока нет учебных предметов',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Создайте первый учебный предмет, чтобы начать работу',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-subject');
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Создать предмет'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsList(SubjectProvider subjectProvider) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Учебные предметы',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите предмет для просмотра практических работ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: subjectProvider.subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjectProvider.subjects[index];
                  return _buildSubjectCard(subject, subjectProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(Subject subject, SubjectProvider subjectProvider) {
    return Dismissible(
      key: Key('subject-${subject.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, subject.title);
      },
      onDismissed: (direction) async {
        final subjectId = subject.id;
        final subjectTitle = subject.title;

        setState(() {
          subjectProvider.subjects.removeWhere((s) => s.id == subjectId);
        });

        try {
          await subjectProvider.deleteSubject(subjectId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Предмет "$subjectTitle" удален'),
              backgroundColor: Colors.green,
            ),
          );

          _checkCurrentScreen(context, subjectId);
        } catch (e) {
          if (mounted) {
            await subjectProvider.loadSubjects();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка при удалении: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/subject-detail',
              arguments: subject,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getSubjectColor(subject.id),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Практических работ: ${subject.practiceCount}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Создан: ${subject.createdAt}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
      BuildContext context, String subjectName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить предмет?'),
        content: Text(
            'Предмет "$subjectName" и все связанные практические работы будут удалены безвозвратно.'),
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

  Color _getSubjectColor(int subjectId) {
    final colors = [
      const Color(0xFF4F6EF7),
      const Color(0xFF6C63FF),
      const Color(0xFF00BFA6),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFA726),
      const Color(0xFFAB47BC),
    ];
    return colors[subjectId % colors.length];
  }
}