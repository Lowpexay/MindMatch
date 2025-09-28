import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../widgets/courses_widget.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Provider.of<CourseService>(context, listen: false).loadCourses();
    } catch (e) {
      _error = 'Erro ao carregar cursos';
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseService = Provider.of<CourseService>(context);
    final courses = courseService.courses;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading && courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: TextStyle(color: isDark ? Colors.white : Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
            ],
        ),
      );
    }

    return CoursesWidget(
      courses: courses,
      title: 'Todos os Cursos',
      showAll: true,
    );
  }
}