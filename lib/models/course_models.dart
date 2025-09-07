class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final int duration; // em minutos
  final int lessonsCount;
  final int exercisesCount;
  final CourseLevel level;
  final List<String> tags;
  final DateTime createdAt;
  final bool isPopular;
  final bool isFree;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.duration,
    required this.lessonsCount,
    required this.exercisesCount,
    required this.level,
    required this.tags,
    required this.createdAt,
    this.isPopular = false,
    this.isFree = true,
  });

  factory Course.fromFirestore(Map<String, dynamic> data, String id) {
    return Course(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      duration: data['duration'] ?? 0,
      lessonsCount: data['lessonsCount'] ?? 0,
      exercisesCount: data['exercisesCount'] ?? 0,
      level: CourseLevel.values.firstWhere(
        (e) => e.toString() == 'CourseLevel.${data['level']}',
        orElse: () => CourseLevel.beginner,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      isPopular: data['isPopular'] ?? false,
      isFree: data['isFree'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'duration': duration,
      'lessonsCount': lessonsCount,
      'exercisesCount': exercisesCount,
      'level': level.toString().split('.').last,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isPopular': isPopular,
      'isFree': isFree,
    };
  }
}

enum CourseLevel {
  beginner,
  intermediate,
  advanced,
}

extension CourseLevelExtension on CourseLevel {
  String get displayName {
    switch (this) {
      case CourseLevel.beginner:
        return 'Iniciante';
      case CourseLevel.intermediate:
        return 'Intermediário';
      case CourseLevel.advanced:
        return 'Avançado';
    }
  }

  String get emoji {
    switch (this) {
      case CourseLevel.beginner:
        return '🌱';
      case CourseLevel.intermediate:
        return '🌿';
      case CourseLevel.advanced:
        return '🌳';
    }
  }
}

class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String videoUrl;
  final int duration; // em segundos
  final int order;
  final LessonType type;
  final bool isCompleted;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.duration,
    required this.order,
    required this.type,
    this.isCompleted = false,
  });

  factory Lesson.fromFirestore(Map<String, dynamic> data, String id) {
    return Lesson(
      id: id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      duration: data['duration'] ?? 0,
      order: data['order'] ?? 0,
      type: LessonType.values.firstWhere(
        (e) => e.toString() == 'LessonType.${data['type']}',
        orElse: () => LessonType.video,
      ),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'duration': duration,
      'order': order,
      'type': type.toString().split('.').last,
      'isCompleted': isCompleted,
    };
  }
}

enum LessonType {
  video,
  exercise,
  reading,
}

class Exercise {
  final String id;
  final String lessonId;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final int order;

  Exercise({
    required this.id,
    required this.lessonId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.order,
  });

  factory Exercise.fromFirestore(Map<String, dynamic> data, String id) {
    return Exercise(
      id: id,
      lessonId: data['lessonId'] ?? '',
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? 0,
      explanation: data['explanation'] ?? '',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lessonId': lessonId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'order': order,
    };
  }
}

class CourseProgress {
  final String id;
  final String userId;
  final String courseId;
  final List<String> completedLessons;
  final List<String> completedExercises;
  final int currentLessonOrder;
  final double progressPercentage;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool isCompleted;

  CourseProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.completedLessons,
    required this.completedExercises,
    required this.currentLessonOrder,
    required this.progressPercentage,
    required this.startedAt,
    this.completedAt,
    this.isCompleted = false,
  });

  factory CourseProgress.fromFirestore(Map<String, dynamic> data, String id) {
    return CourseProgress(
      id: id,
      userId: data['userId'] ?? '',
      courseId: data['courseId'] ?? '',
      completedLessons: List<String>.from(data['completedLessons'] ?? []),
      completedExercises: List<String>.from(data['completedExercises'] ?? []),
      currentLessonOrder: data['currentLessonOrder'] ?? 0,
      progressPercentage: (data['progressPercentage'] ?? 0.0).toDouble(),
      startedAt: DateTime.fromMillisecondsSinceEpoch(data['startedAt'] ?? 0),
      completedAt: data['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['completedAt'])
          : null,
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'courseId': courseId,
      'completedLessons': completedLessons,
      'completedExercises': completedExercises,
      'currentLessonOrder': currentLessonOrder,
      'progressPercentage': progressPercentage,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
  }
}
