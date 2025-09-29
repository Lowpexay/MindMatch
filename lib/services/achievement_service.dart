import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/achievement.dart';

class AchievementService extends ChangeNotifier {
  static const String _unlockedAchievementsKeyPrefix = 'unlocked_achievements_';
  static const String _statsKeyPrefix = 'user_stats_';

  List<Achievement> _allAchievements = [];
  List<Achievement> _unlockedAchievements = [];
  Map<String, int> _userStats = {};
  String? _currentUserId;

  List<Achievement> get allAchievements => _allAchievements;
  List<Achievement> get unlockedAchievements => _unlockedAchievements;
  List<Achievement> get lockedAchievements => 
      _allAchievements.where((a) => !a.isUnlocked).toList();
  
  int get totalAchievements => _allAchievements.length;
  int get unlockedCount => _unlockedAchievements.length;
  double get completionPercentage => 
      totalAchievements > 0 ? (unlockedCount / totalAchievements) * 100 : 0;

  AchievementService() {
    _initializeAchievements();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentUserId != user.uid) {
      _currentUserId = user.uid;
      await _loadAchievementData();
    }
  }

  String get _unlockedAchievementsKey => '${_unlockedAchievementsKeyPrefix}${_currentUserId ?? 'anonymous'}';
  String get _statsKey => '${_statsKeyPrefix}${_currentUserId ?? 'anonymous'}';

  void _initializeAchievements() {
    _allAchievements = [
      // Conquistas de Checkup
      Achievement(
        id: 'first_checkup',
        title: 'Primeiro Passo',
        description: 'Complete seu primeiro checkup emocional',
        icon: '🌱',
        requiredCount: 1,
        category: 'checkup',
      ),
      Achievement(
        id: 'checkup_streak_3',
        title: 'Consistência',
        description: 'Mantenha um streak de 3 dias',
        icon: '🔥',
        requiredCount: 3,
        category: 'checkup',
      ),
      Achievement(
        id: 'checkup_streak_7',
        title: 'Uma Semana Forte',
        description: 'Mantenha um streak de 7 dias',
        icon: '💪',
        requiredCount: 7,
        category: 'checkup',
      ),
      Achievement(
        id: 'checkup_streak_30',
        title: 'Dedicação Total',
        description: 'Mantenha um streak de 30 dias',
        icon: '👑',
        requiredCount: 30,
        category: 'checkup',
      ),
      Achievement(
        id: 'checkup_100',
        title: 'Centenário',
        description: 'Complete 100 checkups',
        icon: '💯',
        requiredCount: 100,
        category: 'checkup',
      ),

      // Conquistas de Bem-estar
      Achievement(
        id: 'happy_week',
        title: 'Semana Feliz',
        description: 'Tenha humor positivo por 7 dias seguidos',
        icon: '😄',
        requiredCount: 7,
        category: 'wellbeing',
      ),
      Achievement(
        id: 'mood_tracker',
        title: 'Observador de Humor',
        description: 'Registre diferentes tipos de humor',
        icon: '📊',
        requiredCount: 5,
        category: 'wellbeing',
      ),

      // Conquistas de Engajamento
      Achievement(
        id: 'app_explorer',
        title: 'Explorador',
        description: 'Acesse todas as seções do app',
        icon: '🗺️',
        requiredCount: 5,
        category: 'engagement',
      ),
      Achievement(
        id: 'daily_user',
        title: 'Usuário Diário',
        description: 'Use o app por 10 dias no mês',
        icon: '📱',
        requiredCount: 10,
        category: 'engagement',
      ),
      Achievement(
        id: 'report_viewer',
        title: 'Analista',
        description: 'Visualize seus relatórios 5 vezes',
        icon: '📈',
        requiredCount: 5,
        category: 'engagement',
      ),

      // Conquistas Especiais
      Achievement(
        id: 'night_owl',
        title: 'Coruja Noturna',
        description: 'Faça checkup após 22h',
        icon: '🦉',
        requiredCount: 1,
        category: 'special',
      ),
      Achievement(
        id: 'early_bird',
        title: 'Madrugador',
        description: 'Faça checkup antes das 7h',
        icon: '🌅',
        requiredCount: 1,
        category: 'special',
      ),
      Achievement(
        id: 'weekend_warrior',
        title: 'Guerreiro do Fim de Semana',
        description: 'Mantenha streak no fim de semana',
        icon: '⚔️',
        requiredCount: 2,
        category: 'special',
      ),
      
      // Conquistas de Cursos
      Achievement(
        id: 'first_lesson',
        title: 'Estudante Iniciante',
        description: 'Complete sua primeira aula',
        icon: '📚',
        requiredCount: 1,
        category: 'course',
      ),
      Achievement(
        id: 'lesson_streak_5',
        title: 'Dedicado aos Estudos',
        description: 'Complete 5 aulas',
        icon: '🎓',
        requiredCount: 5,
        category: 'course',
      ),
      Achievement(
        id: 'lesson_streak_20',
        title: 'Expert em Aprendizado',
        description: 'Complete 20 aulas',
        icon: '🏆',
        requiredCount: 20,
        category: 'course',
      ),
      Achievement(
        id: 'first_course',
        title: 'Curso Concluído',
        description: 'Complete seu primeiro curso',
        icon: '🌟',
        requiredCount: 1,
        category: 'course',
      ),
      Achievement(
        id: 'course_master',
        title: 'Mestre dos Cursos',
        description: 'Complete 5 cursos',
        icon: '👨‍🎓',
        requiredCount: 5,
        category: 'course',
      ),
      Achievement(
        id: 'exercise_starter',
        title: 'Praticante',
        description: 'Complete 10 exercícios',
        icon: '💪',
        requiredCount: 10,
        category: 'course',
      ),
      Achievement(
        id: 'exercise_master',
        title: 'Mestre dos Exercícios',
        description: 'Complete 50 exercícios',
        icon: '🥇',
        requiredCount: 50,
        category: 'course',
      ),
    ];
  }

  Future<void> _loadAchievementData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Carregar conquistas desbloqueadas
      final unlockedJson = prefs.getString(_unlockedAchievementsKey);
      if (unlockedJson != null) {
        final List<dynamic> unlockedList = jsonDecode(unlockedJson);
        _unlockedAchievements = unlockedList.map((item) => Achievement.fromJson(item)).toList();
        
        // Atualizar status das conquistas
        for (var unlocked in _unlockedAchievements) {
          final index = _allAchievements.indexWhere((a) => a.id == unlocked.id);
          if (index != -1) {
            _allAchievements[index] = _allAchievements[index].copyWith(
              isUnlocked: true,
              unlockedDate: unlocked.unlockedDate,
            );
          }
        }
      }
      
      // Carregar estatísticas do usuário
      final statsJson = prefs.getString(_statsKey);
      if (statsJson != null) {
        final Map<String, dynamic> statsMap = jsonDecode(statsJson);
        _userStats = statsMap.map((key, value) => MapEntry(key, value as int));
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados de conquistas: $e');
    }
  }

  Future<void> _saveAchievementData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar conquistas desbloqueadas
      final unlockedJson = jsonEncode(_unlockedAchievements.map((a) => a.toJson()).toList());
      await prefs.setString(_unlockedAchievementsKey, unlockedJson);
      
      // Salvar estatísticas
      final statsJson = jsonEncode(_userStats);
      await prefs.setString(_statsKey, statsJson);
    } catch (e) {
      debugPrint('Erro ao salvar dados de conquistas: $e');
    }
  }

  Future<List<Achievement>> updateStats(String statKey, int value) async {
    final oldValue = _userStats[statKey] ?? 0;
    _userStats[statKey] = oldValue + value;
    final newValue = _userStats[statKey];
    
    print('🏆 DEBUG: updateStats - $statKey: $oldValue + $value = $newValue');
    
    final newAchievements = await _checkForNewAchievements();
    await _saveAchievementData();
    
    print('🏆 DEBUG: updateStats returning ${newAchievements.length} new achievements');
    return newAchievements;
  }

  Future<List<Achievement>> _checkForNewAchievements() async {
    final List<Achievement> newlyUnlocked = [];
    
    for (var achievement in _allAchievements) {
      if (!achievement.isUnlocked) {
        bool shouldUnlock = false;
        
        switch (achievement.id) {
          case 'first_checkup':
            shouldUnlock = (_userStats['checkups_completed'] ?? 0) >= 1;
            break;
          case 'checkup_streak_3':
            shouldUnlock = (_userStats['current_streak'] ?? 0) >= 3;
            break;
          case 'checkup_streak_7':
            shouldUnlock = (_userStats['current_streak'] ?? 0) >= 7;
            break;
          case 'checkup_streak_30':
            shouldUnlock = (_userStats['current_streak'] ?? 0) >= 30;
            break;
          case 'checkup_100':
            shouldUnlock = (_userStats['checkups_completed'] ?? 0) >= 100;
            break;
          case 'happy_week':
            shouldUnlock = (_userStats['happy_streak'] ?? 0) >= 7;
            break;
          case 'mood_tracker':
            shouldUnlock = (_userStats['different_moods'] ?? 0) >= 5;
            break;
          case 'app_explorer':
            shouldUnlock = (_userStats['sections_visited'] ?? 0) >= 5;
            break;
          case 'daily_user':
            shouldUnlock = (_userStats['days_used'] ?? 0) >= 10;
            break;
          case 'report_viewer':
            shouldUnlock = (_userStats['reports_viewed'] ?? 0) >= 5;
            break;
          case 'night_owl':
            shouldUnlock = (_userStats['night_checkups'] ?? 0) >= 1;
            break;
          case 'early_bird':
            shouldUnlock = (_userStats['early_checkups'] ?? 0) >= 1;
            break;
          case 'weekend_warrior':
            shouldUnlock = (_userStats['weekend_streaks'] ?? 0) >= 2;
            break;
          // --- Course related achievements (previously missing unlock logic) ---
          case 'first_lesson':
            shouldUnlock = (_userStats['lessons_completed'] ?? 0) >= 1;
            break;
          case 'lesson_streak_5':
            shouldUnlock = (_userStats['lessons_completed'] ?? 0) >= 5;
            break;
          case 'lesson_streak_20':
            shouldUnlock = (_userStats['lessons_completed'] ?? 0) >= 20;
            break;
          case 'first_course':
            shouldUnlock = (_userStats['courses_completed'] ?? 0) >= 1;
            break;
          case 'course_master':
            shouldUnlock = (_userStats['courses_completed'] ?? 0) >= 5;
            break;
          case 'exercise_starter':
            shouldUnlock = (_userStats['exercises_completed'] ?? 0) >= 10;
            break;
          case 'exercise_master':
            shouldUnlock = (_userStats['exercises_completed'] ?? 0) >= 50;
            break;
        }
        
        if (shouldUnlock) {
          final unlockedAchievement = achievement.copyWith(
            isUnlocked: true,
            unlockedDate: DateTime.now(),
          );
          
          // Atualizar na lista principal
          final index = _allAchievements.indexWhere((a) => a.id == achievement.id);
          _allAchievements[index] = unlockedAchievement;
          
          // Adicionar à lista de desbloqueadas
          _unlockedAchievements.add(unlockedAchievement);
          newlyUnlocked.add(unlockedAchievement);
        }
      }
    }
    
    if (newlyUnlocked.isNotEmpty) {
      notifyListeners();
    }
    
    return newlyUnlocked;
  }

  List<Achievement> getAchievementsByCategory(String category) {
    return _allAchievements.where((a) => a.category == category).toList();
  }

  List<Achievement> getRecentAchievements({int limit = 5}) {
    final recent = _unlockedAchievements
        .where((a) => a.unlockedDate != null)
        .toList()
      ..sort((a, b) => b.unlockedDate!.compareTo(a.unlockedDate!));
    
    return recent.take(limit).toList();
  }

  // Métodos para incrementar estatísticas específicas
  Future<List<Achievement>> onCheckupCompleted(int streak, int hour) async {
    print('🏆 DEBUG: onCheckupCompleted called with streak: $streak, hour: $hour');
    final newAchievements = <Achievement>[];
    
    newAchievements.addAll(await updateStats('checkups_completed', 1));
    newAchievements.addAll(await updateStats('current_streak', 0)); // Set value
    _userStats['current_streak'] = streak;
    
    // Verificar horários especiais
    if (hour >= 22 || hour <= 5) {
      newAchievements.addAll(await updateStats('night_checkups', 1));
    }
    if (hour >= 5 && hour <= 7) {
      newAchievements.addAll(await updateStats('early_checkups', 1));
    }
    
    print('🏆 DEBUG: onCheckupCompleted returning ${newAchievements.length} achievements');
    return newAchievements.toSet().toList(); // Remove duplicatas
  }

  Future<List<Achievement>> onReportViewed() async {
    return await updateStats('reports_viewed', 1);
  }

  Future<List<Achievement>> onSectionVisited() async {
    return await updateStats('sections_visited', 1);
  }

  Future<List<Achievement>> onHappyMood() async {
    return await updateStats('happy_streak', 1);
  }

  Future<List<Achievement>> onDifferentMood() async {
    return await updateStats('different_moods', 1);
  }

  // Course-related achievement methods
  Future<List<Achievement>> onLessonCompleted() async {
    return await updateStats('lessons_completed', 1);
  }

  Future<List<Achievement>> onCourseCompleted() async {
    return await updateStats('courses_completed', 1);
  }

  Future<List<Achievement>> onExerciseCompleted() async {
    return await updateStats('exercises_completed', 1);
  }

  /// Método para atualizar usuário (chamar quando usuário logar/deslogar)
  Future<void> updateUser() async {
    await _checkCurrentUser();
  }
}
