import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../models/course_models.dart';
import '../models/course_exercise.dart';
import '../models/question.dart';
import '../utils/app_colors.dart';
import '../services/achievement_service.dart';
import '../services/course_progress_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  List<Lesson> _lessons = [];
  List<CourseExercise> _exercises = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final lessons = _getLessonsForCourse(widget.course.id);
    final exercises = _getExercisesForCourse(widget.course.id);
    
    if (mounted) {
      setState(() {
        _lessons = lessons;
        _exercises = exercises;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkCourseCompletion() async {
    final progressService = Provider.of<CourseProgressService>(context, listen: false);
    final isCourseCompleted = progressService.isCourseCompleted(
      widget.course.id, 
      _lessons.length, 
      _exercises.length
    );
    
    if (isCourseCompleted) {
      await _onCourseCompleted();
      _showCompletionCelebration();
    }
  }

  Future<void> _onCourseCompleted() async {
    try {
      // ✨ CONQUISTAS: Registrar conclusão de curso
      final achievementService = Provider.of<AchievementService>(context, listen: false);
      final newAchievements = await achievementService.onCourseCompleted();
      
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
      print('❌ Erro ao registrar conclusão do curso: $e');
    }
  }

  void _showCompletionCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                '🎉 Parabéns! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Você concluiu o curso:\n"${widget.course.title}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.school,
                      size: 40,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Curso Concluído!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Continue explorando outros cursos!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar Aprendendo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseHeader(),
                  _buildProgressBar(),
                  _buildTabSelector(),
                  _buildSelectedTabContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildCourseHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _getCourseGradient(widget.course.category),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getCourseIcon(widget.course.category),
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.course.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.course.duration} min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.course.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.course.description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(Icons.play_circle_outline, '${_lessons.length} aulas'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.quiz_outlined, '${_exercises.length} exercícios'),
              const SizedBox(width: 12),
              _buildStatChip(Icons.star, widget.course.level.displayName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Consumer<CourseProgressService>(
      builder: (context, progressService, child) {
        final totalItems = _lessons.length + _exercises.length;
        final completedLessons = progressService.getCompletedLessons(widget.course.id).length;
        final completedExercises = progressService.getCompletedExercises(widget.course.id).length;
        final completedItems = completedLessons + completedExercises;
        final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progresso do Curso',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedItems de $totalItems itens concluídos',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Aulas', 0)),
          const SizedBox(width: 8),
          Expanded(child: _buildTabButton('Exercícios', 1)),
          const SizedBox(width: 8),
          Expanded(child: _buildTabButton('Sobre', 2)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildLessonsContent();
      case 1:
        return _buildExercisesContent();
      case 2:
        return _buildAboutContent();
      default:
        return _buildLessonsContent();
    }
  }

  Widget _buildLessonsContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aulas do Curso',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lessons.length,
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              return Consumer<CourseProgressService>(
                builder: (context, progressService, child) {
                  final isCompleted = progressService.isLessonCompleted(widget.course.id, lesson.id);
                  return _buildLessonCard(lesson, index + 1, isCompleted);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson, int order, bool isCompleted) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCompleted ? Border.all(color: Colors.green, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LessonScreen(
                lesson: lesson,
                course: widget.course,
                onLessonCompleted: () async {
                  // Salvar progresso no serviço
                  final progressService = Provider.of<CourseProgressService>(context, listen: false);
                  await progressService.completeLesson(widget.course.id, lesson.id);
                  
                  // ✨ CONQUISTAS: Registrar conclusão de lição
                  try {
                    final achievementService = Provider.of<AchievementService>(context, listen: false);
                    final newAchievements = await achievementService.onLessonCompleted();
                    
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
                    print('❌ Erro ao registrar conclusão de lição: $e');
                  }
                  
                  await _checkCourseCompletion();
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text(
                          '$order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          lesson.type == LessonType.video
                              ? Icons.play_circle_outline
                              : Icons.article_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(lesson.duration / 60).ceil()} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Concluída',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExercisesContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exercícios do Curso',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exercises.length,
            itemBuilder: (context, index) {
              final exercise = _exercises[index];
              return Consumer<CourseProgressService>(
                builder: (context, progressService, child) {
                  final isCompleted = progressService.isExerciseCompleted(widget.course.id, exercise.id);
                  return _buildExerciseCard(exercise, index + 1, isCompleted);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(CourseExercise exercise, int order, bool isCompleted) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCompleted ? Border.all(color: Colors.green, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showExerciseDialog(exercise);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text(
                          '$order',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.quiz_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${exercise.questions.length} perguntas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Concluído',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre o Curso',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.course.description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalhes do Curso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Nível', widget.course.level.displayName),
                _buildDetailRow('Duração', '${widget.course.duration} minutos'),
                _buildDetailRow('Aulas', '${_lessons.length} vídeos'),
                _buildDetailRow('Exercícios', '${_exercises.length} atividades'),
                _buildDetailRow('Categoria', widget.course.category),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDialog(CourseExercise exercise) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: QuizWidget(
            exercise: exercise,
            onExerciseCompleted: () async {
              // Salvar progresso no serviço
              final progressService = Provider.of<CourseProgressService>(context, listen: false);
              await progressService.completeExercise(widget.course.id, exercise.id);
              
              // ✨ CONQUISTAS: Registrar conclusão de exercício
              try {
                final achievementService = Provider.of<AchievementService>(context, listen: false);
                final newAchievements = await achievementService.onExerciseCompleted();
                
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
                print('❌ Erro ao registrar conclusão de exercício: $e');
              }
              
              await _checkCourseCompletion();
            },
          ),
        ),
      ),
    );
  }

  // Métodos utilitários
  LinearGradient _getCourseGradient(String category) {
    switch (category.toLowerCase()) {
      case 'respiração':
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'mindfulness':
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'emoções':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'autoestima':
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'estresse':
        return const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getCourseIcon(String category) {
    switch (category.toLowerCase()) {
      case 'respiração':
        return Icons.air;
      case 'mindfulness':
        return Icons.self_improvement;
      case 'emoções':
        return Icons.favorite;
      case 'autoestima':
        return Icons.emoji_emotions;
      case 'estresse':
        return Icons.spa;
      default:
        return Icons.school;
    }
  }

  List<Lesson> _getLessonsForCourse(String courseId) {
    switch (courseId) {
      case 'respiracao':
        return [
          Lesson(
            id: 'resp_lesson_1',
            courseId: courseId,
            title: 'Introdução à Respiração Consciente',
            description: 'Aprenda os fundamentos da respiração para relaxamento e bem-estar mental.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=YRPh_GaiL8s',
            duration: 480,
            order: 1,
          ),
          Lesson(
            id: 'resp_lesson_2',
            courseId: courseId,
            title: 'Técnica 4-7-8 para Ansiedade',
            description: 'Uma técnica poderosa para acalmar a mente rapidamente em momentos de estresse.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=gz4G31LGyog',
            duration: 360,
            order: 2,
          ),
          Lesson(
            id: 'resp_lesson_3',
            courseId: courseId,
            title: 'Respiração Diafragmática',
            description: 'Maximize sua oxigenação com a respiração profunda pelo diafragma.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=1Dv-ldGLnMU',
            duration: 420,
            order: 3,
          ),
          Lesson(
            id: 'resp_lesson_4',
            courseId: courseId,
            title: 'Respiração Quadrada (Box Breathing)',
            description: 'Técnica usada por militares e atletas para manter a calma sob pressão.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=tEmt1Znux58',
            duration: 300,
            order: 4,
          ),
          Lesson(
            id: 'resp_lesson_5',
            courseId: courseId,
            title: 'Respiração para Dormir',
            description: 'Técnicas especiais para relaxar e conseguir adormecer naturalmente.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=DbDoBzGY3vo',
            duration: 540,
            order: 5,
          ),
        ];
      case 'mindfulness':
        return [
          Lesson(
            id: 'mind_lesson_1',
            courseId: courseId,
            title: 'O que é Mindfulness?',
            description: 'Conceitos fundamentais da atenção plena e como ela pode transformar sua vida.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=ZToicYcHIOU',
            duration: 600,
            order: 1,
          ),
          Lesson(
            id: 'mind_lesson_2',
            courseId: courseId,
            title: 'Meditação da Respiração',
            description: 'Prática guiada de meditação focada na respiração para iniciantes.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=inpok4MKVLM',
            duration: 900,
            order: 2,
          ),
          Lesson(
            id: 'mind_lesson_3',
            courseId: courseId,
            title: 'Meditação do Corpo',
            description: 'Escaneamento corporal para conectar-se com o momento presente.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=15q-N-_kkrU',
            duration: 720,
            order: 3,
          ),
          Lesson(
            id: 'mind_lesson_4',
            courseId: courseId,
            title: 'Mindfulness no Dia a Dia',
            description: 'Como aplicar a atenção plena em atividades cotidianas.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=F6eFFCi12v8',
            duration: 480,
            order: 4,
          ),
        ];
      case 'emocoes':
        return [
          Lesson(
            id: 'emo_lesson_1',
            courseId: courseId,
            title: 'Inteligência Emocional',
            description: 'Como reconhecer e gerenciar suas emoções de forma saudável.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=LgUCyWhJf6s',
            duration: 720,
            order: 1,
          ),
          Lesson(
            id: 'emo_lesson_2',
            courseId: courseId,
            title: 'Lidando com a Raiva',
            description: 'Estratégias práticas para controlar e canalizar a raiva positivamente.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=sbHdF8W3qKY',
            duration: 540,
            order: 2,
          ),
          Lesson(
            id: 'emo_lesson_3',
            courseId: courseId,
            title: 'Superando a Tristeza',
            description: 'Como processar sentimentos de tristeza e melancolia de forma saudável.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=9-xNJbOOXis',
            duration: 600,
            order: 3,
          ),
          Lesson(
            id: 'emo_lesson_4',
            courseId: courseId,
            title: 'Cultivando Alegria',
            description: 'Práticas para aumentar sentimentos positivos e gratidão no dia a dia.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=WPPPFqsECz0',
            duration: 480,
            order: 4,
          ),
        ];
      case 'autoestima':
        return [
          Lesson(
            id: 'auto_lesson_1',
            courseId: courseId,
            title: 'Construindo Autoestima Sólida',
            description: 'Fundamentos para desenvolver uma autoestima saudável e duradoura.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=w-HYZv6HzAs',
            duration: 660,
            order: 1,
          ),
          Lesson(
            id: 'auto_lesson_2',
            courseId: courseId,
            title: 'Eliminando Autocrítica Excessiva',
            description: 'Como identificar e parar padrões de pensamento autodestrutivos.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=KZBTYViDPlQ',
            duration: 540,
            order: 2,
          ),
          Lesson(
            id: 'auto_lesson_3',
            courseId: courseId,
            title: 'Aceitação e Autocompaixão',
            description: 'Aprenda a ser gentil consigo mesmo e aceitar suas imperfeições.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=IvtZBUSplr4',
            duration: 480,
            order: 3,
          ),
        ];
      case 'estresse':
        return [
          Lesson(
            id: 'stress_lesson_1',
            courseId: courseId,
            title: 'Entendendo o Estresse',
            description: 'O que é o estresse, suas causas e como ele afeta nosso corpo e mente.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=hnpQrMqDoqE',
            duration: 600,
            order: 1,
          ),
          Lesson(
            id: 'stress_lesson_2',
            courseId: courseId,
            title: 'Técnicas de Relaxamento',
            description: 'Métodos eficazes para relaxar o corpo e acalmar a mente.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            duration: 720,
            order: 2,
          ),
          Lesson(
            id: 'stress_lesson_3',
            courseId: courseId,
            title: 'Gestão do Tempo e Prioridades',
            description: 'Como organizar sua vida para reduzir o estresse diário.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=tT89OZ7TNwc',
            duration: 540,
            order: 3,
          ),
        ];
      default:
        return [];
    }
  }

  List<CourseExercise> _getExercisesForCourse(String courseId) {
    switch (courseId) {
      case 'respiracao':
        return [
          CourseExercise(
            id: 'resp_ex_1',
            courseId: courseId,
            title: 'Quiz: Fundamentos da Respiração',
            description: 'Teste seus conhecimentos sobre respiração consciente',
            questions: [
              Question(
                id: 'resp_q1',
                text: 'Qual é o principal músculo responsável pela respiração?',
                options: ['Pulmões', 'Diafragma', 'Coração', 'Estômago'],
                correctAnswer: 1,
                explanation: 'O diafragma é o principal músculo respiratório, localizado entre o tórax e o abdômen.',
              ),
              Question(
                id: 'resp_q2',
                text: 'Quantos segundos você deve inspirar na técnica 4-7-8?',
                options: ['4 segundos', '7 segundos', '8 segundos', '10 segundos'],
                correctAnswer: 0,
                explanation: 'Na técnica 4-7-8, você inspira por 4 segundos, segura por 7 e expira por 8.',
              ),
              Question(
                id: 'resp_q3',
                text: 'Qual é o benefício principal da respiração diafragmática?',
                options: ['Acelera o coração', 'Aumenta a ansiedade', 'Melhora a oxigenação', 'Causa tontura'],
                correctAnswer: 2,
                explanation: 'A respiração diafragmática melhora a oxigenação do sangue e ativa o sistema nervoso parassimpático.',
              ),
            ],
          ),
          CourseExercise(
            id: 'resp_ex_2',
            courseId: courseId,
            title: 'Quiz: Técnicas Avançadas',
            description: 'Avalie seu conhecimento sobre técnicas específicas',
            questions: [
              Question(
                id: 'resp_q4',
                text: 'A respiração quadrada (box breathing) consiste em:',
                options: ['Inspirar-pausar-expirar-pausar em tempos iguais', 'Respirar apenas pelo nariz', 'Segurar o ar por 10 segundos', 'Respirar muito rápido'],
                correctAnswer: 0,
                explanation: 'A respiração quadrada envolve quatro fases de duração igual: inspirar, pausar, expirar, pausar.',
              ),
              Question(
                id: 'resp_q5',
                text: 'Qual técnica é mais eficaz para adormecer?',
                options: ['Respiração rápida', 'Técnica 4-7-8', 'Prender a respiração', 'Respirar pela boca'],
                correctAnswer: 1,
                explanation: 'A técnica 4-7-8 ativa o sistema nervoso parassimpático, promovendo relaxamento e sono.',
              ),
            ],
          ),
        ];
      case 'mindfulness':
        return [
          CourseExercise(
            id: 'mind_ex_1',
            courseId: courseId,
            title: 'Quiz: Princípios do Mindfulness',
            description: 'Teste seus conhecimentos sobre atenção plena',
            questions: [
              Question(
                id: 'mind_q1',
                text: 'O que significa mindfulness?',
                options: ['Pensar muito', 'Atenção plena', 'Meditar sempre', 'Controlar pensamentos'],
                correctAnswer: 1,
                explanation: 'Mindfulness significa atenção plena - estar presente no momento atual com consciência.',
              ),
              Question(
                id: 'mind_q2',
                text: 'Qual é o objetivo principal da prática de mindfulness?',
                options: ['Parar de pensar', 'Observar sem julgar', 'Controlar as emoções', 'Evitar problemas'],
                correctAnswer: 1,
                explanation: 'O mindfulness ensina a observar pensamentos e sentimentos sem julgamento, com aceitação.',
              ),
              Question(
                id: 'mind_q3',
                text: 'Quando devemos praticar mindfulness?',
                options: ['Apenas ao meditar', 'Só quando estressados', 'Em qualquer momento', 'Antes de dormir'],
                correctAnswer: 2,
                explanation: 'Mindfulness pode ser praticado a qualquer momento, em atividades cotidianas.',
              ),
            ],
          ),
        ];
      case 'emocoes':
        return [
          CourseExercise(
            id: 'emo_ex_1',
            courseId: courseId,
            title: 'Quiz: Inteligência Emocional',
            description: 'Avalie seu conhecimento sobre gestão emocional',
            questions: [
              Question(
                id: 'emo_q1',
                text: 'O que é inteligência emocional?',
                options: ['Controlar todas as emoções', 'Reconhecer e gerenciar emoções', 'Nunca sentir raiva', 'Ser sempre feliz'],
                correctAnswer: 1,
                explanation: 'Inteligência emocional é a capacidade de reconhecer, compreender e gerenciar nossas emoções.',
              ),
              Question(
                id: 'emo_q2',
                text: 'Qual é a melhor forma de lidar com a raiva?',
                options: ['Reprimir completamente', 'Explodir imediatamente', 'Reconhecer e processar', 'Ignorar o sentimento'],
                correctAnswer: 2,
                explanation: 'É importante reconhecer a raiva, entender sua causa e processá-la de forma saudável.',
              ),
              Question(
                id: 'emo_q3',
                text: 'A tristeza é uma emoção:',
                options: ['Sempre negativa', 'Que deve ser evitada', 'Natural e importante', 'Sinal de fraqueza'],
                correctAnswer: 2,
                explanation: 'A tristeza é uma emoção natural que nos ajuda a processar perdas e mudanças.',
              ),
            ],
          ),
        ];
      case 'autoestima':
        return [
          CourseExercise(
            id: 'auto_ex_1',
            courseId: courseId,
            title: 'Quiz: Autoestima Saudável',
            description: 'Teste seus conhecimentos sobre autoestima',
            questions: [
              Question(
                id: 'auto_q1',
                text: 'Autoestima saudável significa:',
                options: ['Achar-se perfeito', 'Aceitar-se com qualidades e defeitos', 'Nunca se criticar', 'Ser melhor que os outros'],
                correctAnswer: 1,
                explanation: 'Autoestima saudável envolve aceitar-se completamente, reconhecendo tanto qualidades quanto áreas de melhoria.',
              ),
              Question(
                id: 'auto_q2',
                text: 'O que é autocrítica excessiva?',
                options: ['Uma forma de motivação', 'Padrão destrutivo de pensamento', 'Sinal de humildade', 'Busca por perfeição'],
                correctAnswer: 1,
                explanation: 'Autocrítica excessiva é um padrão destrutivo que mina a autoconfiança e bem-estar.',
              ),
            ],
          ),
        ];
      case 'estresse':
        return [
          CourseExercise(
            id: 'stress_ex_1',
            courseId: courseId,
            title: 'Quiz: Gerenciamento do Estresse',
            description: 'Avalie seus conhecimentos sobre estresse',
            questions: [
              Question(
                id: 'stress_q1',
                text: 'O estresse é sempre prejudicial?',
                options: ['Sim, sempre', 'Não, pode ser motivador', 'Apenas em excesso', 'Depende da pessoa'],
                correctAnswer: 2,
                explanation: 'O estresse em pequenas doses pode ser motivador, mas em excesso torna-se prejudicial.',
              ),
              Question(
                id: 'stress_q2',
                text: 'Qual é uma técnica eficaz para reduzir estresse?',
                options: ['Evitar todos os problemas', 'Respiração profunda', 'Trabalhar mais', 'Ignorar os sintomas'],
                correctAnswer: 1,
                explanation: 'A respiração profunda ativa o sistema nervoso parassimpático, reduzindo o estresse.',
              ),
            ],
          ),
        ];
      default:
        return [];
    }
  }
}

// Classes auxiliares para lições e quizzes
class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final LessonType type;
  final String? videoUrl;
  final int duration; // em segundos
  final int order;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.type,
    this.videoUrl,
    required this.duration,
    required this.order,
  });
}

enum LessonType { video, text }

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Course course;
  final VoidCallback onLessonCompleted;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.course,
    required this.onLessonCompleted,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  YoutubePlayerController? _controller;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.lesson.type == LessonType.video && widget.lesson.videoUrl != null) {
      final videoId = YoutubePlayer.convertUrlToId(widget.lesson.videoUrl!);
      if (videoId != null) {
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
        
        _controller!.addListener(() {
          if (_controller!.value.playerState == PlayerState.ended && !_isCompleted) {
            _markAsCompleted();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _markAsCompleted() {
    if (!_isCompleted) {
      setState(() {
        _isCompleted = true;
      });
      widget.onLessonCompleted();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aula concluída! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isCompleted)
            TextButton(
              onPressed: _markAsCompleted,
              child: const Text(
                'Marcar como Concluída',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.lesson.type == LessonType.video && _controller != null)
              YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lesson.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.lesson.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(widget.lesson.duration / 60).ceil()} min',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_isCompleted) ...[
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Concluída',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (!_isCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _markAsCompleted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Marcar como Concluída',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizWidget extends StatefulWidget {
  final CourseExercise exercise;
  final VoidCallback onExerciseCompleted;

  const QuizWidget({
    super.key,
    required this.exercise,
    required this.onExerciseCompleted,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];
  bool _showResults = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List.filled(widget.exercise.questions.length, null);
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.exercise.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _score = 0;
    for (int i = 0; i < widget.exercise.questions.length; i++) {
      if (_selectedAnswers[i] == widget.exercise.questions[i].correctAnswer) {
        _score++;
      }
    }
    
    setState(() {
      _showResults = true;
    });
    
    if (_score >= widget.exercise.questions.length * 0.7) {
      widget.onExerciseCompleted();
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers = List.filled(widget.exercise.questions.length, null);
      _showResults = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsView();
    }

    final question = widget.exercise.questions[_currentQuestionIndex];
    final selectedAnswer = _selectedAnswers[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.exercise.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.exercise.questions.length,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Pergunta ${_currentQuestionIndex + 1} de ${widget.exercise.questions.length}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedAnswer == index;
            
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _selectAnswer(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.gray300,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedAnswer != null ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentQuestionIndex < widget.exercise.questions.length - 1
                    ? 'Próxima Pergunta'
                    : 'Finalizar Quiz',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final passed = _score >= widget.exercise.questions.length * 0.7;
    final percentage = (_score / widget.exercise.questions.length * 100).toInt();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resultado do Quiz',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            size: 80,
            color: passed ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 20),
          Text(
            passed ? 'Parabéns!' : 'Tente Novamente',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: passed ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Você acertou $_score de ${widget.exercise.questions.length} perguntas',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: passed ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 30),
          if (passed) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Exercício concluído com sucesso!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: passed ? () => Navigator.pop(context) : _restartQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: passed ? Colors.green : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                passed ? 'Continuar' : 'Tentar Novamente',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
