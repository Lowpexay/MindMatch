class MoodEntry {
  final String id;
  final String userId;
  final DateTime date;
  final int happiness; // 1-5
  final int energy; // 1-5
  final int clarity; // 1-5
  final int stress; // 1-5
  final int socialConnection; // 1-5
  final double overallMood; // calculated average
  final DateTime createdAt;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.happiness,
    required this.energy,
    required this.clarity,
    required this.stress,
    required this.socialConnection,
    required this.overallMood,
    required this.createdAt,
  });

  factory MoodEntry.fromMap(Map<String, dynamic> map, String id) {
    return MoodEntry(
      id: id,
      userId: map['userId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      happiness: map['happiness'] ?? 3,
      energy: map['energy'] ?? 3,
      clarity: map['clarity'] ?? 3,
      stress: map['stress'] ?? 3,
      socialConnection: map['socialConnection'] ?? 3,
      overallMood: (map['overallMood'] ?? 3.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'happiness': happiness,
      'energy': energy,
      'clarity': clarity,
      'stress': stress,
      'socialConnection': socialConnection,
      'overallMood': overallMood,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Calculate overall mood (inverted stress since lower is better)
  static double calculateOverallMood(int happiness, int energy, int clarity, int stress, int socialConnection) {
    return (happiness + energy + clarity + (6 - stress) + socialConnection) / 5.0;
  }

  // Check if emotional support might be needed
  bool get needsSupport {
    return happiness <= 2 || energy <= 2 || stress >= 4 || overallMood <= 2.5;
  }
}
