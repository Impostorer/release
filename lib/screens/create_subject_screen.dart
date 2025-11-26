import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/core/providers/subject_provider.dart';

class CreateSubjectScreen extends StatefulWidget {
  const CreateSubjectScreen({super.key});

  @override
  State<CreateSubjectScreen> createState() => _CreateSubjectScreenState();
}

class _CreateSubjectScreenState extends State<CreateSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();

  @override
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  Future<void> _createSubject() async {
    if (_formKey.currentState!.validate()) {
      final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
      
      try {
        await subjectProvider.createSubject(_subjectNameController.text);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Предмет "${_subjectNameController.text}" создан!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при создании предмета: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание предмета'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: subjectProvider.isLoading ? null : () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
      body: subjectProvider.isLoading
          ? _buildLoadingState()
          : _buildForm(subjectProvider),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Создание предмета...'),
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
          // Заголовок
          Text(
            'Учебные предметы',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создать новый учебный предмет',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 32),
          // Форма
          Expanded(
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Заголовок карточки
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.library_add,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Новый учебный предмет',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Поле ввода названия
                      TextFormField(
                        controller: _subjectNameController,
                        decoration: InputDecoration(
                          labelText: 'Название предмета *',
                          hintText: 'Введите название учебного предмета',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите название предмета';
                          }
                          if (value.length < 3) {
                            return 'Название должно содержать минимум 3 символа';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Кнопка создания
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: subjectProvider.isLoading ? null : _createSubject,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: subjectProvider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Создать предмет',
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