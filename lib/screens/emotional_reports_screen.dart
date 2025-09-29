import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/checkup_streak_service.dart';
import '../services/achievement_service.dart';
import '../services/course_progress_service.dart';
import '../services/luma_ai_service.dart';
import '../services/daily_checkup_history_service.dart';
import '../models/achievement.dart';
import '../models/daily_checkup.dart';
import '../utils/app_colors.dart';

class EmotionalReportsScreen extends StatefulWidget {
  const EmotionalReportsScreen({super.key});

  @override
  State<EmotionalReportsScreen> createState() => _EmotionalReportsScreenState();
}

class _EmotionalReportsScreenState extends State<EmotionalReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _registerReportView();
  }

  Future<void> _registerReportView() async {
    try {
      // ✨ CONQUISTAS: Registrar visualização de relatório
      final achievementService = Provider.of<AchievementService>(context, listen: false);
      final newAchievements = await achievementService.onReportViewed();
      
      // Mostrar conquistas desbloqueadas
      if (newAchievements.isNotEmpty) {
        for (final achievement in newAchievements) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🏆 ${achievement.title} desbloqueada! ${achievement.icon}'),
              backgroundColor: Colors.amber,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao registrar visualização de relatório: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relatórios de Bem-estar Emocional',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Visão Geral'),
            Tab(text: 'Streaks'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildStreaksTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer3<CheckupStreakService, CourseProgressService, DailyCheckupHistoryService>(
      builder: (context, streakService, courseProgressService, historyService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCards(streakService),
              const SizedBox(height: 24),
              _buildCourseProgressSection(courseProgressService),
              const SizedBox(height: 24),
              _buildMotivationalMessage(streakService),
              const SizedBox(height: 24),
              _buildWeeklyChart(streakService),
              const SizedBox(height: 24),
              _buildMonthlyProgress(streakService, historyService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(CheckupStreakService streakService) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Streak Atual',
            '${streakService.currentStreak}',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Melhor Streak',
            '${streakService.bestStreak}',
            Icons.emoji_events,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.blackFont : AppColors.whiteBack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.grey.withOpacity(0.5) :  Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:  isDark ? AppColors.whiteBack : AppColors.blackFont,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(CheckupStreakService streakService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.blackFont : AppColors.whiteBack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Humor dos Últimos 7 Dias',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color:  isDark ? AppColors.whiteBack : AppColors.blackFont,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 1: return const Text('😢', style: TextStyle(fontSize: 16));
                          case 2: return const Text('😕', style: TextStyle(fontSize: 16));
                          case 3: return const Text('😐', style: TextStyle(fontSize: 16));
                          case 4: return const Text('😊', style: TextStyle(fontSize: 16));
                          case 5: return const Text('😄', style: TextStyle(fontSize: 16));
                          default: return const Text('');
                        }
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
                        return Text(days[value.toInt() % 7]);
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateMoodData(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 1,
                maxY: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateMoodData() {
    // Dados simulados para demonstração
    return [
      const FlSpot(0, 3),
      const FlSpot(1, 4),
      const FlSpot(2, 3.5),
      const FlSpot(3, 4.5),
      const FlSpot(4, 4),
      const FlSpot(5, 3.8),
      const FlSpot(6, 4.2),
    ];
  }

  Widget _buildStreaksTab() {
    return Consumer2<CheckupStreakService, AchievementService>(
      builder: (context, streakService, achievementService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStreakOverview(streakService),
              const SizedBox(height: 24),
              _buildAchievementsSection(achievementService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakOverview(CheckupStreakService streakService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '${streakService.currentStreak} dias',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Streak Atual',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Continue assim! Você está mantendo sua rotina de checkup emocional há ${streakService.currentStreak} dias consecutivos.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(AchievementService achievementService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  isDark ? AppColors.blackFont : AppColors.whiteBack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Conquistas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.whiteBack : AppColors.blackFont,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${achievementService.unlockedCount}/${achievementService.totalAchievements}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: achievementService.completionPercentage / 100,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          ...achievementService.allAchievements.take(6).map((achievement) => 
            _buildAchievementItem(achievement)).toList(),
          if (achievementService.totalAchievements > 6)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    _showAllAchievements(context, achievementService);
                  },
                  child: Text(
                    'Ver todas as conquistas (${achievementService.totalAchievements})',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: achievement.isUnlocked 
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: achievement.isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:  isDark ? (achievement.isUnlocked ? Colors.white : Colors.grey) : (achievement.isUnlocked ? Colors.black87 : Colors.grey),
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: achievement.isUnlocked ? Colors.grey : Colors.grey.shade400,
                  ),
                ),
                if (achievement.isUnlocked && achievement.unlockedDate != null)
                  Text(
                    'Desbloqueado em ${_formatDate(achievement.unlockedDate!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (achievement.isUnlocked)
            Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 20,
            )
          else
            Icon(
              Icons.lock_outline,
              color: Colors.grey,
              size: 20,
            ),
        ],
      ),
    );
  }

  void _showAllAchievements(BuildContext context, AchievementService achievementService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? AppColors.blackFont : AppColors.whiteBack,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Text(
                    'Todas as Conquistas',
                    style: TextStyle(
                      color: isDark ? AppColors.whiteBack : AppColors.blackFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${achievementService.unlockedCount}/${achievementService.totalAchievements}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: achievementService.allAchievements.length,
                itemBuilder: (context, index) {
                  return _buildAchievementItem(achievementService.allAchievements[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer3<CheckupStreakService, AchievementService, DailyCheckupHistoryService>(
      builder: (context, streakService, achievementService, historyService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthlyProgress(streakService, historyService),
              const SizedBox(height: 24),
              _buildRecentAchievements(achievementService),
              const SizedBox(height: 24),
              _buildHistoryList(streakService, historyService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyProgress(CheckupStreakService streakService, DailyCheckupHistoryService historyService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = endOfMonth.day;

    // Usar SOMENTE dados reais salvos no DailyCheckupHistoryService e apenas checkups concluídos
    final monthCompleted = historyService.checkupHistory
        .where((c) => c.isCompleted && c.date.year == now.year && c.date.month == now.month)
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet();

    // Contar somente até o dia atual (não o mês inteiro ainda não passado)
    final daysElapsed = now.day; // quantos dias já se passaram no mês (1..day)
    final daysWithCheckupToToday = monthCompleted.where((d) => d.day <= now.day).length;
    final progress = daysElapsed == 0 ? 0.0 : daysWithCheckupToToday / daysElapsed;

    debugPrint('📊 MonthlyProgress REAL -> elapsed=$daysElapsed completed=$daysWithCheckupToToday totalMonthDays=$daysInMonth allMonthCompleted=${monthCompleted.length}');
    if (monthCompleted.length <= 40) {
      final ord = monthCompleted.toList()..sort((a,b)=>a.compareTo(b));
      debugPrint('📊 Completed days: ${ord.map((d)=>d.day).join(',')}');
    }

    final monthCheckups = monthCompleted.length; // total concluído no mês inteiro (informativo)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  isDark ? AppColors.blackFont : AppColors.whiteBack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progresso do Mês',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.whiteBack : AppColors.blackFont,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$daysWithCheckupToToday/$daysElapsed dias (até hoje)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:  isDark ? AppColors.whiteBack : AppColors.blackFont,
                      ),
                    ),
                    Text(
                      'Dias concluídos em ${_monthName(now.month)} (mês: $monthCheckups/$daysInMonth)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 6,
                    ),
                  ),
                  Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(CheckupStreakService streakService, DailyCheckupHistoryService historyService) {
    // Preferir fonte unificada do histórico detalhado
    final recentCheckups = historyService.getLastNDaysCheckups(30)
      ..sort((a,b) => b.date.compareTo(a.date));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.blackFont : AppColors.whiteBack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico Recente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color:  isDark ? AppColors.whiteBack : AppColors.blackFont,
            ),
          ),
          const SizedBox(height: 16),
          if (recentCheckups.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Nenhum checkup registrado ainda',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Comece fazendo seu primeiro checkup emocional!',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentCheckups.take(30).map(_buildHistoryItem).toList(),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Janeiro','Fevereiro','Março','Abril','Maio','Junho',
      'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'
    ];
    if (m < 1 || m > 12) return '';
    return months[m-1];
  }

  Widget _buildHistoryItem(DailyCheckup checkup) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: checkup.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  checkup.moodEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${checkup.completionPercentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: checkup.statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatDateHistory(checkup.date),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:  isDark ? AppColors.whiteBack : AppColors.blackFont,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: checkup.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        checkup.overallStatus,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: checkup.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Humor: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(checkup.moodEmoji, style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('Energia: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(checkup.energyEmoji, style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    if (checkup.completedAt != null)
                      Text(
                        '${checkup.completedAt!.hour.toString().padLeft(2, '0')}:${checkup.completedAt!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                if (checkup.notes != null && checkup.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      checkup.notes!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalMessage(CheckupStreakService streakService) {
    final recentCheckups = streakService.getRecentCheckups(days: 7);
    final averageMood = streakService.getAverageMood(days: 7);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Sua Jornada Emocional',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: _generateMotivationalMessage(recentCheckups),
            builder: (context, snapshot) {
              final message = snapshot.data ?? _getDefaultMessage(averageMood);
              return Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: _generateActionSuggestion(recentCheckups),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    snapshot.data!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Future<String> _generateMotivationalMessage(List<DailyCheckup> checkups) async {
    try {
      final lumaService = LumaAIService();
      return await lumaService.generateMotivationalMessage(checkups);
    } catch (e) {
      final averageMood = checkups.isNotEmpty 
          ? checkups.map((c) => c.moodScore).reduce((a, b) => a + b) / checkups.length
          : 3.0;
      return _getDefaultMessage(averageMood);
    }
  }

  Future<String> _generateActionSuggestion(List<DailyCheckup> checkups) async {
    try {
      final lumaService = LumaAIService();
      return lumaService.generateActionSuggestion(checkups);
    } catch (e) {
      return "🌟 Continue cuidando do seu bem-estar emocional com seus checkups diários!";
    }
  }

  String _getDefaultMessage(double averageMood) {
    if (averageMood >= 4.0) {
      return 'Que alegria ver você tão bem! 😄 Seu humor tem estado excelente nos últimos dias. Continue cuidando de si mesmo dessa forma!';
    } else if (averageMood >= 3.0) {
      return 'Você está mantendo um bom equilíbrio emocional! 😊 Seus checkups mostram consistência no autocuidado.';
    } else if (averageMood >= 2.0) {
      return 'Percebo que tem sido um período desafiador. 😐 Lembre-se de que altos e baixos fazem parte da jornada.';
    } else {
      return 'Sei que os últimos dias têm sido difíceis. 💙 Cada checkup mostra sua força em cuidar de si mesmo.';
    }
  }

  String _formatDateHistory(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      const weekdays = ['', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
      return weekdays[date.weekday];
    } else {
      return '${date.day}/${date.month}';
    }
  }

  Widget _buildRecentAchievements(AchievementService achievementService) {
    final recentAchievements = achievementService.getRecentAchievements();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  isDark ? AppColors.blackFont : AppColors.whiteBack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conquistas Recentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.whiteBack : AppColors.blackFont,
            ),
          ),
          const SizedBox(height: 16),
          if (recentAchievements.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, 
                         size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Nenhuma conquista ainda',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Continue usando o app para desbloquear conquistas!',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentAchievements.map((achievement) => 
              _buildRecentAchievementItem(achievement)).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentAchievementItem(Achievement achievement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(achievement.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '🎉 ',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Você conquistou o emblema ',
                      style: TextStyle(
                        fontSize: 14,
                        color:  isDark ? AppColors.whiteBack : AppColors.blackFont,
                      ),
                    ),
                  ],
                ),
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (achievement.unlockedDate != null)
                  Text(
                    _formatDate(achievement.unlockedDate!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.star,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildCourseProgressSection(CourseProgressService courseProgressService) {
    final totalLessons = courseProgressService.totalCompletedLessons;
    final totalExercises = courseProgressService.totalCompletedExercises;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    
    // Dados fictícios dos cursos para calcular cursos completados
    final courseData = {
      'respiracao': {'lessons': 3, 'exercises': 1},
      'mindfulness': {'lessons': 2, 'exercises': 1},
      'emocoes': {'lessons': 1, 'exercises': 0},
    };
    
    final completedCourses = courseProgressService.getTotalCompletedCourses(courseData);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:  isDark ? AppColors.blackFont : AppColors.whiteBack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.grey.withOpacity(0.5) :  Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Progresso dos Cursos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.whiteBack : AppColors.blackFont,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCourseStatItem(
                  'Lições Completadas',
                  totalLessons.toString(),
                  Icons.play_circle_outline,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCourseStatItem(
                  'Exercícios Feitos',
                  totalExercises.toString(),
                  Icons.quiz_outlined,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCourseStatItem(
                  'Cursos Concluídos',
                  completedCourses.toString(),
                  Icons.emoji_events,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCourseStatItem(
                  'Total de Cursos',
                  courseData.length.toString(),
                  Icons.library_books,
                  Colors.purple,
                ),
              ),
            ],
          ),
          if (totalLessons > 0 || totalExercises > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      completedCourses > 0 
                        ? 'Parabéns! Você já concluiu $completedCourses curso${completedCourses > 1 ? 's' : ''}!'
                        : 'Continue aprendendo! Você está fazendo progresso nos cursos.',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
