import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_models.dart';
import '../services/course_service.dart';
import '../services/course_progress_service.dart';
import '../utils/app_colors.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  bool _initialLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final courseService =
          Provider.of<CourseService>(context, listen: false);
      await courseService.loadCourses();
      await courseService.loadFavorites();
      // opcional: carregar progresso já ocorre via CourseProgressService separado
    } catch (e) {
      _error = 'Erro ao carregar cursos';
    } finally {
      if (mounted) {
        setState(() => _initialLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courseService = Provider.of<CourseService>(context);
    final progressService = Provider.of<CourseProgressService>(context);

    final allCourses = courseService.courses;
    final favoriteCourses = courseService.favoriteCourses;
    final completedCourses = allCourses
        .where((c) => progressService.isCourseCompletedById(c.id))
        .toList();

    if (_initialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.red,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initialLoading = true;
                  });
                  _loadInitial();
                },
                child: const Text('Tentar novamente'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // Mantemos sem AppBar para reutilizar o header/navbar existente na tela principal
      body: Column(
        children: [
          // Tabs inline no corpo para não gerar um novo header
          Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
              tabs: const [
                Tab(text: 'Em Destaque'),
                Tab(text: 'Favoritos'),
                Tab(text: 'Concluídos'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await courseService.loadCourses();
                await courseService.loadFavorites();
              },
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCourseList(context, allCourses, courseService, progressService, emptyMessage: 'Nenhum curso disponível.'),
                  _buildCourseList(context, favoriteCourses, courseService, progressService, emptyMessage: 'Você ainda não favoritou cursos.'),
                  _buildCourseList(context, completedCourses, courseService, progressService, emptyMessage: 'Você ainda não concluiu cursos.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList(
    BuildContext context,
    List<Course> courses,
    CourseService courseService,
    CourseProgressService progressService, {
    String emptyMessage = 'Nada aqui',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (courses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Icon(Icons.school_outlined,
              size: 48, color: isDark ? Colors.white54 : Colors.black26),
          const SizedBox(height: 12),
          Center(
            child: Text(
              emptyMessage,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500),
            ),
          )
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final c = courses[index];
        final completed = progressService.isCourseCompletedById(c.id);
        final progress = progressService.getCourseCompletionPercentage(c.id);
        final isFav = courseService.isFavorite(c.id);
        return _CourseRow(
          course: c,
          isCompleted: completed,
          progress: progress,
          isFavorite: isFav,
          onToggleFavorite: () => courseService.toggleFavorite(c.id),
        );
      },
    );
  }
}

class _CourseRow extends StatelessWidget {
  final Course course;
  final bool isCompleted;
  final double progress; // 0..100
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _CourseRow({
    Key? key,
    required this.course,
    required this.isCompleted,
    required this.progress,
    required this.isFavorite,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(course: course),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(category: course.category, isCompleted: isCompleted),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: onToggleFavorite,
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: isFavorite
                                ? Colors.pinkAccent
                                : (isDark
                                    ? Colors.white54
                                    : Colors.black38),
                          ),
                          tooltip: isFavorite
                              ? 'Remover dos favoritos'
                              : 'Adicionar aos favoritos',
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Tag('${course.duration} min'),
                        _Tag('${course.lessonsCount} aulas'),
                        _Tag('${course.exercisesCount} exercícios'),
                        _Tag(course.level.displayName),
                        if (course.isPopular) _Tag('Popular', color: Colors.orange),
                        if (course.isFree) _Tag('Gratuito', color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (isCompleted)
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 6),
                          Text('Concluído',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    else if (progress > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: isDark ? Colors.white10 : Colors.black12,
                              valueColor: const AlwaysStoppedAnimation(Colors.orangeAccent),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${progress.toStringAsFixed(0)}% concluído',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.orangeAccent
                                    : Colors.deepOrange),
                          )
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_outline,
                                size: 18,
                                color: isDark ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Comece agora',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String category;
  final bool isCompleted;
  const _Thumbnail({Key? key, required this.category, required this.isCompleted})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(category);
    return Stack(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _iconFor(category),
            color: Colors.white,
            size: 34,
          ),
        ),
        if (isCompleted)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
          )
      ],
    );
  }

  static LinearGradient _gradientFor(String category) {
    switch (category.toLowerCase()) {
      case 'ansiedade':
        return const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]);
      case 'depressão':
        return const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)]);
      case 'autoestima':
        return const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF97316)]);
      case 'relacionamentos':
        return const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]);
      case 'estresse':
        return const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]);
      default:
        return const LinearGradient(colors: [Color(0xFF6B7280), Color(0xFF374151)]);
    }
  }

  static IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'ansiedade':
        return Icons.psychology_outlined;
      case 'depressão':
        return Icons.sentiment_satisfied_alt;
      case 'autoestima':
        return Icons.favorite_outline;
      case 'relacionamentos':
        return Icons.people_outline;
      case 'estresse':
        return Icons.self_improvement;
      default:
        return Icons.school_outlined;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  const _Tag(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.15) ??
            (isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color ?? (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}

// (Legacy MenuCategorias widget removido em favor de TabBar)
