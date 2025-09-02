import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_checkup.dart';

class LumaAIService {
  static const String _baseUrl = 'https://api.lumalabs.ai'; // URL fictícia para demonstração
  
  /// Gera uma mensagem motivacional baseada nos dados de humor dos últimos 7 dias
  Future<String> generateMotivationalMessage(List<DailyCheckup> recentCheckups) async {
    try {
      // Calcular estatísticas dos últimos 7 dias
      final moodAverage = _calculateMoodAverage(recentCheckups);
      final energyAverage = _calculateEnergyAverage(recentCheckups);
      final stressAverage = _calculateStressAverage(recentCheckups);
      final completionRate = _calculateCompletionRate(recentCheckups);
      
      // Criar contexto para a Luma
      final context = _buildContextString(
        moodAverage, 
        energyAverage, 
        stressAverage, 
        completionRate,
        recentCheckups.length
      );
      
      // Simular chamada para API da Luma (substituir pela API real)
      return await _generateWithLuma(context);
    } catch (e) {
      // Fallback para mensagens locais se a API falhar
      return _generateLocalMessage(recentCheckups);
    }
  }

  double _calculateMoodAverage(List<DailyCheckup> checkups) {
    if (checkups.isEmpty) return 3.0;
    final validCheckups = checkups.where((c) => c.moodScore > 0).toList();
    if (validCheckups.isEmpty) return 3.0;
    return validCheckups.map((c) => c.moodScore).reduce((a, b) => a + b) / validCheckups.length;
  }

  double _calculateEnergyAverage(List<DailyCheckup> checkups) {
    if (checkups.isEmpty) return 3.0;
    final validCheckups = checkups.where((c) => c.energyLevel > 0).toList();
    if (validCheckups.isEmpty) return 3.0;
    return validCheckups.map((c) => c.energyLevel).reduce((a, b) => a + b) / validCheckups.length;
  }

  double _calculateStressAverage(List<DailyCheckup> checkups) {
    if (checkups.isEmpty) return 2.5;
    final validCheckups = checkups.where((c) => c.stressLevel > 0).toList();
    if (validCheckups.isEmpty) return 2.5;
    return validCheckups.map((c) => c.stressLevel).reduce((a, b) => a + b) / validCheckups.length;
  }

  double _calculateCompletionRate(List<DailyCheckup> checkups) {
    if (checkups.isEmpty) return 0.0;
    final completedCount = checkups.where((c) => c.isCompleted).length;
    return (completedCount / checkups.length) * 100;
  }

  String _buildContextString(double mood, double energy, double stress, double completion, int days) {
    return '''
Analise o bem-estar emocional do usuário e gere uma mensagem motivacional personalizada em português brasileiro:

Dados dos últimos $days dias:
- Humor médio: ${mood.toStringAsFixed(1)}/5.0
- Energia média: ${energy.toStringAsFixed(1)}/5.0  
- Nível de estresse médio: ${stress.toStringAsFixed(1)}/5.0
- Taxa de conclusão dos checkups: ${completion.toStringAsFixed(1)}%

Gere uma mensagem motivacional de 2-3 frases que:
1. Reconheça o estado atual do usuário
2. Ofereça encorajamento específico baseado nos dados
3. Sugira uma ação positiva ou reflexão
4. Use tom amigável e empático
5. Seja personalizada para os dados específicos
''';
  }

  Future<String> _generateWithLuma(String context) async {
    // Implementação futura da API da Luma
    // Por enquanto, retorna uma mensagem baseada no contexto local
    return _generateLocalMessage([]);
  }

  String _generateLocalMessage(List<DailyCheckup> checkups) {
    final moodAverage = _calculateMoodAverage(checkups);
    final completionRate = _calculateCompletionRate(checkups);
    
    // Mensagens baseadas no humor médio
    if (moodAverage >= 4.0) {
      return '''Que alegria ver você tão bem! 😄 Seu humor tem estado excelente nos últimos dias. Continue cuidando de si mesmo dessa forma, você está no caminho certo para o bem-estar emocional.''';
    } else if (moodAverage >= 3.0) {
      return '''Você está mantendo um bom equilíbrio emocional! 😊 Seus checkups mostram consistência no autocuidado. Que tal experimentar uma atividade nova hoje para elevar ainda mais seu humor?''';
    } else if (moodAverage >= 2.0) {
      return '''Percebo que tem sido um período desafiador. 😐 Lembre-se de que altos e baixos fazem parte da jornada. Você está fazendo sua parte ao se acompanhar diariamente - isso já é um grande passo!''';
    } else {
      return '''Sei que os últimos dias têm sido difíceis. 💙 Cada checkup que você faz mostra sua força e determinação em cuidar de si mesmo. Você não está sozinho nesta jornada.''';
    }
  }

  /// Gera sugestões específicas baseadas nos padrões dos dados
  String generateActionSuggestion(List<DailyCheckup> checkups) {
    final moodAverage = _calculateMoodAverage(checkups);
    final energyAverage = _calculateEnergyAverage(checkups);
    final stressAverage = _calculateStressAverage(checkups);
    
    if (stressAverage >= 4.0) {
      return "💆‍♀️ Que tal experimentar uma técnica de relaxamento hoje? Respiração profunda ou uma caminhada podem ajudar.";
    } else if (energyAverage <= 2.0) {
      return "⚡ Sua energia parece baixa. Considere uma caminhada ao ar livre ou um lanche saudável para revigorar-se.";
    } else if (moodAverage >= 4.0) {
      return "🌟 Você está radiante! Que tal compartilhar essa energia positiva fazendo algo gentil por alguém hoje?";
    } else {
      return "🎯 Continue com seus checkups diários - você está construindo um hábito muito valioso para seu bem-estar!";
    }
  }
}
