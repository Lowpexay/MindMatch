import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/daily_checkup.dart';

class DailyCheckupHistoryService extends ChangeNotifier {
  static const String _checkupHistoryKeyPrefix = 'checkup_history_';
  
  List<DailyCheckup> _checkupHistory = [];
  String? _currentUserId;

  List<DailyCheckup> get checkupHistory => _checkupHistory;

  DailyCheckupHistoryService() {
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentUserId != user.uid) {
      _currentUserId = user.uid;
      _loadCheckupHistory();
    }
  }

  String _getHistoryKey() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '${_checkupHistoryKeyPrefix}anonymous';
    return '${_checkupHistoryKeyPrefix}${user.uid}';
  }

  /// Carregar histórico de checkups
  Future<void> _loadCheckupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = _getHistoryKey();
      final historyJson = prefs.getString(historyKey);
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _checkupHistory = historyList
            .map((item) => DailyCheckup.fromJson(item))
            .toList();
        
        // Ordenar por data (mais recente primeiro)
        _checkupHistory.sort((a, b) => b.date.compareTo(a.date));
        
        print('✅ Histórico de checkups carregado: ${_checkupHistory.length} registros');
      }
    } catch (e) {
      print('❌ Erro ao carregar histórico de checkups: $e');
      _checkupHistory = [];
    }
    notifyListeners();
  }

  /// Salvar histórico de checkups
  Future<void> _saveCheckupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = _getHistoryKey();
      
      final historyJson = json.encode(
        _checkupHistory.map((checkup) => checkup.toJson()).toList()
      );
      
      await prefs.setString(historyKey, historyJson);
      print('✅ Histórico de checkups salvo');
    } catch (e) {
      print('❌ Erro ao salvar histórico de checkups: $e');
    }
  }

  /// Adicionar novo checkup ao histórico
  Future<void> addCheckup(DailyCheckup checkup) async {
    // Verificar se já existe um checkup para esta data
    final existingIndex = _checkupHistory.indexWhere(
      (item) => _isSameDay(item.date, checkup.date)
    );
    
    if (existingIndex != -1) {
      // Atualizar checkup existente
      _checkupHistory[existingIndex] = checkup;
      print('🔄 Checkup atualizado para ${_formatDate(checkup.date)}');
    } else {
      // Adicionar novo checkup
      _checkupHistory.add(checkup);
      print('✅ Novo checkup adicionado para ${_formatDate(checkup.date)}');
    }
    
    // Ordenar por data (mais recente primeiro)
    _checkupHistory.sort((a, b) => b.date.compareTo(a.date));
    
    await _saveCheckupHistory();
    notifyListeners();
  }

  /// Obter checkup de uma data específica
  DailyCheckup? getCheckupForDate(DateTime date) {
    try {
      return _checkupHistory.firstWhere(
        (checkup) => _isSameDay(checkup.date, date)
      );
    } catch (e) {
      return null;
    }
  }

  /// Obter checkups dos últimos N dias
  List<DailyCheckup> getLastNDaysCheckups(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _checkupHistory
        .where((checkup) => checkup.date.isAfter(cutoffDate))
        .toList();
  }

  /// Calcular humor médio dos últimos 7 dias
  double getAverageMoodLast7Days() {
    final last7DaysCheckups = getLastNDaysCheckups(7);
    
    if (last7DaysCheckups.isEmpty) {
      return 3.0; // Valor neutro padrão
    }
    
    final totalMood = last7DaysCheckups
        .where((checkup) => checkup.moodScore > 0)
        .fold(0.0, (sum, checkup) => sum + checkup.moodScore);
    
    final validCheckups = last7DaysCheckups
        .where((checkup) => checkup.moodScore > 0)
        .length;
    
    return validCheckups > 0 ? totalMood / validCheckups : 3.0;
  }

  /// Calcular energia média dos últimos 7 dias
  double getAverageEnergyLast7Days() {
    final last7DaysCheckups = getLastNDaysCheckups(7);
    
    if (last7DaysCheckups.isEmpty) {
      return 3.0; // Valor neutro padrão
    }
    
    final totalEnergy = last7DaysCheckups
        .where((checkup) => checkup.energyLevel > 0)
        .fold(0.0, (sum, checkup) => sum + checkup.energyLevel);
    
    final validCheckups = last7DaysCheckups
        .where((checkup) => checkup.energyLevel > 0)
        .length;
    
    return validCheckups > 0 ? totalEnergy / validCheckups : 3.0;
  }

  /// Calcular estresse médio dos últimos 7 dias
  double getAverageStressLast7Days() {
    final last7DaysCheckups = getLastNDaysCheckups(7);
    
    if (last7DaysCheckups.isEmpty) {
      return 3.0; // Valor neutro padrão
    }
    
    final totalStress = last7DaysCheckups
        .where((checkup) => checkup.stressLevel > 0)
        .fold(0.0, (sum, checkup) => sum + checkup.stressLevel);
    
    final validCheckups = last7DaysCheckups
        .where((checkup) => checkup.stressLevel > 0)
        .length;
    
    return validCheckups > 0 ? totalStress / validCheckups : 3.0;
  }

  /// Obter estatísticas dos últimos 7 dias
  Map<String, double> getLast7DaysStats() {
    return {
      'averageMood': getAverageMoodLast7Days(),
      'averageEnergy': getAverageEnergyLast7Days(),
      'averageStress': getAverageStressLast7Days(),
      'checkupsCompleted': getLastNDaysCheckups(7).length.toDouble(),
    };
  }

  /// Obter checkups por mês
  List<DailyCheckup> getCheckupsForMonth(DateTime month) {
    return _checkupHistory
        .where((checkup) => 
            checkup.date.year == month.year && 
            checkup.date.month == month.month)
        .toList();
  }

  /// Obter total de checkups realizados
  int get totalCheckupsCompleted => _checkupHistory.length;

  /// Verificar se duas datas são do mesmo dia
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Formatar data para display
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Limpar histórico (para desenvolvimento/teste)
  Future<void> clearHistory() async {
    _checkupHistory.clear();
    await _saveCheckupHistory();
    notifyListeners();
    print('🔄 Histórico de checkups limpo');
  }

  /// Recarregar dados
  Future<void> refresh() async {
    _checkCurrentUser();
    await _loadCheckupHistory();
  }
}
