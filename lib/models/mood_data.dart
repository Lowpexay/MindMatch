class MoodData {
  final String userId;
  final DateTime date;
  final int happiness; // 1-10
  final int energy; // 1-10
  final int clarity; // 1-10
  final int stress; // 1-10
  final String? notes;

  MoodData({
    required this.userId,
    required this.date,
    required this.happiness,
    required this.energy,
    required this.clarity,
    required this.stress,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'happiness': happiness,
      'energy': energy,
      'clarity': clarity,
      'stress': stress,
      'notes': notes,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory MoodData.fromMap(Map<String, dynamic> map) {
    return MoodData(
      userId: map['userId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      happiness: map['happiness'] ?? 5,
      energy: map['energy'] ?? 5,
      clarity: map['clarity'] ?? 5,
      stress: map['stress'] ?? 5,
      notes: map['notes'],
    );
  }

  // Calcula score geral de bem-estar (0-100)
  double get wellnessScore {
    final positiveScore = (happiness + energy + clarity) / 3;
    final stressImpact = (10 - stress) / 10;
    return ((positiveScore / 10) * 0.7 + stressImpact * 0.3) * 100;
  }

  // Verifica se precisa de apoio emocional
  bool get needsSupport {
    return happiness <= 3 || stress >= 8 || wellnessScore < 30;
  }
}
