import 'package:flutter/material.dart';

class DailyCheckup {
  final DateTime date;
  final double moodScore; // 1-5 (muito triste a muito feliz)
  final double energyLevel; // 1-5 
  final double stressLevel; // 1-5
  final double sleepQuality; // 1-5
  final String? notes;
  final DateTime? completedAt;
  final bool isCompleted;
  final double completionPercentage; // 0-100

  DailyCheckup({
    required this.date,
    this.moodScore = 0,
    this.energyLevel = 0,
    this.stressLevel = 0,
    this.sleepQuality = 0,
    this.notes,
    this.completedAt,
    this.isCompleted = false,
    this.completionPercentage = 0,
  });

  factory DailyCheckup.fromJson(Map<String, dynamic> json) {
    return DailyCheckup(
      date: DateTime.parse(json['date']),
      moodScore: (json['moodScore'] ?? 0).toDouble(),
      energyLevel: (json['energyLevel'] ?? 0).toDouble(),
      stressLevel: (json['stressLevel'] ?? 0).toDouble(),
      sleepQuality: (json['sleepQuality'] ?? 0).toDouble(),
      notes: json['notes'],
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
      completionPercentage: (json['completionPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'moodScore': moodScore,
      'energyLevel': energyLevel,
      'stressLevel': stressLevel,
      'sleepQuality': sleepQuality,
      'notes': notes,
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'completionPercentage': completionPercentage,
    };
  }

  DailyCheckup copyWith({
    DateTime? date,
    double? moodScore,
    double? energyLevel,
    double? stressLevel,
    double? sleepQuality,
    String? notes,
    DateTime? completedAt,
    bool? isCompleted,
    double? completionPercentage,
  }) {
    return DailyCheckup(
      date: date ?? this.date,
      moodScore: moodScore ?? this.moodScore,
      energyLevel: energyLevel ?? this.energyLevel,
      stressLevel: stressLevel ?? this.stressLevel,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  String get moodEmoji {
    if (moodScore >= 4.5) return '😄';
    if (moodScore >= 3.5) return '😊';
    if (moodScore >= 2.5) return '😐';
    if (moodScore >= 1.5) return '😕';
    return '😢';
  }

  String get energyEmoji {
    if (energyLevel >= 4.5) return '⚡';
    if (energyLevel >= 3.5) return '🔋';
    if (energyLevel >= 2.5) return '🟨';
    if (energyLevel >= 1.5) return '🟧';
    return '🔴';
  }

  String get overallStatus {
    final average = (moodScore + energyLevel + (6 - stressLevel) + sleepQuality) / 4;
    if (average >= 4.0) return 'Excelente';
    if (average >= 3.0) return 'Bom';
    if (average >= 2.0) return 'Regular';
    return 'Precisa de atenção';
  }

  Color get statusColor {
    final average = (moodScore + energyLevel + (6 - stressLevel) + sleepQuality) / 4;
    if (average >= 4.0) return const Color(0xFF4CAF50); // Verde
    if (average >= 3.0) return const Color(0xFF8BC34A); // Verde claro
    if (average >= 2.0) return const Color(0xFFFF9800); // Laranja
    return const Color(0xFFF44336); // Vermelho
  }
}
