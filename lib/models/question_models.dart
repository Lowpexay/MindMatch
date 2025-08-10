class ReflectiveQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final String? category;
  final DateTime createdAt;

  ReflectiveQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type.toString(),
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ReflectiveQuestion.fromMap(Map<String, dynamic> map) {
    return ReflectiveQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => QuestionType.philosophical,
      ),
      category: map['category'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}

enum QuestionType {
  philosophical, // Questões filosóficas e morais
  personal,      // Questões pessoais sobre valores
  social,        // Questões sobre relacionamentos
  funny,         // Questões divertidas
  hypothetical,  // Situações hipotéticas
}

class QuestionResponse {
  final String userId;
  final String questionId;
  final bool answer; // true = sim, false = não
  final DateTime answeredAt;

  QuestionResponse({
    required this.userId,
    required this.questionId,
    required this.answer,
    required this.answeredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'questionId': questionId,
      'answer': answer,
      'answeredAt': answeredAt.millisecondsSinceEpoch,
    };
  }

  factory QuestionResponse.fromMap(Map<String, dynamic> map) {
    return QuestionResponse(
      userId: map['userId'] ?? '',
      questionId: map['questionId'] ?? '',
      answer: map['answer'] ?? false,
      answeredAt: DateTime.fromMillisecondsSinceEpoch(map['answeredAt'] ?? 0),
    );
  }
}

class CompatibilityResult {
  final String userId;
  final String otherUserId;
  final double compatibilityPercentage;
  final Map<String, int> categoryScores; // Score por categoria de pergunta
  final DateTime calculatedAt;

  CompatibilityResult({
    required this.userId,
    required this.otherUserId,
    required this.compatibilityPercentage,
    required this.categoryScores,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'otherUserId': otherUserId,
      'compatibilityPercentage': compatibilityPercentage,
      'categoryScores': categoryScores,
      'calculatedAt': calculatedAt.millisecondsSinceEpoch,
    };
  }

  factory CompatibilityResult.fromMap(Map<String, dynamic> map) {
    return CompatibilityResult(
      userId: map['userId'] ?? '',
      otherUserId: map['otherUserId'] ?? '',
      compatibilityPercentage: (map['compatibilityPercentage'] ?? 0.0).toDouble(),
      categoryScores: Map<String, int>.from(map['categoryScores'] ?? {}),
      calculatedAt: DateTime.fromMillisecondsSinceEpoch(map['calculatedAt'] ?? 0),
    );
  }
}
