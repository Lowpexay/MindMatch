import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/course_models.dart';
import '../utils/app_colors.dart';
import '../services/course_service.dart';
import '../widgets/exercise_quiz_widget.dart';

// Modelos para exercícios
class CourseExercise {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<Question> questions;

  CourseExercise({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.questions,
  });
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({
    Key? key,
    required this.course,
  }) : super(key: key);

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
    try {
      // Carregar dados reais do curso
      final lessons = _getLessonsForCourse(widget.course.id);
      final exercises = _getExercisesForCourse(widget.course.id);
      
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do curso
                  _buildCourseHeader(),
                  
                  // Tabs de navegação
                  _buildTabSelector(),
                  
                  // Conteúdo baseado na tab selecionada
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
              borderRadius: BorderRadius.circular(16),
              gradient: _getCourseGradient(widget.course.category),
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

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Aulas', 0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Exercícios', 1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Sobre', 2),
          ),
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
              return _buildLessonCard(lesson, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson, int order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
                            color: AppColors.textSecondary,
                          ),
                        ),
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
              return _buildExerciseCard(exercise, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(CourseExercise exercise, int order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: _buildQuizContent(exercise),
        ),
      ),
    );
  }

  Widget _buildQuizContent(CourseExercise exercise) {
    return StatefulBuilder(
      builder: (context, setState) {
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
                      exercise.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                exercise.description,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: exercise.questions.length,
                  itemBuilder: (context, index) {
                    final question = exercise.questions[index];
                    return _buildQuestionCard(question, index + 1);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exercício concluído! 🎉'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Finalizar Exercício',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(Question question, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pergunta $number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isCorrect = index == question.correctAnswer;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect ? Colors.green : AppColors.gray300,
                  width: isCorrect ? 2 : 1,
                ),
              ),
              child: ListTile(
                dense: true,
                title: Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    color: isCorrect ? Colors.green : AppColors.textPrimary,
                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isCorrect 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              ),
            );
          }).toList(),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
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
            description: 'Aprenda os fundamentos da respiração consciente e seus benefícios para a saúde mental.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=DbDoBzGY3vo',
            duration: 480, // 8 minutos
            order: 1,
          ),
          Lesson(
            id: 'resp_lesson_2',
            courseId: courseId,
            title: 'Técnica 4-7-8 para Relaxamento',
            description: 'Domine a técnica 4-7-8 para reduzir ansiedade e promover relaxamento profundo.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=YRPh_GaiL8s',
            duration: 360, // 6 minutos
            order: 2,
          ),
          Lesson(
            id: 'resp_lesson_3',
            courseId: courseId,
            title: 'Respiração Diafragmática',
            description: 'Aprenda a respirar corretamente usando o diafragma para maximizar a oxigenação.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=Jyy6YtVb928',
            duration: 420, // 7 minutos
            order: 3,
          ),
          Lesson(
            id: 'resp_lesson_4',
            courseId: courseId,
            title: 'Respiração Quadrada (Box Breathing)',
            description: 'Técnica usada por militares e atletas para manter o foco e controlar o estresse.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=tEmt1Znux58',
            duration: 300, // 5 minutos
            order: 4,
          ),
          Lesson(
            id: 'resp_lesson_5',
            courseId: courseId,
            title: 'Prática Guiada - 10 Minutos',
            description: 'Sessão prática guiada combinando todas as técnicas aprendidas.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=g_tea8ZNk5A',
            duration: 600, // 10 minutos
            order: 5,
          ),
        ];

      case 'mindfulness':
        return [
          Lesson(
            id: 'mind_lesson_1',
            courseId: courseId,
            title: 'O que é Mindfulness?',
            description: 'Entenda os princípios básicos da atenção plena e como ela pode transformar sua vida.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=HmEo6RI4Wvs',
            duration: 540, // 9 minutos
            order: 1,
          ),
          Lesson(
            id: 'mind_lesson_2',
            courseId: courseId,
            title: 'Meditação da Respiração',
            description: 'Prática fundamental de mindfulness focada na observação da respiração.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=aNjTH8SzXdc',
            duration: 600, // 10 minutos
            order: 2,
          ),
          Lesson(
            id: 'mind_lesson_3',
            courseId: courseId,
            title: 'Escaneamento Corporal',
            description: 'Técnica para desenvolver consciência corporal e liberar tensões.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=15q-N-_kkrU',
            duration: 900, // 15 minutos
            order: 3,
          ),
          Lesson(
            id: 'mind_lesson_4',
            courseId: courseId,
            title: 'Mindfulness no Dia a Dia',
            description: 'Como integrar a atenção plena em atividades cotidianas.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=6p_yaNFSYao',
            duration: 480, // 8 minutos
            order: 4,
          ),
          Lesson(
            id: 'mind_lesson_5',
            courseId: courseId,
            title: 'Meditação Caminhando',
            description: 'Prática de mindfulness em movimento para conectar corpo e mente.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=Lcw6zNg6mis',
            duration: 720, // 12 minutos
            order: 5,
          ),
        ];

      case 'emocoes':
        return [
          Lesson(
            id: 'emo_lesson_1',
            courseId: courseId,
            title: 'Compreendendo as Emoções',
            description: 'Aprenda sobre a natureza das emoções e como elas influenciam nosso comportamento.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=gAMbkJk6gnE',
            duration: 660, // 11 minutos
            order: 1,
          ),
          Lesson(
            id: 'emo_lesson_2',
            courseId: courseId,
            title: 'Inteligência Emocional',
            description: 'Desenvolva sua capacidade de reconhecer e gerenciar emoções.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=Y7m9eNoB3NU',
            duration: 780, // 13 minutos
            order: 2,
          ),
          Lesson(
            id: 'emo_lesson_3',
            courseId: courseId,
            title: 'Técnicas de Regulação Emocional',
            description: 'Estratégias práticas para lidar com emoções intensas de forma saudável.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=BhXvkYeOhbE',
            duration: 540, // 9 minutos
            order: 3,
          ),
          Lesson(
            id: 'emo_lesson_4',
            courseId: courseId,
            title: 'Mindfulness das Emoções',
            description: 'Como observar emoções sem julgamento e com aceitação.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=nTqOOBkJVKw',
            duration: 600, // 10 minutos
            order: 4,
          ),
          Lesson(
            id: 'emo_lesson_5',
            courseId: courseId,
            title: 'Cultivando Emoções Positivas',
            description: 'Práticas para desenvolver gratidão, compassão e alegria genuína.',
            type: LessonType.video,
            videoUrl: 'https://www.youtube.com/watch?v=x7vfEY1OTcs',
            duration: 720, // 12 minutos
            order: 5,
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
                text: 'Qual o principal benefício da respiração diafragmática?',
                options: ['Aumenta frequência cardíaca', 'Maximiza oxigenação', 'Reduz capacidade pulmonar', 'Acelera metabolismo'],
                correctAnswer: 1,
                explanation: 'A respiração diafragmática permite maior expansão dos pulmões, maximizando a oxigenação do sangue.',
              ),
            ],
          ),
          CourseExercise(
            id: 'resp_ex_2',
            courseId: courseId,
            title: 'Prática: Respiração 4-7-8',
            description: 'Exercício prático da técnica de respiração 4-7-8',
            questions: [
              Question(
                id: 'resp_q4',
                text: 'Qual é a sequência correta da respiração 4-7-8?',
                options: ['Inspirar 4, segurar 7, expirar 8', 'Inspirar 7, segurar 4, expirar 8', 'Inspirar 8, segurar 7, expirar 4', 'Inspirar 4, segurar 8, expirar 7'],
                correctAnswer: 0,
                explanation: 'A técnica 4-7-8 consiste em inspirar por 4 segundos, segurar por 7 e expirar por 8 segundos.',
              ),
              Question(
                id: 'resp_q5',
                text: 'Quantos ciclos são recomendados para iniciantes?',
                options: ['10-15 ciclos', '4-6 ciclos', '1-2 ciclos', '20+ ciclos'],
                correctAnswer: 1,
                explanation: 'Para iniciantes, é recomendado começar com 4-6 ciclos para evitar tontura.',
              ),
            ],
          ),
          CourseExercise(
            id: 'resp_ex_3',
            courseId: courseId,
            title: 'Avaliação: Técnicas Avançadas',
            description: 'Teste seu domínio das técnicas avançadas de respiração',
            questions: [
              Question(
                id: 'resp_q6',
                text: 'A respiração quadrada (Box Breathing) usa qual padrão?',
                options: ['4-4-4-4', '4-7-8-0', '6-2-6-2', '5-5-5-5'],
                correctAnswer: 0,
                explanation: 'A respiração quadrada usa o padrão 4-4-4-4: inspirar 4, segurar 4, expirar 4, pausar 4.',
              ),
              Question(
                id: 'resp_q7',
                text: 'Qual técnica é mais eficaz para reduzir ansiedade rapidamente?',
                options: ['Respiração diafragmática', 'Técnica 4-7-8', 'Respiração quadrada', 'Respiração natural'],
                correctAnswer: 1,
                explanation: 'A técnica 4-7-8 é especialmente eficaz para reduzir ansiedade rapidamente devido ao padrão específico.',
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
                text: 'Qual é a atitude correta durante a prática de mindfulness?',
                options: ['Julgar pensamentos', 'Observar sem julgar', 'Parar de pensar', 'Forçar concentração'],
                correctAnswer: 1,
                explanation: 'A atitude fundamental é observar pensamentos e sensações sem julgamento.',
              ),
            ],
          ),
          CourseExercise(
            id: 'mind_ex_2',
            courseId: courseId,
            title: 'Prática: Meditação da Respiração',
            description: 'Exercício prático de meditação focada na respiração',
            questions: [
              Question(
                id: 'mind_q3',
                text: 'Durante a meditação da respiração, se a mente dispersar, você deve:',
                options: ['Se frustrar', 'Parar a prática', 'Gentilmente retornar à respiração', 'Forçar concentração'],
                correctAnswer: 2,
                explanation: 'É natural a mente dispersar. Gentilmente retorne a atenção à respiração sem autocrítica.',
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
            description: 'Avalie seu conhecimento sobre inteligência emocional',
            questions: [
              Question(
                id: 'emo_q1',
                text: 'Qual é o primeiro passo para desenvolver inteligência emocional?',
                options: ['Controlar emoções', 'Reconhecer emoções', 'Ignorar sentimentos', 'Expressar tudo'],
                correctAnswer: 1,
                explanation: 'O primeiro passo é desenvolver a capacidade de reconhecer e identificar suas próprias emoções.',
              ),
              Question(
                id: 'emo_q2',
                text: 'Como devemos lidar com emoções intensas?',
                options: ['Suprimi-las', 'Explodi-las', 'Observá-las com mindfulness', 'Negá-las'],
                correctAnswer: 2,
                explanation: 'A abordagem mindful permite observar emoções intensas sem ser dominado por elas.',
              ),
            ],
          ),
        ];

      default:
        return [];
    }
  }
}

