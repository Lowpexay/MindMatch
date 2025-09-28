import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/checkup_streak_service.dart';
import '../services/daily_checkup_history_service.dart';
import '../models/checkup_streak.dart';
import '../models/daily_checkup.dart';
import '../utils/app_colors.dart';

class CheckupCalendarScreen extends StatefulWidget {
  const CheckupCalendarScreen({super.key});

  @override
  State<CheckupCalendarScreen> createState() => _CheckupCalendarScreenState();
}

class _CheckupCalendarScreenState extends State<CheckupCalendarScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Checkups',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<CheckupStreakService, DailyCheckupHistoryService>(
        builder: (context, streakService, historyService, child) {
          final monthCheckups = historyService.getCheckupsForMonth(_selectedMonth);
          final last7DaysStats = historyService.getLast7DaysStats();
          
          return Column(
            children: [
              // Header com estatísticas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: _buildStatsGrid(
                  last7DaysStats: last7DaysStats,
                  streakService: streakService,
                  historyService: historyService,
                ),
              ),
              
              // Navegação do mês
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        return Text(
                          _getMonthYearString(_selectedMonth),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white.withOpacity(0.9) : AppColors.textPrimary,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              
              // Calendário
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCalendar(streakService),
                ),
              ),
              
              // Legenda
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('Checkup feito', Colors.orange.shade300),
                    _buildLegendItem('Hoje', AppColors.primary),
                    _buildLegendItem('Sem checkup', Colors.grey.shade300),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Grid responsivo com os 6 cards de métricas.
  Widget _buildStatsGrid({
    required Map<String, double> last7DaysStats,
    required CheckupStreakService streakService,
    required DailyCheckupHistoryService historyService,
  }) {
    // Em telas pequenas (largura < 600) usamos 3 colunas (2 linhas). Em telas maiores 6 em uma linha.
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900; // breakpoint arbitrário
    final crossAxisCount = isWide ? 6 : 3;

    final items = [
      _buildStatCard(
        'Humor Médio',
        '${last7DaysStats['averageMood']?.toStringAsFixed(1) ?? '3.0'}',
        Icons.sentiment_satisfied,
        Colors.blue,
      ),
      _buildStatCard(
        'Energia Média',
        '${last7DaysStats['averageEnergy']?.toStringAsFixed(1) ?? '3.0'}',
        Icons.battery_charging_full,
        Colors.green,
      ),
      _buildStatCard(
        'Checkups',
        '${last7DaysStats['checkupsCompleted']?.toInt() ?? 0}',
        Icons.calendar_today,
        Colors.orange,
      ),
      _buildStatCard(
        'Streak Atual',
        '${streakService.currentStreak}',
        Icons.local_fire_department,
        Colors.red,
      ),
      _buildStatCard(
        'Melhor Streak',
        '${streakService.bestStreak}',
        Icons.emoji_events,
        Colors.amber,
      ),
      _buildStatCard(
        'Total',
        '${historyService.totalCheckupsCompleted}',
        Icons.history,
        Colors.purple,
      ),
    ];

    // Usar GridView.count com shrinkWrap para caber no header.
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.05,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items,
    );
  }

  Widget _buildCalendar(CheckupStreakService streakService) {
    final monthData = streakService.getMonthData(_selectedMonth);
    final today = DateTime.now();
    final firstDayOfWeek = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;
    
    return Column(
      children: [
        // Cabeçalho dos dias da semana
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                .map((day) => Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ))
                .toList(),
          ),
        ),
        
        // Grade do calendário
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42, // 6 semanas * 7 dias
            itemBuilder: (context, index) {
              final dayIndex = index - (firstDayOfWeek % 7);
              
              if (dayIndex < 0 || dayIndex >= monthData.length) {
                return Container(); // Espaços vazios
              }
              
              final dayData = monthData[dayIndex];
              final isToday = _isSameDay(dayData.date, today);
              
              return _buildDayCell(dayData, isToday);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(CheckupStreak dayData, bool isToday) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor;
    Color textColor;
    
    if (isToday) {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
    } else if (dayData.completed) {
      backgroundColor = Colors.orange.shade300;
      textColor = Colors.white;
    } else {
      backgroundColor = isDark ? AppColors.blackFont : AppColors.whiteBack;
      textColor =  isDark ? AppColors.whiteBack : AppColors.blackFont;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${dayData.date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (dayData.completed)
              Icon(
                Icons.favorite,
                size: 12,
                color: textColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _changeMonth(int direction) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + direction,
        1,
      );
    });
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
