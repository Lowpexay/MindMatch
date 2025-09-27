import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/checkup_streak.dart';
import '../models/daily_checkup.dart';

class CheckupStreakService extends ChangeNotifier {
  static const String _streakKeyPrefix = 'checkup_streak_data_';
  static const String _lastCheckupKeyPrefix = 'last_checkup_date_';
  static const String _currentStreakKeyPrefix = 'current_streak_count_';
  static const String _dailyCheckupKeyPrefix = 'daily_checkup_data_';
  
  List<CheckupStreak> _streakHistory = [];
  List<DailyCheckup> _dailyCheckups = [];
  int _currentStreak = 0;
  DateTime? _lastCheckupDate;
  bool _todayCompleted = false;
  String? _currentUserId;

  List<CheckupStreak> get streakHistory => _streakHistory;
  List<DailyCheckup> get dailyCheckups => _dailyCheckups;
  int get currentStreak => _currentStreak;
  DateTime? get lastCheckupDate => _lastCheckupDate;
  bool get todayCompleted => _todayCompleted;

  CheckupStreakService() {
    // Inicializar com usuário atual (se já logado)
    _checkCurrentUser();
    // Escutar mudanças de autenticação para garantir isolamento por usuário
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _handleAuthChange(user);
    });
  }

  /// Lida com mudanças de autenticação garantindo que os dados do streak
  /// sejam únicos por usuário. Também migra dados locais 'anonymous' para
  /// o primeiro usuário logado (caso o usuário tenha usado o app antes de logar).
  Future<void> _handleAuthChange(User? user) async {
    final newUserId = user?.uid;
    if (newUserId == _currentUserId) return; // Nada mudou

    // Se usuário deslogou: atualizar id e recarregar dados anônimos
    if (newUserId == null) {
      _currentUserId = null;
      await _loadStreakData();
      await _loadDailyCheckups();
      return;
    }

    // Usuário logou ou trocou: migrar dados anônimos se necessário
    await _migrateAnonymousDataIfNeeded(newUserId);

    _currentUserId = newUserId;
    await _loadStreakData();
    await _loadDailyCheckups();
  }

  /// Migra dados salvos sob o namespace 'anonymous' para o usuário real
  /// apenas se o usuário ainda não tiver dados próprios.
  Future<void> _migrateAnonymousDataIfNeeded(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final anonymousStreakKey = '${_streakKeyPrefix}anonymous';
      final anonymousCurrentKey = '${_currentStreakKeyPrefix}anonymous';
      final anonymousLastKey = '${_lastCheckupKeyPrefix}anonymous';
      final anonymousDailyKey = '${_dailyCheckupKeyPrefix}anonymous';

      final userStreakKey = '${_streakKeyPrefix}$userId';
      final userHasData = prefs.containsKey(userStreakKey);

      // Apenas migrar se usuário não tem dados e existir algo anônimo
      if (userHasData) return;
      final hasAnonymous = prefs.containsKey(anonymousStreakKey) || prefs.containsKey(anonymousCurrentKey);
      if (!hasAnonymous) return;

      // Copiar valores
      if (prefs.containsKey(anonymousStreakKey)) {
        final v = prefs.getString(anonymousStreakKey);
        if (v != null) await prefs.setString(userStreakKey, v);
      }
      if (prefs.containsKey(anonymousCurrentKey)) {
        final v = prefs.getInt(anonymousCurrentKey);
        if (v != null) await prefs.setInt('${_currentStreakKeyPrefix}$userId', v);
      }
      if (prefs.containsKey(anonymousLastKey)) {
        final v = prefs.getString(anonymousLastKey);
        if (v != null) await prefs.setString('${_lastCheckupKeyPrefix}$userId', v);
      }
      if (prefs.containsKey(anonymousDailyKey)) {
        final v = prefs.getString(anonymousDailyKey);
        if (v != null) await prefs.setString('${_dailyCheckupKeyPrefix}$userId', v);
      }

      // (Opcional) Limpar chaves anônimas para evitar reutilização cruzada
      await prefs.remove(anonymousStreakKey);
      await prefs.remove(anonymousCurrentKey);
      await prefs.remove(anonymousLastKey);
      await prefs.remove(anonymousDailyKey);

      if (kDebugMode) {
        print('📦 Migração de streak anônimo concluída para usuário $userId');
      }
    } catch (e) {
      print('⚠️ Falha ao migrar dados anônimos: $e');
    }
  }

  Future<void> _checkCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentUserId != user.uid) {
      _currentUserId = user.uid;
      await _loadStreakData();
      await _loadDailyCheckups();
    }
  }

  String get _streakKey => '${_streakKeyPrefix}${_currentUserId ?? 'anonymous'}';
  String get _lastCheckupKey => '${_lastCheckupKeyPrefix}${_currentUserId ?? 'anonymous'}';
  String get _currentStreakKey => '${_currentStreakKeyPrefix}${_currentUserId ?? 'anonymous'}';
  String get _dailyCheckupKey => '${_dailyCheckupKeyPrefix}${_currentUserId ?? 'anonymous'}';

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

  // Métodos para DailyCheckup

  /// Carregar dados de checkups diários
  Future<void> _loadDailyCheckups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyJson = prefs.getString(_dailyCheckupKey);
      
      if (dailyJson != null) {
        final List<dynamic> dailyList = jsonDecode(dailyJson);
        _dailyCheckups = dailyList.map((item) => DailyCheckup.fromJson(item)).toList();
      }
    } catch (e) {
      print('❌ Erro ao carregar checkups diários: $e');
    }
  }

  /// Salvar dados de checkups diários
  Future<void> _saveDailyCheckups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyJson = jsonEncode(_dailyCheckups.map((e) => e.toJson()).toList());
      await prefs.setString(_dailyCheckupKey, dailyJson);
    } catch (e) {
      print('❌ Erro ao salvar checkups diários: $e');
    }
  }

  /// Atualizar ou criar checkup do dia
  Future<void> updateTodayCheckup(DailyCheckup checkup) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Remover checkup existente do dia
    _dailyCheckups.removeWhere((c) => _isSameDay(c.date, todayDate));
    
    // Adicionar o novo
    _dailyCheckups.add(checkup.copyWith(date: todayDate));
    
    // Ordenar por data
    _dailyCheckups.sort((a, b) => b.date.compareTo(a.date));
    
    await _saveDailyCheckups();
    // Se ainda não marcou o streak de hoje como completo, integrar com streak
    if (!_todayCompleted) {
      // Atualiza campos internos de streak sem duplicar lógica
      // Reaproveitando fluxo existente chamando completeCheckup()
      await completeCheckup();
    } else {
      notifyListeners();
    }
  }

  /// Obter checkup de hoje
  DailyCheckup? getTodayCheckup() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    try {
      return _dailyCheckups.firstWhere((c) => _isSameDay(c.date, todayDate));
    } catch (e) {
      return null;
    }
  }

  /// Obter checkups dos últimos N dias
  List<DailyCheckup> getRecentCheckups({int days = 7}) {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: days));
    
    return _dailyCheckups
        .where((c) => c.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Calcular média de humor dos últimos 7 dias
  double getAverageMood({int days = 7}) {
    final recentCheckups = getRecentCheckups(days: days)
        .where((c) => c.moodScore > 0)
        .toList();
    
    if (recentCheckups.isEmpty) return 3.0;
    
    final sum = recentCheckups.map((c) => c.moodScore).reduce((a, b) => a + b);
    return sum / recentCheckups.length;
  }

  /// Método para atualizar usuário (chamar quando usuário logar/deslogar)
  Future<void> updateUser() async {
    await _checkCurrentUser();
  }
}
