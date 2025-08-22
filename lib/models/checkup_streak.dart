class CheckupStreak {
  final DateTime date;
  final bool completed;
  final int streakCount;

  CheckupStreak({
    required this.date,
    required this.completed,
    required this.streakCount,
  });

  factory CheckupStreak.fromJson(Map<String, dynamic> json) {
    return CheckupStreak(
      date: DateTime.parse(json['date']),
      completed: json['completed'] ?? false,
      streakCount: json['streakCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'completed': completed,
      'streakCount': streakCount,
    };
  }

  CheckupStreak copyWith({
    DateTime? date,
    bool? completed,
    int? streakCount,
  }) {
    return CheckupStreak(
      date: date ?? this.date,
      completed: completed ?? this.completed,
      streakCount: streakCount ?? this.streakCount,
    );
  }
}
