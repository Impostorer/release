import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'src/core/providers/subject_provider.dart';
import 'src/core/providers/practice_provider.dart';
import 'src/core/providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'screens/subjects_screen.dart';
import 'screens/create_subject_screen.dart';
import 'screens/subject_detail_screen.dart';
import 'screens/create_practice_screen.dart';
import 'screens/practice_detail_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ApiService apiService = ApiService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => SubjectProvider(apiService)),
        ChangeNotifierProvider(
            create: (context) => PracticeProvider(apiService)),
        ChangeNotifierProvider(create: (context) => TaskProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'School Platform',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F6EF7),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F6EF7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        home: const HomeScreen(),
        routes: {
          '/subjects': (context) => const SubjectsScreen(),
          '/create-subject': (context) => const CreateSubjectScreen(),
          '/subject-detail': (context) => const SubjectDetailScreen(),
          '/create-practice': (context) => const CreatePracticeScreen(),
          '/practice-detail': (context) => const PracticeDetailScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
