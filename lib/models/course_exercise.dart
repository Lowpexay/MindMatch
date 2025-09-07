import 'question.dart';

class CourseExercise {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<Question> questions;

  CourseExercise({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.questions,
  });

  factory CourseExercise.fromJson(Map<String, dynamic> json) {
    return CourseExercise(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
