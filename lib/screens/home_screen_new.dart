import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
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
import '../screens/main_navigation.dart';
import '../screens/user_chat_screen.dart';
import '../widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  // Data
  MoodData? _todayMood;
  List<ReflectiveQuestion> _dailyQuestions = [];
  List<Map<String, dynamic>> _compatibleUsers = [];
  Map<String, bool> _questionAnswers = {};
  String? _supportMessage;
  
  // Services
  late FirebaseService _firebaseService;
  late GeminiService _geminiService;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _geminiService = GeminiService();
    _loadInitialData();
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
      final userId = _authService.currentUser?.uid;
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
      final mood = await _firebaseService.getTodayMood(userId);
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
      // Tentar carregar perguntas existentes do dia
      var questions = await _firebaseService.getAllQuestions();
      
      // Se não houver perguntas, gerar novas
      if (questions.isEmpty) {
        questions = await _geminiService.generateDailyQuestions(
          count: 5,
          userMood: _todayMood,
        );
        
        // Salvar as novas perguntas
        for (var question in questions) {
          await _firebaseService.saveQuestion(question);
        }
      }

      // Carregar respostas do usuário
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final responses = await _firebaseService.getUserResponses(userId);
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
      final users = await _firebaseService.getCompatibleUsers(userId, limit: 10);
      setState(() {
        _compatibleUsers = users;
      });
    } catch (e) {
      print('❌ Error loading compatible users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MindMatch',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Wellness score indicator
          if (_todayMood != null)
            _buildWellnessIndicator(),
          
          IconButton(
            onPressed: _showProfileMenu,
            icon: UserAvatar(
              radius: 16,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.mood),
              text: 'Humor',
            ),
            Tab(
              icon: Icon(Icons.psychology),
              text: 'Reflexão',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Conexões',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Support message if needed
                if (_supportMessage != null)
                  _buildSupportMessage(),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMoodTab(),
                      _buildReflectionTab(),
                      _buildConnectionsTab(),
                    ],
                  ),
                ),
              ],
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
              MainNavigation.navigateToAIChat();
            },
            icon: const Icon(Icons.psychology, size: 16),
            label: const Text('Falar com a Luma'),
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

  Widget _buildMoodTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MoodCheckWidget(
        initialMood: _todayMood,
        onMoodSubmitted: _handleMoodSubmission,
      ),
    );
  }

  Widget _buildReflectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ReflectiveQuestionsWidget(
        questions: _dailyQuestions,
        existingAnswers: _questionAnswers,
        onQuestionAnswered: _handleQuestionAnswer,
      ),
    );
  }

  Widget _buildConnectionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CompatibleUsersWidget(
        compatibleUsers: _compatibleUsers,
        onUserTapped: _showUserProfile,
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
      final userId = _authService.currentUser?.uid;
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

      await _firebaseService.saveMoodData(updatedMood);
      
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
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      // Atualizar o userId
      final updatedResponse = QuestionResponse(
        userId: userId,
        questionId: response.questionId,
        answer: response.answer,
        answeredAt: response.answeredAt,
      );

      await _firebaseService.saveQuestionResponse(updatedResponse);
      
      setState(() {
        _questionAnswers[response.questionId] = response.answer;
      });

      // Recarregar usuários compatíveis
      _loadCompatibleUsers(userId);
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
  final profileImageBase64 = user['profileImageBase64'] as String?;
  final Uint8List? profileImageBytes = (profileImageBase64 != null && profileImageBase64.isNotEmpty) ? base64Decode(profileImageBase64) : null;
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
                      UserAvatar(
                        imageUrl: profileImage,
                        imageBytes: profileImageBytes,
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
                          profileImageBase64: profileImageBase64,
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
                  await _authService.signOut();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
