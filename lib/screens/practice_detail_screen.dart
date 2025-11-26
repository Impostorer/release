import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/practice_model.dart';
import '../models/task_model.dart';
import '../src/core/providers/task_provider.dart';
import '../src/core/providers/practice_provider.dart';

class PracticeDetailScreen extends StatefulWidget {
  const PracticeDetailScreen({super.key});

  @override
  State<PracticeDetailScreen> createState() => _PracticeDetailScreenState();
}

class _PracticeDetailScreenState extends State<PracticeDetailScreen> {
  Practice? _practice;
  bool _initialLoad = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final practice = ModalRoute.of(context)!.settings.arguments as Practice;
      setState(() {
        _practice = practice;
        _isLoading = false;
      });
      _loadData();
    });
  }

  void _loadData() {
    if (!_initialLoad || _practice == null) return;

    _initialLoad = false;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.loadTasksByPractice(_practice!.id);
  }

  Future<void> _refreshData() async {
    if (_practice == null) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.loadTasksByPractice(_practice!.id);
  }

  Future<void> _deleteTask(int taskId, String taskDescription) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    try {
      await taskProvider.deleteTask(taskId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Задача "$taskDescription" удалена'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _refreshData();
      }
    }
  }

  // Метод для открытия деталей задачи
  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детали задачи'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildTaskInfoRow('ID задачи', task.id.toString()),
              _buildTaskInfoRow('ID практики', task.idPractice.toString()),
              const SizedBox(height: 16),
              if (task.file.isNotEmpty && task.file != 'Нет файла') ...[
                const Text(
                  'Прикрепленный файл:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openFile(task.file),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getFileIcon(task.file),
                          color: _getFileColor(task.file),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getFileNameFromUrl(task.file),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              Text(
                                'Нажмите чтобы открыть',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Файл не прикреплен',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          if (task.file.isNotEmpty && task.file != 'Нет файла')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openFile(task.file);
              },
              child: const Text('Открыть файл'),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Метод для открытия файла
  Future<void> _openFile(String fileUrl) async {
    try {
      if (await canLaunchUrl(Uri.parse(fileUrl))) {
        await launchUrl(
          Uri.parse(fileUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorDialog('Не удалось открыть файл',
            'Возможно, файл недоступен или ссылка неверная.');
      }
    } catch (e) {
      _showErrorDialog('Ошибка', 'Не удалось открыть файл: $e');
    }
  }

  // Метод для показа диалога ошибки
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Метод для показа опций файла
  void _showFileOptions(BuildContext context, String fileUrl) {
    final fileName = _getFileNameFromUrl(fileUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Файл задачи'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Файл: $fileName',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Что вы хотите сделать с этим файлом?',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openFile(fileUrl);
            },
            child: const Text('Открыть файл'),
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы для определения цвета и иконки файла
  Color _getFileColor(String fileUrl) {
    if (fileUrl.isEmpty || fileUrl == 'Нет файла') {
      return Colors.grey;
    }

    String fileName = _getFileNameFromUrl(fileUrl).toLowerCase();

    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Colors.blue;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Colors.green;
    } else if (fileName.endsWith('.pdf')) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  IconData _getFileIcon(String fileUrl) {
    if (fileUrl.isEmpty || fileUrl == 'Нет файла') {
      return Icons.assignment;
    }

    String fileName = _getFileNameFromUrl(fileUrl).toLowerCase();

    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart;
    } else if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      return url.split('/').last;
    } catch (e) {
      return 'Файл';
    }
  }

  // Построение списка задач
  Widget _buildTasksList(TaskProvider taskProvider) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        itemCount: taskProvider.tasks.length,
        itemBuilder: (context, index) {
          final task = taskProvider.tasks[index];
          final isFileAvailable =
              task.file.isNotEmpty && task.file != 'Нет файла';

          return Dismissible(
            key: Key('task-${task.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.delete, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Удалить',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 16),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              return await _showDeleteConfirmation(context, task.description);
            },
            onDismissed: (direction) async {
              await _deleteTask(task.id, task.description);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: InkWell(
                onTap: () => _showTaskDetails(context, task),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Иконка файла с возможностью нажатия
                      GestureDetector(
                        onTap: isFileAvailable
                            ? () {
                                _showFileOptions(context, task.file);
                              }
                            : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isFileAvailable
                                ? _getFileColor(task.file).withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: isFileAvailable
                                ? Border.all(
                                    color: _getFileColor(task.file)
                                        .withOpacity(0.3))
                                : null,
                          ),
                          child: Icon(
                            _getFileIcon(task.file),
                            color: isFileAvailable
                                ? _getFileColor(task.file)
                                : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Блок файла с возможностью нажатия
                            if (isFileAvailable)
                              GestureDetector(
                                onTap: () {
                                  _showFileOptions(context, task.file);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.blue.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.attach_file,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Прикрепленный файл:',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _getFileNameFromUrl(task.file),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.blue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.open_in_new,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'ID задачи: ${task.id}',
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
                      // Кнопка открытия файла
                      if (isFileAvailable)
                        IconButton(
                          icon: Icon(
                            Icons.open_in_new,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: () => _showFileOptions(context, task.file),
                          tooltip: 'Открыть файл',
                        ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
      BuildContext context, String taskDescription) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('Задача "$taskDescription" будет удалена безвозвратно.'),
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

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    if (_isLoading || _practice == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_practice!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPracticeHeader(_practice!),
            const SizedBox(height: 24),
            _buildPracticeDescription(_practice!),
            const SizedBox(height: 32),
            _buildTasksSection(taskProvider),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateTaskDialog(context, _practice!.id);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPracticeHeader(Practice practice) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                practice.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Практическая работа №${practice.numberPractice}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            final practiceProvider =
                Provider.of<PracticeProvider>(context, listen: false);

            try {
              await practiceProvider.togglePracticeCondition(practice.id);
              await _refreshData();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(practice.condition == 'проверено'
                        ? 'Практика отмечена как не проверенная'
                        : 'Практика отмечена как проверенная'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка при изменении статуса: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: practice.condition == 'проверено'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
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
                  size: 16,
                  color: practice.condition == 'проверено'
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  practice.condition,
                  style: TextStyle(
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
    );
  }

  Widget _buildPracticeDescription(Practice practice) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Описание работы',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              practice.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  'Создана: ${practice.createdPracticeAt}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
            if (practice.dateComplete != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Выполнена: ${practice.dateComplete}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection(TaskProvider taskProvider) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Задачи',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(taskProvider.tasks.length.toString()),
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: taskProvider.isLoading
                ? _buildLoadingTasks()
                : taskProvider.tasks.isEmpty
                    ? _buildEmptyTasks()
                    : _buildTasksList(taskProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTasks() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка задач...'),
        ],
      ),
    );
  }

  Widget _buildEmptyTasks() {
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
            'Пока нет задач',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте первую задачу',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, int practiceId) {
    final _taskDescriptionController = TextEditingController();
    Uint8List? _selectedFileBytes;
    String? _fileName;
    final _formKey = GlobalKey<FormState>();
    bool _isUploading = false;

    Future<void> _pickFile() async {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['doc', 'docx', 'xls', 'xlsx', 'pdf', 'txt'],
          allowMultiple: false,
        );

        if (result != null) {
          if (kIsWeb) {
            Uint8List? fileBytes = result.files.single.bytes;
            String fileName = result.files.single.name;

            setState(() {
              _selectedFileBytes = fileBytes;
              _fileName = fileName;
            });
          } else {
            if (result.files.single.path != null) {
              setState(() {
                _selectedFileBytes = result.files.single.bytes;
                _fileName = result.files.single.name;
              });
            }
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора файла: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Новая задача'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _taskDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание задачи *',
                    hintText: 'Введите описание задачи',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите описание задачи';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedFileBytes == null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Выбрать файл (Word, Excel)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Поддерживаемые форматы: .doc, .docx, .xls, .xlsx',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        _buildFileIcon(_fileName),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fileName ?? 'Файл',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _getFileType(_fileName),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedFileBytes = null;
                              _fileName = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                if (_isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Загрузка файла...'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  _isUploading ? null : () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isUploading = true;
                        });

                        final taskProvider =
                            Provider.of<TaskProvider>(context, listen: false);

                        try {
                          final newTask = CreateTask(
                            idPractice: practiceId,
                            description: _taskDescriptionController.text,
                            file: _selectedFileBytes != null
                                ? 'Загружается...'
                                : 'Нет файла',
                          );

                          if (_selectedFileBytes != null) {
                            await taskProvider.createTaskWithFile(
                                newTask, _selectedFileBytes!, _fileName!);
                          } else {
                            await taskProvider.createTask(newTask);
                          }

                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Задача успешно создана!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка при создании задачи: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isUploading = false;
                            });
                          }
                        }
                      }
                    },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(String? fileName) {
    if (fileName == null)
      return const Icon(Icons.insert_drive_file, color: Colors.green);

    if (fileName.toLowerCase().endsWith('.doc') ||
        fileName.toLowerCase().endsWith('.docx')) {
      return const Icon(Icons.description, color: Colors.blue);
    } else if (fileName.toLowerCase().endsWith('.xls') ||
        fileName.toLowerCase().endsWith('.xlsx')) {
      return const Icon(Icons.table_chart, color: Colors.green);
    } else if (fileName.toLowerCase().endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  String _getFileType(String? fileName) {
    if (fileName == null) return 'Файл';

    if (fileName.toLowerCase().endsWith('.doc') ||
        fileName.toLowerCase().endsWith('.docx')) {
      return 'Документ Word';
    } else if (fileName.toLowerCase().endsWith('.xls') ||
        fileName.toLowerCase().endsWith('.xlsx')) {
      return 'Таблица Excel';
    } else if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'PDF документ';
    } else if (fileName.toLowerCase().endsWith('.txt')) {
      return 'Текстовый файл';
    } else {
      return 'Файл';
    }
  }
}
