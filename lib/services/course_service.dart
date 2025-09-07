import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_models.dart';
import 'achievement_service.dart';

class CourseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AchievementService _achievementService;

  CourseService(this._achievementService);

  // Collections
  static const String coursesCollection = 'courses';
  static const String lessonsCollection = 'lessons';
  static const String exercisesCollection = 'exercises';
  static const String courseProgressCollection = 'course_progress';

  // Cache
  List<Course> _courses = [];
  Map<String, List<Lesson>> _courseLessons = {};
  Map<String, CourseProgress> _userProgress = {};

  List<Course> get courses => _courses;

  Future<void> loadCourses() async {
    try {
      final snapshot = await _firestore
          .collection(coursesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      _courses = snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();

      notifyListeners();
    } catch (e) {
      print('Erro ao carregar cursos: $e');
    }
  }

  Future<List<Course>> getPopularCourses() async {
    try {
      final snapshot = await _firestore
          .collection(coursesCollection)
          .where('isPopular', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(6)
          .get();

      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao carregar cursos populares: $e');
      return [];
    }
  }

  Future<List<Course>> getCoursesByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(coursesCollection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao carregar cursos por categoria: $e');
      return [];
    }
  }

  Future<List<Lesson>> getCourseLessons(String courseId) async {
    if (_courseLessons.containsKey(courseId)) {
      return _courseLessons[courseId]!;
    }

    try {
      final snapshot = await _firestore
          .collection(lessonsCollection)
          .where('courseId', isEqualTo: courseId)
          .orderBy('order')
          .get();

      final lessons = snapshot.docs
          .map((doc) => Lesson.fromFirestore(doc.data(), doc.id))
          .toList();

      _courseLessons[courseId] = lessons;
      return lessons;
    } catch (e) {
      print('Erro ao carregar lições do curso: $e');
      return [];
    }
  }

  Future<List<Exercise>> getLessonExercises(String lessonId) async {
    try {
      final snapshot = await _firestore
          .collection(exercisesCollection)
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => Exercise.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao carregar exercícios da lição: $e');
      return [];
    }
  }

  Future<CourseProgress?> getUserCourseProgress(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final progressKey = '${userId}_$courseId';
    if (_userProgress.containsKey(progressKey)) {
      return _userProgress[progressKey];
    }

    try {
      final snapshot = await _firestore
          .collection(courseProgressCollection)
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final progress = CourseProgress.fromFirestore(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
        _userProgress[progressKey] = progress;
        return progress;
      }

      return null;
    } catch (e) {
      print('Erro ao carregar progresso do curso: $e');
      return null;
    }
  }

  Future<void> enrollInCourse(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final progress = CourseProgress(
        id: '',
        userId: userId,
        courseId: courseId,
        completedLessons: [],
        completedExercises: [],
        currentLessonOrder: 0,
        progressPercentage: 0.0,
        startedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(courseProgressCollection)
          .add(progress.toFirestore());

      _userProgress['${userId}_$courseId'] = progress.copyWith(id: docRef.id);
      notifyListeners();
    } catch (e) {
      print('Erro ao se inscrever no curso: $e');
      throw e;
    }
  }

  Future<void> completeLesson(String courseId, String lessonId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final progress = await getUserCourseProgress(courseId);
      if (progress == null) return;

      final updatedCompletedLessons = List<String>.from(progress.completedLessons);
      if (!updatedCompletedLessons.contains(lessonId)) {
        updatedCompletedLessons.add(lessonId);
      }

      // Calcular novo progresso
      final totalLessons = await getCourseLessons(courseId);
      final newProgressPercentage = (updatedCompletedLessons.length / totalLessons.length) * 100;
      
      final isCompleted = newProgressPercentage >= 100;
      
      final updatedProgress = progress.copyWith(
        completedLessons: updatedCompletedLessons,
        progressPercentage: newProgressPercentage,
        currentLessonOrder: progress.currentLessonOrder + 1,
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
      );

      await _firestore
          .collection(courseProgressCollection)
          .doc(progress.id)
          .update(updatedProgress.toFirestore());

      _userProgress['${userId}_$courseId'] = updatedProgress;

      // Registrar conquistas
      await _achievementService.onLessonCompleted();
      
      if (isCompleted) {
        await _achievementService.onCourseCompleted();
      }

      notifyListeners();
    } catch (e) {
      print('Erro ao completar lição: $e');
      throw e;
    }
  }

  Future<void> completeExercise(String courseId, String exerciseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final progress = await getUserCourseProgress(courseId);
      if (progress == null) return;

      final updatedCompletedExercises = List<String>.from(progress.completedExercises);
      if (!updatedCompletedExercises.contains(exerciseId)) {
        updatedCompletedExercises.add(exerciseId);
      }

      final updatedProgress = progress.copyWith(
        completedExercises: updatedCompletedExercises,
      );

      await _firestore
          .collection(courseProgressCollection)
          .doc(progress.id)
          .update(updatedProgress.toFirestore());

      _userProgress['${userId}_$courseId'] = updatedProgress;

      // Registrar conquistas
      await _achievementService.onExerciseCompleted();

      notifyListeners();
    } catch (e) {
      print('Erro ao completar exercício: $e');
      throw e;
    }
  }

  Future<List<Course>> getUserEnrolledCourses() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final progressSnapshot = await _firestore
          .collection(courseProgressCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final courseIds = progressSnapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toList();

      if (courseIds.isEmpty) return [];

      final coursesSnapshot = await _firestore
          .collection(coursesCollection)
          .where(FieldPath.documentId, whereIn: courseIds)
          .get();

      return coursesSnapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao carregar cursos inscritos: $e');
      return [];
    }
  }

  // Métodos para criar dados de exemplo
  Future<void> createSampleCourses() async {
    final sampleCourses = [
      Course(
        id: '',
        title: 'Gerenciando a Ansiedade',
        description: 'Aprenda técnicas eficazes para identificar, compreender e gerenciar a ansiedade no dia a dia.',
        imageUrl: '',
        category: 'Ansiedade',
        duration: 45,
        lessonsCount: 6,
        exercisesCount: 12,
        level: CourseLevel.beginner,
        tags: ['ansiedade', 'respiração', 'mindfulness', 'técnicas'],
        createdAt: DateTime.now(),
        isPopular: true,
      ),
      Course(
        id: '',
        title: 'Construindo Autoestima',
        description: 'Desenvolva uma autoimagem positiva e aprenda a valorizar suas qualidades únicas.',
        imageUrl: '',
        category: 'Autoestima',
        duration: 60,
        lessonsCount: 8,
        exercisesCount: 16,
        level: CourseLevel.intermediate,
        tags: ['autoestima', 'autoconhecimento', 'confiança'],
        createdAt: DateTime.now(),
        isPopular: true,
      ),
      Course(
        id: '',
        title: 'Relacionamentos Saudáveis',
        description: 'Aprenda a construir e manter relacionamentos equilibrados e significativos.',
        imageUrl: '',
        category: 'Relacionamentos',
        duration: 75,
        lessonsCount: 10,
        exercisesCount: 20,
        level: CourseLevel.intermediate,
        tags: ['relacionamentos', 'comunicação', 'empatia'],
        createdAt: DateTime.now(),
      ),
      Course(
        id: '',
        title: 'Lidando com o Estresse',
        description: 'Identifique fontes de estresse e desenvolva estratégias para lidar com elas de forma saudável.',
        imageUrl: '',
        category: 'Estresse',
        duration: 40,
        lessonsCount: 5,
        exercisesCount: 10,
        level: CourseLevel.beginner,
        tags: ['estresse', 'relaxamento', 'organização'],
        createdAt: DateTime.now(),
      ),
    ];

    for (final course in sampleCourses) {
      await _firestore.collection(coursesCollection).add(course.toFirestore());
    }
  }
}

extension CourseProgressExtension on CourseProgress {
  CourseProgress copyWith({
    String? id,
    String? userId,
    String? courseId,
    List<String>? completedLessons,
    List<String>? completedExercises,
    int? currentLessonOrder,
    double? progressPercentage,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return CourseProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      completedLessons: completedLessons ?? this.completedLessons,
      completedExercises: completedExercises ?? this.completedExercises,
      currentLessonOrder: currentLessonOrder ?? this.currentLessonOrder,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
