import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/checkup_streak_service.dart';
import '../services/achievement_service.dart';
import '../services/course_service.dart';
import '../services/daily_checkup_history_service.dart';
import '../models/mood_data.dart';
import '../models/question_models.dart';
import '../models/conversation_models.dart';
import '../models/course_models.dart';
import '../models/daily_checkup.dart';
import '../utils/app_colors.dart';
import '../widgets/mood_check_widget.dart';
import '../widgets/reflective_questions_widget.dart';
import '../widgets/compatible_users_widget.dart';
import '../widgets/courses_widget.dart';
import '../widgets/user_avatar.dart';
import '../screens/user_chat_screen.dart';
import '../screens/luma_chat_screen.dart';
import '../screens/main_navigation.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;

  const HomeScreen({super.key, this.userRole = 'PATIENT'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  
  // Data
  MoodData? _todayMood;
  List<ReflectiveQuestion> _dailyQuestions = [];
  List<Map<String, dynamic>> _compatibleUsers = [];
  Map<String, bool> _questionAnswers = {};
  String _userName = ''; // Nome do usuário
  List<Course> _courses = []; // Cache local (espelho do CourseService)
  // Removido: _supportMessage - mensagens da Luma agora só aparecem na aba dela
  bool _dailyCheckupCompleted = false;
  bool _editingDailyCheckup = false;
  DateTime? _dailyCheckupDate; // Data do último checkup diário concluído (início do dia)
  
  // Services
  FirebaseService? _firebaseService;
  AuthService? _authService;
  // ignore: unused_field
  CourseService? _courseService;
  bool _userNameLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Aguardar um frame antes de carregar dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firebaseService = Provider.of<FirebaseService>(context);
    _authService = Provider.of<AuthService>(context);
    _courseService = Provider.of<CourseService>(context);

    if (!_userNameLoaded) {
      _userNameLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserName();
      });
    }
  }

  Future<void> _loadUserName() async {
    try {
      final userId = _authService?.currentUser?.uid;
      if (userId == null) return;

      final userProfile = await _firebaseService?.getUserProfile(userId);
      final profileName = userProfile?['name']?.toString().trim() ?? '';
      final profileFullName = userProfile?['fullname']?.toString().trim() ?? '';
      final authName = _authService?.currentUser?.displayName?.trim() ?? '';

      final resolvedName = profileName.isNotEmpty
          ? profileName
          : profileFullName.isNotEmpty
              ? profileFullName
              : authName;

      if (!mounted || resolvedName.isEmpty || resolvedName == _userName) return;

      setState(() {
        _userName = resolvedName;
      });
    } catch (e) {
      print('⚠️ Failed loading user name: $e');
    }
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoading = true; });
    try {
      final userId = _authService?.currentUser?.uid;
      if (userId == null) return;
      // Carregar estado persistido do checkup diário antes de avaliar
      await _loadPersistedDailyCheckup(userId);
      await Future.wait([
        _loadDailyQuestions(),
        _loadCompatibleUsers(userId),
        _loadSampleCourses(),
      ]);
      _evaluateDailyCheckupCompletion();
    } catch (e) {
      print('❌ Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _loadPersistedDailyCheckup(String userId) async {
    try {
      final extra = await _firebaseService?.getUserExtraData(userId);
      if (extra != null) {
        final ts = extra['dailyCheckupDate'];
        if (ts is int) {
          final date = DateTime.fromMillisecondsSinceEpoch(ts);
          final today = DateTime.now();
          final startToday = DateTime(today.year, today.month, today.day);
          if (DateTime(date.year, date.month, date.day) == startToday) {
            _dailyCheckupDate = startToday;
            _dailyCheckupCompleted = true;
            _editingDailyCheckup = false;
            // Restaurar humor salvo, se existir
            final moodMap = extra['dailyCheckupMood'];
            if (moodMap is Map<String, dynamic>) {
              try {
                _todayMood = MoodData.fromMap(moodMap);
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Failed loading persisted daily checkup: $e');
    }
  }

  Future<void> _resetTodayQuestions() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final tomorrow = startOfDay.add(const Duration(days: 1));
      // Estratégia: apagar tudo criado >= startOfDay e < tomorrow.
      // Como só temos método deleteBefore, usamos cutoff = tomorrow e esperamos que histórico anterior fique intacto.
      await _firebaseService?.deleteQuestionsBefore(tomorrow.millisecondsSinceEpoch);
      await _firebaseService?.deleteResponsesBefore(tomorrow.millisecondsSinceEpoch);
      if (mounted) {
        setState(() {
          _dailyQuestions = [];
          _questionAnswers.clear();
        });
      }
      print('🔄 Reset de perguntas de hoje concluído. Será gerado novamente no próximo load.');
      await _loadDailyQuestions();
    } catch (e) {
      print('❌ Falha ao resetar perguntas: $e');
    }
  }

  Future<void> _loadDailyQuestions() async {
    try {
      // Carregar apenas perguntas criadas hoje
  var questions = await _firebaseService?.getTodayQuestions() ?? [];

      const int targetCount = 10;
      if (questions.length < targetCount) {
        final gemini = GeminiService();
        final List<ReflectiveQuestion> newlyCreated = [];
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

        final missing = targetCount - questions.length;
        try {
          final generated = await gemini.generateDailyQuestions(
            count: missing,
            userMood: _todayMood,
          ).timeout(const Duration(seconds: 8));
          print('ℹ️ Gemini returned ${generated.length} generated questions (requested $missing)');

          // Remove duplicates by text compared to existing questions
          final existingTexts = questions.map((q) => q.question.trim()).toSet();
          for (var g in generated) {
            if (existingTexts.contains(g.question.trim())) continue;
            // create deterministic id for new question
            final id = '${now.millisecondsSinceEpoch}_${questions.length + newlyCreated.length}';
            final q = ReflectiveQuestion(
              id: id,
              question: g.question,
              type: g.type,
              category: g.category ?? 'general',
              createdAt: now,
            );
            newlyCreated.add(q);
            questions.add(q);
            if (questions.length >= targetCount) break;
          }
        } catch (e) {
          print('⚠️ Gemini generation timed out or failed: $e');
        }

        // If still missing, supplement with local fallback items (avoiding duplicates)
        if (questions.length < targetCount) {
          final fallback = _localFallbackQuestions();
          final existingTexts = questions.map((q) => q.question.trim()).toSet();
          for (var fb in fallback) {
            if (questions.length >= targetCount) break;
            if (existingTexts.contains(fb.question.trim())) continue;
            final id = '${now.millisecondsSinceEpoch}_${questions.length + newlyCreated.length}';
            final q = ReflectiveQuestion(
              id: id,
              question: fb.question,
              type: fb.type,
              category: fb.category,
              createdAt: now,
            );
            newlyCreated.add(q);
            questions.add(q);
          }
          print('ℹ️ Supplemented with fallback, total questions now: ${questions.length}');
        }

        // If we created any new questions, delete previous-day data and save only the new items
        if (newlyCreated.isNotEmpty) {
          try {
            await _firebaseService?.deleteQuestionsBefore(startOfDay);
            await _firebaseService?.deleteResponsesBefore(startOfDay);
          } catch (e) {
            print('⚠️ Error cleaning previous questions/responses: $e');
          }

          for (var q in newlyCreated) {
            try {
              await _firebaseService?.saveQuestion(q);
            } catch (e) {
              print('⚠️ Error saving generated question: $e');
            }
          }
        }
      }
      
      // Carregar apenas respostas do usuário para hoje
      final userId = _authService?.currentUser?.uid;
      if (userId != null) {
        final responses = await _firebaseService?.getTodayUserResponses(userId) ?? [];
        final answersMap = <String, bool>{};
        for (var response in responses) {
          answersMap[response.questionId] = response.answer;
        }
        // Safety: Guarantee we have exactly targetCount questions in memory
        const int targetCount = 10;
        if (questions.length < targetCount) {
          print('⚠️ After generation/supplement we still have only ${questions.length} questions, filling from local fallback');
          final fallback = _localFallbackQuestions();
          final existingTexts = questions.map((q) => q.question.trim()).toSet();
          final now = DateTime.now();
          while (questions.length < targetCount) {
            final candidate = fallback[questions.length % fallback.length];
            if (existingTexts.contains(candidate.question.trim())) {
              // Try next
              bool found = false;
              for (var fb in fallback) {
                if (!existingTexts.contains(fb.question.trim())) {
                  final id = '${now.millisecondsSinceEpoch}_${questions.length}';
                  questions.add(ReflectiveQuestion(id: id, question: fb.question, type: fb.type, category: fb.category, createdAt: now));
                  existingTexts.add(fb.question.trim());
                  found = true;
                  break;
                }
              }
              if (!found) break; // no unique fallback left
            } else {
              final id = '${now.millisecondsSinceEpoch}_${questions.length}';
              questions.add(ReflectiveQuestion(id: id, question: candidate.question, type: candidate.type, category: candidate.category, createdAt: now));
              existingTexts.add(candidate.question.trim());
            }
          }
          print('✅ After final fill we have ${questions.length} questions');
        }

        // Validação de perguntas SIM/NÃO antes de setState
        final validation = _validateYesNoQuestions(questions);
        if (validation.replacedCount > 0) {
          print('ℹ️ Validação: ${validation.replacedCount} perguntas substituídas por fallback SIM/NÃO');
        }
        setState(() {
          _dailyQuestions = validation.questions;
          _questionAnswers = answersMap;
        });

        print('📱 Loaded ${questions.length} questions and ${responses.length} responses for today');
      }
    } catch (e) {
      print('❌ Error loading daily questions: $e');
    }
  }

  List<ReflectiveQuestion> _localFallbackQuestions() {
    final now = DateTime.now();
    final base = [
      'Você prefere viajar sozinho ou acompanhado?',
      'Você acha importante perdoar alguém que te magoou?',
      'Você costuma seguir sua intuição nas decisões importantes?',
      'Você acredita que pequenos hábitos mudam grandes resultados?',
      'Você gosta mais de planejar ou improvisar?',
      'Você se sente energizado ao passar tempo com outras pessoas?',
      'Você costuma definir metas semanais para si mesmo?',
      'Você acha que ouvir é mais importante que falar?',
      'Você acredita que tecnologia melhora sua qualidade de vida?',
      'Você teria coragem de mudar de carreira agora?'
    ];

    return List.generate(10, (i) => ReflectiveQuestion(
      id: '${now.millisecondsSinceEpoch}_${i}',
      question: base[i],
      type: QuestionType.personal,
      category: 'general',
      createdAt: now,
    ));
  }

  Future<void> _loadCompatibleUsers(String userId) async {
    try {
      print('🔄 Loading compatible users for: $userId');
      
      // DEBUG: List all users in Firestore
      await _firebaseService?.debugListAllUsers();
      
      // Limitando para 6 usuários compatíveis
      final users = await _firebaseService?.getCompatibleUsers(userId, limit: 6) ?? [];
      print('👥 Found ${users.length} compatible users (limited to 6)');
      if (!mounted) return; // prevenir setState após dispose
      setState(() { _compatibleUsers = users; });
    } catch (e) {
      print('❌ Error loading compatible users: $e');
    }
  }

  Future<void> _loadSampleCourses() async {
    try {
      final service = Provider.of<CourseService>(context, listen: false);
      await service.seedAllIfEmpty();
      await service.loadFavorites();
      if (mounted) {
        setState(() { _courses = service.courses; });
      }
    } catch (e) {
      print('❌ Error loading courses (service): $e');
    }
  }

  // Verifica se todas as perguntas do dia foram respondidas
  bool _areAllQuestionsAnswered() {
    if (_dailyQuestions.isEmpty) return false;
    
    for (var question in _dailyQuestions) {
      if (!_questionAnswers.containsKey(question.id)) {
        return false; // Ainda há perguntas não respondidas
      }
    }
    return true; // Todas as perguntas foram respondidas
  }

  void _evaluateDailyCheckupCompletion() {
    final historyService = Provider.of<DailyCheckupHistoryService>(context, listen: false);
    final todayRecord = historyService.getCheckupForDate(DateTime.now());
    final hasMood = _todayMood != null;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (_dailyCheckupDate != null && _dailyCheckupDate == today) {
      // Já marcado via persistência
      _dailyCheckupCompleted = true;
      _editingDailyCheckup = false;
      return;
    }
    if (todayRecord != null && todayRecord.isCompleted) {
      _dailyCheckupDate = today;
      _dailyCheckupCompleted = true;
      _editingDailyCheckup = false;
    } else if (hasMood) {
      // Se já temos humor de hoje mas não está marcado, marcar agora (persistindo)
      _markDailyCheckupCompleted(persist: true);
    } else {
      _dailyCheckupCompleted = false;
    }
  }

  Future<void> _markDailyCheckupCompleted({bool persist = false}) async {
    if (_todayMood == null) return;
    final historyService = Provider.of<DailyCheckupHistoryService>(context, listen: false);
    final streakService = Provider.of<CheckupStreakService>(context, listen: false);
    final mood = _todayMood!;
    final now = DateTime.now();

    final checkup = DailyCheckup(
      date: DateTime(now.year, now.month, now.day),
      moodScore: mood.happiness.toDouble(),
      energyLevel: mood.energy.toDouble(),
      stressLevel: mood.stress.toDouble(),
      sleepQuality: 0, // ainda não coletado
      notes: mood.notes,
      completedAt: now,
      isCompleted: true,
      completionPercentage: 100,
    );
    await historyService.addCheckup(checkup);
    await streakService.updateTodayCheckup(checkup);
    final startOfDay = DateTime(now.year, now.month, now.day);
    if (persist) {
      try {
        final userId = _authService?.currentUser?.uid;
        if (userId != null) {
          await _firebaseService?.updateUserExtraData(userId, {
            'dailyCheckupDate': startOfDay.millisecondsSinceEpoch,
            'dailyCheckupMood': mood.toMap(),
            'dailyCheckupCompleted': true,
          });
        }
      } catch (e) {
        print('⚠️ Failed to persist daily checkup (mark): $e');
      }
    }
    if (!mounted) return;
    setState(() {
        _dailyCheckupDate = startOfDay;
        _dailyCheckupCompleted = true;
        _editingDailyCheckup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userRole == 'PSYCHOLOGIST') {
      return _buildPsychologistHome(context);
    }

    final theme = Theme.of(context);
    // scheme reserved for future use in additional refactors
  final scheme = theme.colorScheme; // ignore: unused_local_variable
    return Container(
      // Use scaffold background instead of fixed gray so dark theme applies
      color: theme.scaffoldBackgroundColor,
      child: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView( // Mudança principal: ScrollView unificado
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Support Message Section - aparece quando bem-estar <= 50%
                  if (_todayMood != null && _todayMood!.wellnessScore <= 50) ...[
                    _buildSupportMessageCard(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Checkup Diário - seção sempre exibida; conteúdo muda conforme estado
                  _buildSectionCard(
                    icon: Icons.checklist,
                    title: 'Checkup Diário',
                    subtitle: 'Como você está se sentindo hoje?',
                    child: Column(
                      children: [
                        if (!_dailyCheckupCompleted || _editingDailyCheckup || _todayMood == null)
                          MoodCheckWidget(
                            initialMood: _todayMood,
                            onMoodSubmitted: _handleMoodSubmission,
                          )
                        else
                          _buildMoodSummaryCard(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Reflective Questions Section - só mostra se não foram todas respondidas
                  if (!_areAllQuestionsAnswered()) ...[
                    _buildSectionCard(
                      icon: Icons.psychology,
                      title: 'Perguntas Reflexivas',
                      subtitle: 'Responda para encontrar pessoas compatíveis',
                      child: ReflectiveQuestionsWidget(
                        questions: _dailyQuestions,
                        existingAnswers: _questionAnswers,
                        onQuestionAnswered: _handleQuestionAnswer,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Completed Questions Message - mostra quando todas foram respondidas
                  if (_areAllQuestionsAnswered() && _dailyQuestions.isNotEmpty) ...[
                    _buildCompletedQuestionsCard(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Compatible Users Section
                  _buildSectionCard(
                    icon: Icons.people,
                    title: 'Pessoas com mais afinidade',
                    subtitle: 'Conecte-se com quem pensa como você',
                    child: CompatibleUsersWidget(
                      compatibleUsers: _compatibleUsers,
                      onUserTapped: _showUserProfile,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Courses Section
                  _buildSectionCard(
                    icon: Icons.school,
                    title: 'Cursos de Bem-Estar Mental',
                    subtitle: 'Aprenda técnicas para melhorar sua saúde mental',
                    child: CoursesWidget(
                      courses: _courses,
                      onViewAll: () {
                        // Muda para a aba de cursos
                        MainNavigation.switchTab(1);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32), // Espaço no final
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Carregando sua experiência personalizada...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildWellnessIndicator() {
    final score = _todayMood!.wellnessScore;
    final color = score >= 70 ? Colors.green : score >= 40 ? Colors.orange : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${score.toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Conteúdo da seção
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedQuestionsCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ícone de sucesso
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 36,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Título
            const Text(
              'Perguntas do dia concluídas! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                // Will be overridden by theme-aware DefaultTextStyle below if needed
                color: null,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Descrição
            Text(
              'Você respondeu todas as perguntas reflexivas de hoje. Novas perguntas estarão disponíveis amanhã!',
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Estatísticas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${_dailyQuestions.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Respondidas',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.gray300,
                  ),
                  Column(
                    children: [
                      Text(
                        '${_compatibleUsers.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Compatíveis',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSummaryCard() {
    final mood = _todayMood!;
    final score = mood.wellnessScore;
    final color = score >= 70 ? Colors.green : score >= 40 ? Colors.orange : Colors.red;
    
    String moodDescription;
    IconData moodIcon;
    
    if (score >= 80) {
      moodDescription = 'Excelente!';
      moodIcon = Icons.sentiment_very_satisfied;
    } else if (score >= 60) {
      moodDescription = 'Bem!';
      moodIcon = Icons.sentiment_satisfied;
    } else if (score >= 40) {
      moodDescription = 'OK';
      moodIcon = Icons.sentiment_neutral;
    } else {
      moodDescription = 'Precisa de cuidado';
      moodIcon = Icons.sentiment_dissatisfied;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Ícone e status principal
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  moodIcon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Você está se sentindo $moodDescription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bem-estar: ${score.toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Resumo dos níveis
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMoodLevelIndicator('😊', 'Felicidade', mood.happiness),
                _buildMoodLevelIndicator('⚡', 'Energia', mood.energy),
                _buildMoodLevelIndicator('🧠', 'Clareza', mood.clarity),
                _buildMoodLevelIndicator('😰', 'Estresse', mood.stress),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botão para alterar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEditMoodDialog(),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text(
                'Alterar estado emocional',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: color.withOpacity(0.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodLevelIndicator(String emoji, String label, int value) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showEditMoodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Alterar Estado Emocional',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Widget de mood
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: MoodCheckWidget(
                  initialMood: _todayMood,
                  onMoodSubmitted: (moodData) {
                    Navigator.pop(context);
                    _handleMoodSubmission(moodData);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportMessageCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.1),
            const Color(0xFF4ECDC4).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone e avatar da Luma
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/cabecaLuma.png'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mensagem da Luma',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.background : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Sua assistente de bem-estar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.favorite,
                  color: Colors.pink.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Mensagem de apoio
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Slightly more transparent in dark theme so gradient below aparece
                color: Theme.of(context).colorScheme.surface.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Text(
                        'Olá! Percebi que você está passando por um momento difícil. 💙',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Text(
                        'Lembre-se de que é completamente normal ter dias mais desafiadores. Você não está sozinho(a) nessa jornada. Estou aqui para conversar, ouvir e ajudar você a encontrar maneiras de se sentir melhor.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                          height: 1.5,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Text(
                        'Que tal conversarmos um pouco? Às vezes, dividir nossos sentimentos pode trazer alívio e clareza. ✨',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                          height: 1.5,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botão para conversar com a Luma
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navegar para o chat com a Luma
                  _navigateToLumaChat();
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                ),
                label: const Text(
                  'Conversar com a Luma',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLumaChat() {
    // Abre o chat da Luma como overlay dedicado (não é mais aba fixa)
    try {
      MainNavigation.openAIChat();
    } catch (e) {
      // Fallback direto se MainNavigation não estiver montado
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LumaChatScreen(),
        ),
      );
    }
  }

  // ignore: unused_element
  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = _userName.isNotEmpty ? ', $_userName' : '';
    
    if (hour < 12) return 'Bom dia$name!';
    if (hour < 18) return 'Boa tarde$name!';
    return 'Boa noite$name!';
  }

  Future<void> _handleMoodSubmission(MoodData moodData) async {
    try {
      final userId = _authService?.currentUser?.uid;
      if (userId == null) return;

      // Atualizar o userId
      final updatedMood = MoodData(
        userId: userId,
        date: moodData.date,
        happiness: moodData.happiness,
        energy: moodData.energy,
        clarity: moodData.clarity,
        stress: moodData.stress,
        notes: moodData.notes,
      );

      await _firebaseService?.saveMoodData(updatedMood);
      
      // Marcar checkup como completo
      final streakService = Provider.of<CheckupStreakService>(context, listen: false);
      await streakService.completeCheckup();
      
      // ✨ CONQUISTAS: Registrar checkup completo
      print('🏆 DEBUG: Iniciando registro de conquistas...');
      final achievementService = Provider.of<AchievementService>(context, listen: false);
      final currentStreak = streakService.currentStreak;
      final currentHour = DateTime.now().hour;
      print('🏆 DEBUG: Chamando onCheckupCompleted com streak: $currentStreak, hour: $currentHour');
      final newAchievements = await achievementService.onCheckupCompleted(currentStreak, currentHour);
      
      // ✨ CONQUISTAS: Verificar humor feliz (felicidade >= 4)
      if (updatedMood.happiness >= 4) {
        print('🏆 DEBUG: Humor feliz detectado (${updatedMood.happiness}), chamando onHappyMood');
        final moodAchievements = await achievementService.onHappyMood();
        newAchievements.addAll(moodAchievements);
      }
      
      // ✨ CONQUISTAS: Verificar variedade de humor (diferentes níveis)
      final moodVarietyAchievements = await achievementService.onDifferentMood();
      newAchievements.addAll(moodVarietyAchievements);
      
      // Mostrar conquistas desbloqueadas
      print('🏆 DEBUG: Total de conquistas desbloqueadas: ${newAchievements.length}');
      if (newAchievements.isNotEmpty) {
        for (final achievement in newAchievements) {
          print('🏆 DEBUG: Mostrando conquista: ${achievement.title}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🏆 ${achievement.title} desbloqueada! ${achievement.icon}'),
              backgroundColor: Colors.amber,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('🏆 DEBUG: Nenhuma conquista desbloqueada');
      }
      
      setState(() {
        _todayMood = updatedMood;
      });
      // Marcar imediatamente como completo (independente das perguntas reflexivas)
      await _markDailyCheckupCompleted(persist: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado emocional registrado! 💖'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleQuestionAnswer(QuestionResponse response) async {
    try {
      final userId = _authService?.currentUser?.uid;
      if (userId == null) return;

      // Atualizar o userId
      final updatedResponse = QuestionResponse(
        userId: userId,
        questionId: response.questionId,
        answer: response.answer,
        answeredAt: response.answeredAt,
      );

      await _firebaseService?.saveQuestionResponse(updatedResponse);
      
      setState(() {
        _questionAnswers[response.questionId] = response.answer;
      });

      // ✨ CONQUISTAS: Registrar nova seção visitada (responder pergunta)
      final achievementService = Provider.of<AchievementService>(context, listen: false);
      final newAchievements = await achievementService.onSectionVisited();
      
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

      // Recarregar usuários compatíveis
      _loadCompatibleUsers(userId);

      // Verificar se todas as perguntas foram respondidas
      if (_areAllQuestionsAnswered()) {
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Parabéns! Você completou todas as perguntas do dia!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      _evaluateDailyCheckupCompletion();
    } catch (e) {
      print('❌ Error saving question response: $e');
    }
  }

  void _showUserProfile(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUserProfileModal(user),
    );
  }

  Widget _buildUserProfileModal(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compatibility = user['compatibility'] as double;
    final name = user['name'] ?? 'Usuário';
    final age = user['age'] as int?;
    final city = user['city'] as String?;
    final bio = user['bio'] as String?;
    final profileImage = user['profileImageUrl'] as String?;
    final profileImageBase64 = user['profileImageBase64'] as String?;
    final goal = user['goal'] as String?;
    
    // Parse tags
    final tags = <String>[];
    final tagsString = user['tags_string'] as String?;
    if (tagsString != null && tagsString.isNotEmpty) {
      tags.addAll(tagsString.split(','));
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile image and compatibility
                  Stack(
                    children: [
                      UserAvatar(
                        imageUrl: profileImage,
                        imageBytes: profileImageBase64 != null && profileImageBase64.isNotEmpty
                            ? base64Decode(profileImageBase64)
                            : null,
                        radius: 60,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            '${compatibility.toInt()}% compatível',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Name and age
                  Builder(builder: (context){
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    );
                  }),
                  
                  if (age != null) ...[
                    const SizedBox(height: 4),
                    Builder(builder: (context){
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Text(
                        '$age anos',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      );
                    }),
                  ],
                  
                  // City
                  if (city != null && city.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(builder: (context){
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          );
                        }),
                        const SizedBox(width: 4),
                        Builder(builder: (context){
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Text(
                            city,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Bio
                  if (bio != null && bio.isNotEmpty) ...[
                    Builder(builder: (context){
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sobre',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bio,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark ? Colors.white70 : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  
                  // Goal
                  if (goal != null && goal.isNotEmpty) ...[
                    Builder(builder: (context){
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Objetivo no app',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              goal,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark ? Colors.white70 : AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  
                  // Tags
                  if (tags.isNotEmpty) ...[
                    Builder(builder: (context){
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interesses',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? AppColors.primary.withOpacity(0.4) : AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white : AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        
                        // Criar ChatUser do usuário compatível
                        final chatUser = ChatUser(
                          id: user['id'] ?? '',
                          name: name,
                          profileImageUrl: profileImage,
                          profileImageBase64: user['profileImageBase64'] as String?,
                          isOnline: false,
                        );
                        
                        // Navegar para o chat
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserChatScreen(otherUser: chatUser),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat, size: 20),
                      label: const Text(
                        'Conversar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  // ignore: unused_element
  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Meu Perfil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar para perfil
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar para configurações
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _authService?.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                } catch (e) {
                  print('Erro no logout: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao sair. Tente novamente.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  _ValidationResult _validateYesNoQuestions(List<ReflectiveQuestion> input) {
    final now = DateTime.now();
    final fallbackPool = _localFallbackQuestions();
    int fallbackIndex = 0;
    int replaced = 0;

    bool isYesNo(String q) {
      final qt = q.trim();
      if (qt.length < 5) return false;
      if (!qt.endsWith('?')) return false;
      final lower = qt.toLowerCase();
      const disallowedStarts = [
        'por que', 'porque', 'como', 'quando', 'onde', 'qual', 'quais', 'o que', 'oque', 'que ', 'descreva', 'explique', 'liste', 'fale sobre', 'conte sobre'
      ];
      for (final w in disallowedStarts) {
        if (lower.startsWith(w)) return false;
      }
      const preferredStarts = [
        'você', 'se ', 'é ', 'está', 'tem ', 'pode', 'poderia', 'deveria', 'iria', 'aceita', 'acredita', 'prefere', 'gostaria', 'quer', 'já ', 'costuma', 'usaria', 'mudaria'
      ];
      bool startsOk = preferredStarts.any((p) => lower.startsWith(p));
      if (!startsOk && lower.contains(' ou ')) startsOk = true;
      return startsOk;
    }

    final validated = <ReflectiveQuestion>[];
    for (final q in input) {
      if (isYesNo(q.question)) {
        validated.add(q);
      } else {
        replaced++;
        print('⚠️ Removendo pergunta não SIM/NÃO: "${q.question}"');
      }
    }

    final existing = validated.map((e) => e.question.trim().toLowerCase()).toSet();
    while (validated.length < 10 && fallbackIndex < fallbackPool.length) {
      final fb = fallbackPool[fallbackIndex++];
      if (!isYesNo(fb.question)) continue;
      if (existing.contains(fb.question.trim().toLowerCase())) continue;
      validated.add(ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_${validated.length}',
        question: fb.question,
        type: fb.type,
        category: fb.category,
        createdAt: now,
      ));
    }
    return _ValidationResult(validated, replaced);
  }

  Widget _buildPsychologistHome(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = _userName.isNotEmpty ? _userName : 'Dr. Gustavo';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            icon: Icons.medical_services_outlined,
            title: 'Bem vindo, $displayName!',
            subtitle: 'Sua agenda, seus pacientes e a Luma em um só lugar.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Você ainda não possui nenhuma consulta hoje!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'O próximo passo é organizar os horários, revisar os pacientes marcados ou falar com a Luma.',
                        style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Quero Organizar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            icon: Icons.people,
            title: 'Pacientes com consulta hoje',
            subtitle: 'Acompanhe quem está agendado para agora.',
            child: Column(
              children: [
                _psychPatientCard('Carlos Augusto', 'Online • 20:00 • Até a consulta doutor!'),
                const SizedBox(height: 12),
                _psychPatientCard('Maria Fernanda', 'Online • 21:00 • Até logo!'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            icon: Icons.chat_bubble_outline,
            title: 'Atalhos',
            subtitle: 'Acesse rápido as áreas mais usadas.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _PsychShortcut(label: 'Chatbot', icon: Icons.smart_toy_outlined),
                _PsychShortcut(label: 'Chats', icon: Icons.chat_bubble_outline),
                _PsychShortcut(label: 'Agenda', icon: Icons.calendar_month_outlined),
                _PsychShortcut(label: 'Perfil', icon: Icons.person_outline),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildPsychologistCoursesSection(context),
        ],
      ),
    );
  }

  Widget _buildPsychologistCoursesSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewCourses = _courses.take(2).toList();

    return _buildSectionCard(
      icon: Icons.school_outlined,
      title: 'Cursos de Psicoeducação',
      subtitle: 'Recomende um curso para seus pacientes e acompanhe o uso.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (previewCourses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : AppColors.gray50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Nenhum curso carregado ainda. Assim que o catálogo estiver pronto, você poderá recomendar conteúdos aos pacientes.',
                style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previewCourses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final course = previewCourses[index];
                  return Container(
                    width: 190,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.school_outlined, color: Colors.white, size: 36),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Recomendado',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Icon(Icons.favorite_border, color: Colors.white.withOpacity(0.9), size: 18),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Text(
                            course.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                          child: Text(
                            course.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showRecommendCourseSheet(course),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text('Recomendar'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _courses.isEmpty ? null : () => _showRecommendCourseSheet(_courses.first),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ver cursos e recomendar'),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecommendCourseSheet(Course course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patients = [
      {'id': 'carlos_augusto', 'name': 'Carlos Augusto', 'selected': false},
      {'id': 'maria_fernanda', 'name': 'Maria Fernanda', 'selected': false},
      {'id': 'victor_mathias', 'name': 'Victor Mathias', 'selected': true},
      {'id': 'eduarda_bizarra', 'name': 'Eduarda Bizarra', 'selected': false},
      {'id': 'arthur_medeiros', 'name': 'Arthur Medeiros', 'selected': true},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : AppColors.gray300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Recomende o curso: ${course.title}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Selecione os pacientes que devem receber esse conteúdo.',
                        style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: patients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final patient = patients[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? Colors.white12 : AppColors.gray300),
                            ),
                            child: CheckboxListTile(
                              value: patient['selected'] as bool,
                              onChanged: (value) {
                                setSheetState(() {
                                  patient['selected'] = value ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                              controlAffinity: ListTileControlAffinity.trailing,
                              secondary: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                                child: Text((patient['name'] as String)[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              title: Text(
                                patient['name'] as String,
                                style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final selectedPatients = patients
                                .where((patient) => patient['selected'] == true)
                                .map((patient) => {
                                      'id': patient['id'] as String,
                                      'name': patient['name'] as String,
                                    })
                                .toList();

                            try {
                              final userId = _authService?.currentUser?.uid;
                              if (userId != null) {
                                await _firebaseService?.updateUserExtraData(userId, {
                                  'lastRecommendedCourse': {
                                    'courseId': course.id,
                                    'courseTitle': course.title,
                                    'courseDescription': course.description,
                                    'selectedPatients': selectedPatients,
                                    'updatedAt': DateTime.now().millisecondsSinceEpoch,
                                  },
                                  'recommendedCourses': [
                                    {
                                      'courseId': course.id,
                                      'courseTitle': course.title,
                                      'selectedPatients': selectedPatients,
                                      'updatedAt': DateTime.now().millisecondsSinceEpoch,
                                    }
                                  ],
                                });
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Curso "${course.title}" recomendado e salvo no seu perfil.')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Não foi possível salvar a recomendação: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Recomendar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _psychPatientCard(String name, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.14),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _PsychShortcut extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PsychShortcut({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _ValidationResult {
  final List<ReflectiveQuestion> questions;
  final int replacedCount;
  _ValidationResult(this.questions, this.replacedCount);
}