// Classe LessonScreen para visualizar vídeos
class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Course course;

  const LessonScreen({
    Key? key,
    required this.lesson,
    required this.course,
  }) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    if (widget.lesson.type == LessonType.video && widget.lesson.videoUrl.isNotEmpty) {
      final videoId = _getYouTubeVideoId(widget.lesson.videoUrl);
      if (videoId.isNotEmpty) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: true,
            captionLanguage: 'pt',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  String _getYouTubeVideoId(String url) {
    final regex = RegExp(r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})');
    final match = regex.firstMatch(url);
    return match?.group(1) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Player de vídeo
          if (widget.lesson.type == LessonType.video && 
              widget.lesson.videoUrl.isNotEmpty && 
              _youtubeController != null)
            YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppColors.primary,
              progressColors: const ProgressBarColors(
                playedColor: AppColors.primary,
                handleColor: AppColors.primary,
              ),
            )
          else if (widget.lesson.type == LessonType.video)
            Container(
              width: double.infinity,
              height: 220,
              color: Colors.grey[300],
              child: const Center(
                child: Text('Vídeo não disponível'),
              ),
            ),
          
          // Conteúdo da lição
          Expanded(
            child: SingleChildScrollView(
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
                  
                  // Informações da lição
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              widget.lesson.type == LessonType.video
                                  ? Icons.play_circle_outline
                                  : Icons.quiz_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.lesson.type == LessonType.video
                                  ? 'Vídeo da lição'
                                  : 'Exercício interativo',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Duração: ${(widget.lesson.duration / 60).ceil()} minutos',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botão de conclusão
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Marcar como concluído e voltar
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lição concluída! 🎉'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
