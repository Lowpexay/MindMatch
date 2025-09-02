class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredCount;
  final String category;
  final DateTime? unlockedDate;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredCount,
    required this.category,
    this.unlockedDate,
    this.isUnlocked = false,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? requiredCount,
    String? category,
    DateTime? unlockedDate,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requiredCount: requiredCount ?? this.requiredCount,
      category: category ?? this.category,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'requiredCount': requiredCount,
      'category': category,
      'unlockedDate': unlockedDate?.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      requiredCount: json['requiredCount'],
      category: json['category'],
      unlockedDate: json['unlockedDate'] != null 
          ? DateTime.parse(json['unlockedDate'])
          : null,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}
