import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/checkup_streak_service.dart';
import '../models/mood_data.dart';
import '../models/question_models.dart';
import '../models/conversation_models.dart';
import '../utils/app_colors.dart';
import '../widgets/mood_check_widget.dart';
import '../widgets/reflective_questions_widget.dart';
import '../widgets/compatible_users_widget.dart';
import '../screens/user_chat_screen.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/main_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  // Removido: _supportMessage - mensagens da Luma agora só aparecem na aba dela
  
  // Services
  FirebaseService? _firebaseService;
  AuthService? _authService;

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
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService?.currentUser?.uid;
      if (userId == null) return;

      // Carregar dados em paralelo
      await Future.wait([
        _loadUserName(userId),
        _loadTodayMood(userId),
        _loadDailyQuestions(),
        _loadCompatibleUsers(userId),
      ]);

    } catch (e) {
      print('❌ Error loading initial data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserName(String userId) async {
    try {
      final userProfile = await _firebaseService?.getUserProfile(userId);
      setState(() {
        _userName = userProfile?['name'] ?? _authService?.currentUser?.displayName ?? 'Usuário';
      });
      print('👤 Nome do usuário carregado: $_userName');
    } catch (e) {
      print('❌ Error loading user name: $e');
      setState(() {
        _userName = _authService?.currentUser?.displayName ?? 'Usuário';
      });
    }
  }

  Future<void> _loadTodayMood(String userId) async {
    try {
      final mood = await _firebaseService?.getTodayMood(userId);
      setState(() {
        _todayMood = mood;
      });

      // Removido: geração automática de mensagem de apoio emocional
      // As mensagens da Luma agora só aparecem quando o usuário vai para a aba dela
    } catch (e) {
      print('❌ Error loading mood: $e');
    }
  }

  Future<void> _loadDailyQuestions() async {
    try {
      // Carregar apenas perguntas criadas hoje
  var questions = await _firebaseService?.getTodayQuestions() ?? [];
      // Ensure we have exactly 10 questions for today. If Firestore has fewer,
      // request only the missing count from Gemini and supplement with local fallback.
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

        setState(() {
          _dailyQuestions = questions;
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
      
      setState(() {
        _compatibleUsers = users;
      });
    } catch (e) {
      print('❌ Error loading compatible users: $e');
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray50,
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
                  
                  // Mood Check Section
                  _buildSectionCard(
                    icon: Icons.mood,
                    title: 'Como você está se sentindo hoje?',
                    subtitle: _todayMood != null 
                        ? 'Estado registrado - clique para alterar'
                        : 'Registre seu estado emocional',
                    child: Column(
                      children: [
                        // Se ainda não registrou o humor, mostra o widget completo
                        if (_todayMood == null) 
                          MoodCheckWidget(
                            initialMood: _todayMood,
                            onMoodSubmitted: _handleMoodSubmission,
                          )
                        // Se já registrou, mostra apenas um resumo com botão para alterar
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
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
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Descrição
            Text(
              'Você respondeu todas as perguntas reflexivas de hoje. Novas perguntas estarão disponíveis amanhã!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
                          color: AppColors.textSecondary,
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
              color: Colors.white.withOpacity(0.7),
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
                backgroundColor: Colors.white,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      image: AssetImage('assets/images/luma_chat_avatar.png'),
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
                      const Text(
                        'Mensagem da Luma',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olá! Percebi que você está passando por um momento difícil. 💙',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lembre-se de que é completamente normal ter dias mais desafiadores. Você não está sozinho(a) nessa jornada. Estou aqui para conversar, ouvir e ajudar você a encontrar maneiras de se sentir melhor.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Que tal conversarmos um pouco? Às vezes, dividir nossos sentimentos pode trazer alívio e clareza. ✨',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
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
    // Usar a navegação estática da MainNavigation para ir para a aba do AI Chat
    // Importar MainNavigation se necessário
    try {
      // Navegar para a aba 2 (AI Chat) da MainNavigation
      // Como estamos usando IndexedStack na MainNavigation, podemos usar o método estático
      MainNavigation.navigateToAIChat();
    } catch (e) {
      print('❌ Erro ao navegar para o chat da Luma: $e');
      // Fallback: tentar navegar diretamente
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiChatScreen(userMood: _todayMood),
        ),
      );
    }
  }

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
      
      setState(() {
        _todayMood = updatedMood;
      });

      // Removido: geração automática de apoio emocional
      // As mensagens da Luma agora só aparecem quando o usuário vai para a aba dela

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
    final compatibility = user['compatibility'] as double;
    final name = user['name'] ?? 'Usuário';
    final age = user['age'] as int?;
    final city = user['city'] as String?;
    final bio = user['bio'] as String?;
    final profileImage = user['profileImageUrl'] as String?;
    final goal = user['goal'] as String?;
    
    // Parse tags
    final tags = <String>[];
    final tagsString = user['tags_string'] as String?;
    if (tagsString != null && tagsString.isNotEmpty) {
      tags.addAll(tagsString.split(','));
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.gray200,
                        backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                        child: profileImage == null
                            ? const Icon(Icons.person, size: 60, color: AppColors.gray500)
                            : null,
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
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  if (age != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$age anos',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  
                  // City
                  if (city != null && city.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Bio
                  if (bio != null && bio.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sobre',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bio,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Goal
                  if (goal != null && goal.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Objetivo no app',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            goal,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Tags
                  if (tags.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Interesses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
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
                          isOnline: false, // Podemos implementar status online depois
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
}
