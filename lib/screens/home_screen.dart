import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../models/mood_data.dart';
import '../models/question_models.dart';
import '../models/conversation_models.dart';
import '../utils/app_colors.dart';
import '../widgets/mood_check_widget.dart';
import '../widgets/reflective_questions_widget.dart';
import '../widgets/compatible_users_widget.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/user_chat_screen.dart';

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
  String? _supportMessage;
  
  // Services
  FirebaseService? _firebaseService;
  late GeminiService _geminiService;
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    
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

  Future<void> _loadTodayMood(String userId) async {
    try {
      final mood = await _firebaseService?.getTodayMood(userId);
      setState(() {
        _todayMood = mood;
      });

      // Se precisa de apoio emocional, gerar mensagem
      if (mood?.needsSupport == true) {
        final supportMsg = await _geminiService.generateEmotionalSupport(mood!);
        setState(() {
          _supportMessage = supportMsg;
        });
      }
    } catch (e) {
      print('❌ Error loading mood: $e');
    }
  }

  Future<void> _loadDailyQuestions() async {
    try {
      // Apenas carregar perguntas existentes do dia e respostas do usuário
      var questions = await _firebaseService?.getAllQuestions() ?? [];
      
      // Carregar respostas do usuário
      final userId = _authService?.currentUser?.uid;
      if (userId != null) {
        final responses = await _firebaseService?.getUserResponses(userId) ?? [];
        final answersMap = <String, bool>{};
        for (var response in responses) {
          answersMap[response.questionId] = response.answer;
        }
        
        setState(() {
          _dailyQuestions = questions;
          _questionAnswers = answersMap;
        });
      }
    } catch (e) {
      print('❌ Error loading questions: $e');
    }
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

  // Inicia a análise diária - gera perguntas personalizadas
  void _startDailyAnalysis() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = _authService?.currentUser?.uid;
      if (userId == null) return;

      // Gerar perguntas aleatórias personalizadas para o usuário
      final questions = await _geminiService.generateDailyQuestions(
        count: 20, // Aumentado para 20 perguntas
        userMood: _todayMood,
        userId: userId, // Passa o userId para tornar as perguntas únicas
      );
      
      // Salvar as novas perguntas
      for (var question in questions) {
        await _firebaseService?.saveQuestion(question);
      }

      setState(() {
        _dailyQuestions = questions;
        _questionAnswers.clear(); // Limpar respostas anteriores
      });

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Perguntas personalizadas geradas! Vamos começar a análise.'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      print('❌ Error starting daily analysis: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao gerar análise. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                  // Support message if needed - só para quem está mal
                  if (_supportMessage != null && _todayMood?.needsSupport == true) ...[
                    _buildSupportMessage(),
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
                        
                        // Botão de análise do dia - só aparece se o humor foi registrado E não há perguntas ainda
                        if (_todayMood != null && _dailyQuestions.isEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Análise do Dia',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Quer fazer uma reflexão mais profunda sobre seu dia?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => _startDailyAnalysis(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Gostaria de fazer a análise do seu dia?',
                                    style: TextStyle(
                                      fontSize: 14,
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

  Widget _buildSupportMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Apoio Emocional',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _supportMessage!,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AiChatScreen(userMood: _todayMood),
                ),
              );
            },
            icon: const Icon(Icons.chat, size: 16),
            label: const Text('Conversar com IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia!';
    if (hour < 18) return 'Boa tarde!';
    return 'Boa noite!';
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
      
      setState(() {
        _todayMood = updatedMood;
      });

      // Verificar se precisa de apoio
      if (updatedMood.needsSupport && _supportMessage == null) {
        final supportMsg = await _geminiService.generateEmotionalSupport(updatedMood);
        setState(() {
          _supportMessage = supportMsg;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado emocional registrado!'),
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
