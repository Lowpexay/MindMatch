import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checkup_streak.dart';

class CheckupStreakService extends ChangeNotifier {
  static const String _streakKey = 'checkup_streak_data';
  static const String _lastCheckupKey = 'last_checkup_date';
  static const String _currentStreakKey = 'current_streak_count';
  
  List<CheckupStreak> _streakHistory = [];
  int _currentStreak = 0;
  DateTime? _lastCheckupDate;
  bool _todayCompleted = false;

  List<CheckupStreak> get streakHistory => _streakHistory;
  int get currentStreak => _currentStreak;
  DateTime? get lastCheckupDate => _lastCheckupDate;
  bool get todayCompleted => _todayCompleted;

  CheckupStreakService() {
    _loadStreakData();
  }

  /// Carregar dados salvos
  Future<void> _loadStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Carregar histórico
      final streakDataJson = prefs.getString(_streakKey);
      if (streakDataJson != null) {
        final List<dynamic> streakList = jsonDecode(streakDataJson);
        _streakHistory = streakList.map((item) => CheckupStreak.fromJson(item)).toList();
      }
      
      // Carregar streak atual
      _currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      
      // Carregar última data de checkup
      final lastDateString = prefs.getString(_lastCheckupKey);
      if (lastDateString != null) {
        _lastCheckupDate = DateTime.parse(lastDateString);
      }
      
      // Verificar se hoje já foi feito
      _checkTodayStatus();
      
      // Verificar se precisa resetar streak (se perdeu um dia)
      _checkStreakContinuity();
      
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao carregar dados de streak: $e');
    }
  }

  /// Salvar dados no SharedPreferences
  Future<void> _saveStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Salvar histórico
      final streakJson = jsonEncode(_streakHistory.map((e) => e.toJson()).toList());
      await prefs.setString(_streakKey, streakJson);
      
      // Salvar streak atual
      await prefs.setInt(_currentStreakKey, _currentStreak);
      
      // Salvar última data
      if (_lastCheckupDate != null) {
        await prefs.setString(_lastCheckupKey, _lastCheckupDate!.toIso8601String());
      }
      
    } catch (e) {
      print('❌ Erro ao salvar dados de streak: $e');
    }
  }

  /// Verificar se hoje já foi feito o checkup
  void _checkTodayStatus() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    _todayCompleted = _streakHistory.any((streak) => 
      _isSameDay(streak.date, todayDate) && streak.completed
    );
  }

  /// Verificar continuidade do streak
  void _checkStreakContinuity() {
    if (_lastCheckupDate == null) return;
    
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    // Se a última vez foi antes de ontem, resetar streak
    if (!_isSameDay(_lastCheckupDate!, today) && 
        !_isSameDay(_lastCheckupDate!, yesterday)) {
      _currentStreak = 0;
    }
  }

  /// Marcar checkup como feito hoje
  Future<void> completeCheckup() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Se já foi feito hoje, não fazer nada
    if (_todayCompleted) {
      print('ℹ️ Checkup já foi feito hoje');
      return;
    }
    
    // Calcular novo streak
    if (_lastCheckupDate != null) {
      final yesterday = todayDate.subtract(const Duration(days: 1));
      if (_isSameDay(_lastCheckupDate!, yesterday)) {
        // Continuou o streak
        _currentStreak++;
      } else {
        // Reiniciar streak
        _currentStreak = 1;
      }
    } else {
      // Primeiro checkup
      _currentStreak = 1;
    }
    
    // Adicionar ao histórico
    final newStreak = CheckupStreak(
      date: todayDate,
      completed: true,
      streakCount: _currentStreak,
    );
    
    // Remover entrada de hoje se existir e adicionar nova
    _streakHistory.removeWhere((streak) => _isSameDay(streak.date, todayDate));
    _streakHistory.add(newStreak);
    
    // Atualizar estado
    _lastCheckupDate = todayDate;
    _todayCompleted = true;
    
    // Salvar dados
    await _saveStreakData();
    
    print('✅ Checkup concluído! Streak atual: $_currentStreak');
    notifyListeners();
  }

  /// Verificar se duas datas são do mesmo dia
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Obter dias do mês atual com status de checkup
  List<CheckupStreak> getMonthData(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    
    List<CheckupStreak> monthData = [];
    
    for (int day = 1; day <= lastDay.day; day++) {
      final currentDate = DateTime(month.year, month.month, day);
      
      // Procurar se tem checkup neste dia
      final existingStreak = _streakHistory.firstWhere(
        (streak) => _isSameDay(streak.date, currentDate),
        orElse: () => CheckupStreak(
          date: currentDate,
          completed: false,
          streakCount: 0,
        ),
      );
      
      monthData.add(existingStreak);
    }
    
    return monthData;
  }

  /// Obter total de dias com checkup
  int get totalCheckupDays {
    return _streakHistory.where((streak) => streak.completed).length;
  }

  /// Obter maior streak já alcançado
  int get bestStreak {
    if (_streakHistory.isEmpty) return 0;
    
    int maxStreak = 0;
    int currentSequence = 0;
    
    // Ordenar por data
    final sortedHistory = List<CheckupStreak>.from(_streakHistory)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    DateTime? lastDate;
    
    for (final streak in sortedHistory) {
      if (streak.completed) {
        if (lastDate == null || 
            _isSameDay(streak.date, lastDate.add(const Duration(days: 1)))) {
          currentSequence++;
          maxStreak = maxStreak > currentSequence ? maxStreak : currentSequence;
        } else {
          currentSequence = 1;
        }
        lastDate = streak.date;
      } else {
        currentSequence = 0;
      }
    }
    
    return maxStreak;
  }

  /// Reset manual (para testes)
  Future<void> resetStreak() async {
    _streakHistory.clear();
    _currentStreak = 0;
    _lastCheckupDate = null;
    _todayCompleted = false;
    await _saveStreakData();
    notifyListeners();
    print('🔄 Streak resetado');
  }
}
