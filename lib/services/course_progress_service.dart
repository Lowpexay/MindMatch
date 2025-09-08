import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'achievement_service.dart';

class CourseProgressService extends ChangeNotifier {
  static const String _completedLessonsKeyPrefix = 'completed_lessons_';
  static const String _completedExercisesKeyPrefix = 'completed_exercises_';
  
  final AchievementService? _achievementService;
  
  Map<String, Set<String>> _completedLessonsByCourse = {};
  Map<String, Set<String>> _completedExercisesByCourse = {};
  String? _currentUserId;

  Map<String, Set<String>> get completedLessonsByCourse => _completedLessonsByCourse;
  Map<String, Set<String>> get completedExercisesByCourse => _completedExercisesByCourse;

  CourseProgressService([this._achievementService]) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentUserId != user.uid) {
      _currentUserId = user.uid;
      await _loadProgressData();
    }
  }

  String get _completedLessonsKey => '${_completedLessonsKeyPrefix}${_currentUserId ?? 'anonymous'}';
  String get _completedExercisesKey => '${_completedExercisesKeyPrefix}${_currentUserId ?? 'anonymous'}';

  /// Carregar dados de progresso salvos
  Future<void> _loadProgressData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Carregar lições completadas
      final lessonsJson = prefs.getString(_completedLessonsKey);
      if (lessonsJson != null) {
        final Map<String, dynamic> lessonsData = jsonDecode(lessonsJson);
        _completedLessonsByCourse = lessonsData.map((courseId, lessonIds) => 
          MapEntry(courseId, Set<String>.from(lessonIds as List)));
      }
      
      // Carregar exercícios completados
      final exercisesJson = prefs.getString(_completedExercisesKey);
      if (exercisesJson != null) {
        final Map<String, dynamic> exercisesData = jsonDecode(exercisesJson);
        _completedExercisesByCourse = exercisesData.map((courseId, exerciseIds) => 
          MapEntry(courseId, Set<String>.from(exerciseIds as List)));
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao carregar progresso dos cursos: $e');
    }
  }

  /// Salvar dados de progresso
  Future<void> _saveProgressData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar lições completadas
      final lessonsData = _completedLessonsByCourse.map((courseId, lessonIds) => 
        MapEntry(courseId, lessonIds.toList()));
      await prefs.setString(_completedLessonsKey, jsonEncode(lessonsData));
      
      // Salvar exercícios completados
      final exercisesData = _completedExercisesByCourse.map((courseId, exerciseIds) => 
        MapEntry(courseId, exerciseIds.toList()));
      await prefs.setString(_completedExercisesKey, jsonEncode(exercisesData));
      
    } catch (e) {
      print('❌ Erro ao salvar progresso dos cursos: $e');
    }
  }

  /// Marcar lição como completada
  Future<void> completeLesson(String courseId, String lessonId) async {
    _completedLessonsByCourse.putIfAbsent(courseId, () => <String>{});
    _completedLessonsByCourse[courseId]!.add(lessonId);
    
    await _saveProgressData();
    notifyListeners();
    
    // 🏆 Verificar se desbloqueou conquista
    await _checkAndTriggerAchievements(courseId);
    
    print('✅ Lição $lessonId do curso $courseId marcada como completada');
  }

  /// Marcar exercício como completado
  Future<void> completeExercise(String courseId, String exerciseId) async {
    _completedExercisesByCourse.putIfAbsent(courseId, () => <String>{});
    _completedExercisesByCourse[courseId]!.add(exerciseId);
    
    await _saveProgressData();
    notifyListeners();
    
    // 🏆 Verificar se desbloqueou conquista
    await _checkAndTriggerAchievements(courseId);
    
    print('✅ Exercício $exerciseId do curso $courseId marcado como completado');
  }

  /// Verificar e disparar conquistas relacionadas a cursos
  Future<void> _checkAndTriggerAchievements(String courseId) async {
    if (_achievementService == null) return;
    
    try {
      // Verificar se desbloqueou conquista por lição completada
      await _achievementService!.onLessonCompleted();
      
      // Verificar se desbloqueou conquista por exercício completado
      await _achievementService!.onExerciseCompleted();
      
      // Verificar se o curso foi concluído
      if (isCourseCompletedById(courseId)) {
        await _achievementService!.onCourseCompleted();
      }
      
    } catch (e) {
      print('❌ Erro ao verificar conquistas: $e');
    }
  }

  /// Verificar se lição está completada
  bool isLessonCompleted(String courseId, String lessonId) {
    return _completedLessonsByCourse[courseId]?.contains(lessonId) ?? false;
  }

  /// Verificar se exercício está completado
  bool isExerciseCompleted(String courseId, String exerciseId) {
    return _completedExercisesByCourse[courseId]?.contains(exerciseId) ?? false;
  }

  /// Verificar se um curso específico está completado (versão simples)
  bool isCourseCompletedById(String courseId) {
    final completedLessons = _completedLessonsByCourse[courseId]?.length ?? 0;
    final completedExercises = _completedExercisesByCourse[courseId]?.length ?? 0;
    
    // Considera concluído se tem pelo menos 1 lição e 1 exercício completados
    return completedLessons > 0 && completedExercises > 0;
  }

  /// Calcular porcentagem de conclusão do curso
  double getCourseCompletionPercentage(String courseId) {
    final completedLessons = _completedLessonsByCourse[courseId]?.length ?? 0;
    final completedExercises = _completedExercisesByCourse[courseId]?.length ?? 0;
    
    // Estimar total baseado no que já foi completado ou usar padrão
    final totalItems = 8; // 5 lições + 3 exercícios como padrão
    final completedItems = completedLessons + completedExercises;
    
    return totalItems > 0 ? (completedItems / totalItems * 100) : 0.0;
  }

  /// Verificar se curso está completado
  bool isCourseCompleted(String courseId, int totalLessons, int totalExercises) {
    final completedLessons = _completedLessonsByCourse[courseId]?.length ?? 0;
    final completedExercises = _completedExercisesByCourse[courseId]?.length ?? 0;
    
    return completedLessons == totalLessons && completedExercises == totalExercises;
  }

  /// Obter progresso do curso (0.0 a 1.0)
  double getCourseProgress(String courseId, int totalLessons, int totalExercises) {
    final totalItems = totalLessons + totalExercises;
    if (totalItems == 0) return 0.0;
    
    final completedLessons = _completedLessonsByCourse[courseId]?.length ?? 0;
    final completedExercises = _completedExercisesByCourse[courseId]?.length ?? 0;
    final completedItems = completedLessons + completedExercises;
    
    return completedItems / totalItems;
  }

  /// Obter lições completadas de um curso
  Set<String> getCompletedLessons(String courseId) {
    return _completedLessonsByCourse[courseId] ?? <String>{};
  }

  /// Obter exercícios completados de um curso
  Set<String> getCompletedExercises(String courseId) {
    return _completedExercisesByCourse[courseId] ?? <String>{};
  }

  /// Obter total de lições completadas (todos os cursos)
  int get totalCompletedLessons {
    return _completedLessonsByCourse.values
        .fold(0, (total, lessons) => total + lessons.length);
  }

  /// Obter total de exercícios completados (todos os cursos)
  int get totalCompletedExercises {
    return _completedExercisesByCourse.values
        .fold(0, (total, exercises) => total + exercises.length);
  }

  /// Obter total de cursos completados
  int getTotalCompletedCourses(Map<String, Map<String, int>> courseData) {
    int completedCourses = 0;
    
    for (final courseId in courseData.keys) {
      final totalLessons = courseData[courseId]?['lessons'] ?? 0;
      final totalExercises = courseData[courseId]?['exercises'] ?? 0;
      
      if (isCourseCompleted(courseId, totalLessons, totalExercises)) {
        completedCourses++;
      }
    }
    
    return completedCourses;
  }

  /// Método para atualizar usuário (chamar quando usuário logar/deslogar)
  Future<void> updateUser() async {
    await _checkCurrentUser();
  }

  /// Reset para testes
  Future<void> resetProgress() async {
    _completedLessonsByCourse.clear();
    _completedExercisesByCourse.clear();
    await _saveProgressData();
    notifyListeners();
    print('🔄 Progresso dos cursos resetado');
  }
}
