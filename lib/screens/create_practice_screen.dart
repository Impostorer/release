import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject_model.dart';
import '../models/practice_model.dart';
import '../src/core/providers/subject_provider.dart';
import '../src/core/providers/practice_provider.dart';

class CreatePracticeScreen extends StatefulWidget {
  const CreatePracticeScreen({super.key});

  @override
  State<CreatePracticeScreen> createState() => _CreatePracticeScreenState();
}

class _CreatePracticeScreenState extends State<CreatePracticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _practiceNameController = TextEditingController();
  final _practiceDescriptionController = TextEditingController();

  Subject? _selectedSubject;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _practiceNameController.dispose();
    _practiceDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final subjectProvider =
        Provider.of<SubjectProvider>(context, listen: false);
    if (subjectProvider.subjects.isEmpty) {
      await subjectProvider.loadSubjects();
    }
  }

  Future<void> _createPractice() async {
    if (_formKey.currentState!.validate() && _selectedSubject != null) {
      setState(() {
        _isLoading = true;
      });

      final practiceProvider =
          Provider.of<PracticeProvider>(context, listen: false);

      try {
        final practice = CreatePractice(
          idSubject: _selectedSubject!.id,
          name: _practiceNameController.text,
          description: _practiceDescriptionController.text,
        );

        await practiceProvider.createPractice(practice);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Практическая работа "${_practiceNameController.text}" создана!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при создании практики: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите предмет'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание практической работы'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildForm(subjectProvider),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Создание практической работы...'),
        ],
      ),
    );
  }

  Widget _buildForm(SubjectProvider subjectProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Практические работы',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создать новую практическую работу',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.assignment_add,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Новая практическая работа',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<Subject>(
                        value: _selectedSubject,
                        decoration: InputDecoration(
                          labelText: 'Выберите предмет *',
                          prefixIcon: const Icon(Icons.subject),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        items: subjectProvider.subjects.map((Subject subject) {
                          return DropdownMenuItem<Subject>(
                            value: subject,
                            child: Text(subject.title),
                          );
                        }).toList(),
                        onChanged: (Subject? newValue) {
                          setState(() {
                            _selectedSubject = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Пожалуйста, выберите предмет';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _practiceNameController,
                        decoration: InputDecoration(
                          labelText: 'Название практической работы *',
                          hintText: 'Введите название практической работы',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите название работы';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _practiceDescriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Описание работы *',
                          hintText: 'Введите описание практической работы',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите описание работы';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createPractice,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Создать практическую работу',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
