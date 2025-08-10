import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../models/mood_data.dart';
import '../utils/app_colors.dart';

class AiChatScreen extends StatefulWidget {
  final MoodData? userMood;

  const AiChatScreen({
    super.key,
    this.userMood,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late GeminiService _geminiService;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    
    // Enviar mensagem inicial de boas-vindas baseada no humor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _sendWelcomeMessage() {
    String welcomeMessage;
    
    if (widget.userMood?.needsSupport == true) {
      welcomeMessage = "Olá! 💙 Percebi que você não está se sentindo muito bem hoje. "
          "Estou aqui para conversar e te apoiar. Como posso te ajudar neste momento?";
    } else {
      welcomeMessage = "Olá! 😊 Sou sua assistente de bem-estar emocional. "
          "Estou aqui para conversar, ouvir e te apoiar sempre que precisar. "
          "Como você está se sentindo hoje?";
    }

    setState(() {
      _messages.add(ChatMessage(
        text: welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Preparar contexto da conversa
      final conversationContext = _messages
          .take(_messages.length - 1) // Excluir a última mensagem (a que acabou de ser enviada)
          .map((msg) => "${msg.isUser ? 'Usuário' : 'IA'}: ${msg.text}")
          .join('\n');

      // Gerar resposta da IA
      final response = await _geminiService.generateChatResponse(
        userMessage: messageText,
        userMood: widget.userMood,
        conversationContext: conversationContext,
      );

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Desculpe, ocorreu um erro. Tente novamente em alguns momentos. 🤗",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistente de Bem-estar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Aqui para te apoiar',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showChatOptions,
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status do humor do usuário (se disponível)
          if (widget.userMood != null) _buildMoodStatusBar(),
          
          // Lista de mensagens
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Indicador de carregamento
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(width: 60), // Espaço para alinhar com mensagens da IA
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pensando...',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Campo de entrada de mensagem
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMoodStatusBar() {
    final mood = widget.userMood!;
    final score = mood.wellnessScore;
    final color = score >= 70 ? Colors.green : score >= 40 ? Colors.orange : Colors.red;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Seu bem-estar hoje: ${score.toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              mood.needsSupport ? 'Apoio disponível' : 'Tudo bem',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // Avatar da IA
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Bolha da mensagem
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: message.isUser ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 12),
            // Avatar do usuário
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.gray300,
              child: Icon(
                Icons.person,
                color: AppColors.gray600,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.gray300,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocus,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: Icon(
                  _isLoading ? Icons.hourglass_empty : Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Opções do Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.primary),
              title: const Text('Reiniciar conversa'),
              subtitle: const Text('Limpar histórico e começar novamente'),
              onTap: () {
                Navigator.pop(context);
                _restartConversation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('Sobre a IA'),
              subtitle: const Text('Entenda como funciona o apoio emocional'),
              onTap: () {
                Navigator.pop(context);
                _showAboutAI();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppColors.primary),
              title: const Text('Dicas de conversa'),
              subtitle: const Text('Como aproveitar melhor o chat'),
              onTap: () {
                Navigator.pop(context);
                _showChatTips();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _restartConversation() {
    setState(() {
      _messages.clear();
    });
    _sendWelcomeMessage();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversa reiniciada!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAboutAI() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre a Assistente de Bem-estar'),
        content: const Text(
          'Sou uma IA especializada em apoio emocional e bem-estar mental. '
          'Estou aqui para:\n\n'
          '• Ouvir suas preocupações com empatia\n'
          '• Oferecer perspectivas positivas\n'
          '• Sugerir técnicas de relaxamento\n'
          '• Apoiar sua jornada de autoconhecimento\n\n'
          'Lembre-se: não substituo ajuda profissional, mas posso ser um apoio valioso no seu dia a dia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _showChatTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dicas para uma boa conversa'),
        content: const Text(
          '💭 Seja sincero sobre seus sentimentos\n\n'
          '🗣️ Descreva situações específicas\n\n'
          '❓ Faça perguntas sobre estratégias\n\n'
          '🎯 Compartilhe seus objetivos\n\n'
          '⏰ Use nosso tempo sem pressa\n\n'
          '🤝 Lembre-se: estou aqui para te apoiar!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Obrigado!'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
