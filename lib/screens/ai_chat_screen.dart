import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/elevenlabs_service.dart';
import '../services/preferences_service.dart';
import '../models/mood_data.dart';
import '../utils/app_colors.dart';
import '../utils/scaffold_utils.dart';
import '../widgets/luma_voice_widget.dart';

class AiChatScreen extends StatefulWidget {
  final MoodData? userMood;

  const AiChatScreen({
    super.key,
    this.userMood,
  });

  @override
  State<AiChatScreen> createState() => AiChatScreenState();
}

class AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late GeminiService _geminiService;
  
  // Configurações de voz simplificadas
  ElevenLabsService? _elevenLabsService;
  String _interactionMode = 'text'; // 'text' ou 'voice'
  bool _hasConfigured = false;
  
  // Controle do modo visual de voz
  bool _isVisualVoiceMode = false;
  String? _currentSpeechText;
  bool _isSpeakingNow = false;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    
    // Inicializar ElevenLabs
    try {
      _elevenLabsService = ElevenLabsService();
      print('✅ ElevenLabs inicializado');
    } catch (e) {
      print('⚠️ ElevenLabs não disponível: $e');
    }
    
    // NÃO inicializar automaticamente - aguardar o usuário acessar a tela
  }

  /// Método público chamado pelo MainNavigation quando a aba se torna ativa
  Future<void> checkAndInitializeWhenActive() async {
    if (!_hasConfigured) {
      await _checkAndInitializeLuma();
    }
  }

  /// Verifica se a tela está visível e inicializa a Luma apenas quando necessário
  Future<void> _checkAndInitializeLuma() async {
    // Verificar se já foi configurado
    _hasConfigured = await PreferencesService.hasConfiguredLuma();
    
    if (_hasConfigured) {
      // Carregar configurações salvas
      _interactionMode = await PreferencesService.getLumaInteractionMode();
      
      // Se for modo voz, ativar modo visual
      if (_interactionMode == 'voice') {
        _isVisualVoiceMode = true;
      }
      
      setState(() {});
      
      _sendWelcomeMessage();
    } else {
      // Primeira vez - mostrar modal de configuração apenas se a tela estiver visível
      if (mounted) {
        _showInitialSetupModal();
      }
    }
  }

  /// Manipula o toque na Luma no modo voz
  void _handleLumaTap() {
    if (_isSpeakingNow) {
      // Se estiver falando, parar
      _elevenLabsService?.stop();
      setState(() {
        _isSpeakingNow = false;
        _currentSpeechText = null;
      });
    }
  }

  /// Alterna para modo texto
  Future<void> _switchToTextMode() async {
    // Parar qualquer operação em andamento
    _elevenLabsService?.stop();
    
    // Cancelar loading se estiver em progresso
    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
    
    await PreferencesService.setLumaInteractionMode('text');
    setState(() {
      _interactionMode = 'text';
      _isVisualVoiceMode = false;
      _isSpeakingNow = false;
      _currentSpeechText = null;
    });
    
    ScaffoldUtils.showSuccessSnackBar('Modo de chat por texto ativado 💬');
  }

  /// Alterna para modo voz
  Future<void> _switchToVoiceMode() async {
    // Parar qualquer operação em andamento
    _elevenLabsService?.stop();
    
    // Cancelar loading se estiver em progresso
    if (_isLoading) {
      setState(() {
        _isLoading = false;
      });
    }
    
    await PreferencesService.setLumaInteractionMode('voice');
    setState(() {
      _interactionMode = 'voice';
      _isVisualVoiceMode = true;
      _isSpeakingNow = false;
      _currentSpeechText = null;
    });
    
    ScaffoldUtils.showSuccessSnackBar('Modo de conversa por voz ativado 🗣️🦊');
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
      welcomeMessage = "Olá, sou a Luma 💙 Percebo que hoje pode não estar sendo um dia fácil para você. "
          "Quero que saiba que é completamente normal sentir-se assim às vezes, e você foi muito corajoso(a) "
          "ao buscar apoio. Este é um espaço seguro onde seus sentimentos são válidos e importantes. "
          "Estou aqui, presente com você. Como posso te acompanhar neste momento?";
    } else {
      // Personalizar mensagem baseada no modo de interação
      if (_interactionMode == 'voice') {
        welcomeMessage = "Olá! Sou a Luma ✨ É um prazer te encontrar aqui. Meu nome significa 'luz', "
            "e estou aqui para iluminar sua jornada de bem-estar emocional com minha voz. "
            "Este é um espaço acolhedor onde você pode se expressar livremente. Como você está se sentindo hoje?";
      } else {
        welcomeMessage = "Olá! Sou a Luma ✨ É um prazer te encontrar aqui. Meu nome significa 'luz', "
            "e estou aqui para iluminar sua jornada de bem-estar emocional. Este é um espaço acolhedor "
            "onde você pode se expressar livremente, refletir sobre seus sentimentos e descobrir "
            "recursos internos que já possui. Como você está se sentindo hoje?";
      }
    }

    setState(() {
      _messages.add(ChatMessage(
        text: welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();

    // NÃO falar mensagem de boas-vindas automaticamente
    // A Luma só fala quando o usuário enviar uma mensagem
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

      // 🔊 FALAR RESPOSTA SE MODO VOZ ATIVO
      if (_interactionMode == 'voice') {
        await _speakMessage(response);
      }

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
    // REMOVIDO: Inicialização automática quando a tela é construída
    // Agora só inicializa quando o usuário realmente acessa a aba
    
    // Se estiver no modo visual de voz, mostrar a interface da Luma
    if (_isVisualVoiceMode) {
      return Scaffold(
        backgroundColor: AppColors.gray50,
        body: Column(
          children: [
            // Interface visual da Luma
            Expanded(
              child: LumaVoiceWidget(
                isSpeaking: _isSpeakingNow,
                currentMessage: _currentSpeechText,
                onTap: _handleLumaTap,
              ),
            ),
            
            // Input de texto para modo voz
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocus,
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem para a Luma...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: AppColors.gray300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Modo texto normal
    return Scaffold(
      backgroundColor: AppColors.gray50,
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
                Icons.auto_awesome,
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

  // 🆕 MODAL SIMPLES PARA ESCOLHA VOZ/TEXTO

  void _showInitialSetupModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Olá! Sou a Luma'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Como você gostaria de conversar comigo?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            // Opção Texto
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.text_fields, color: AppColors.primary),
                title: const Text('Chat por Texto'),
                subtitle: const Text('Conversaremos apenas escrevendo'),
                onTap: () => _finishSetup('text'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Opção Voz
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.record_voice_over, color: AppColors.primary),
                title: const Text('Chat por Voz'),
                subtitle: const Text('Eu falarei minhas respostas para você'),
                onTap: () => _finishSetup('voice'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishSetup(String mode) async {
    Navigator.pop(context);
    
    // Salvar configurações
    await PreferencesService.setLumaInteractionMode(mode);
    await PreferencesService.setLumaConfigured();
    
    // Atualizar estado local
    setState(() {
      _interactionMode = mode;
      _hasConfigured = true;
      
      // Se escolheu voz, ativar modo visual
      if (mode == 'voice') {
        _isVisualVoiceMode = true;
      }
    });
    
    // Mostrar mensagem de confirmação
    ScaffoldUtils.showSuccessSnackBar(
      mode == 'voice' 
        ? 'Ótimo! Agora você verá a Luma e ela falará com você 🗣️🦊' 
        : 'Perfeito! Vamos conversar por texto 💬'
    );
    
    // Enviar mensagem de boas-vindas
    _sendWelcomeMessage();
  }

  /// Atualiza o método de fala para funcionar com o modo visual
  Future<void> _speakMessage(String text) async {
    if (_interactionMode != 'voice' || _elevenLabsService == null) return;
    
    try {
      // Atualizar estado visual
      setState(() {
        _isSpeakingNow = true;
        _currentSpeechText = text;
      });
      
      print('🌐 Falando com ElevenLabs: $text');
      await _elevenLabsService!.speak(text, voiceId: '21m00Tcm4TlvDq8ikWAM');
      
      // Limpar estado visual após falar
      setState(() {
        _isSpeakingNow = false;
        _currentSpeechText = null;
      });
      
    } catch (e) {
      print('❌ Erro ao falar: $e');
      setState(() {
        _isSpeakingNow = false;
        _currentSpeechText = null;
      });
      ScaffoldUtils.showErrorSnackBar('Erro ao reproduzir áudio');
    }
  }

  void showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isVisualVoiceMode ? 'Opções da Conversa por Voz' : 'Opções da Luma',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Opção para alternar modo
            if (_isVisualVoiceMode)
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                title: const Text('Voltar ao Chat por Texto'),
                subtitle: const Text('Conversar com balões de mensagem'),
                onTap: () {
                  Navigator.pop(context);
                  _switchToTextMode();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.record_voice_over, color: AppColors.primary),
                title: const Text('Chat por Voz'),
                subtitle: const Text('Conversar com a Luma visualmente'),
                onTap: () {
                  Navigator.pop(context);
                  _switchToVoiceMode();
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.primary),
              title: const Text('Reiniciar conversa'),
              subtitle: const Text('Começar uma nova conversa com a Luma'),
              onTap: () {
                Navigator.pop(context);
                _restartConversation();
              },
            ),
            
            // Opção para parar fala (só no modo voz)
            if (_isVisualVoiceMode)
              ListTile(
                leading: const Icon(Icons.volume_off, color: AppColors.error),
                title: const Text('Parar fala atual'),
                subtitle: const Text('Interromper a Luma se estiver falando'),
                onTap: () {
                  Navigator.pop(context);
                  _handleLumaTap();
                },
              ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: AppColors.primary),
              title: const Text('Sobre a Luma'),
              subtitle: const Text('Conheça sua assistente de bem-estar'),
              onTap: () {
                Navigator.pop(context);
                _showAboutAI();
              },
            ),
            ListTile(
              leading: const Icon(Icons.tips_and_updates, color: AppColors.primary),
              title: const Text('Dicas de conversa'),
              subtitle: const Text('Como aproveitar melhor nosso tempo juntas'),
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
    
    ScaffoldUtils.showSnackBar(
      'Nova conversa iniciada com a Luma! ✨',
      backgroundColor: AppColors.primary,
    );
  }

  void _showAboutAI() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre a Luma ✨'),
        content: const Text(
          'Olá! Sou a Luma, sua assistente de bem-estar emocional. Meu nome significa "luz" em latim, '
          'representando a esperança e clareza que busco trazer para sua jornada.\n\n'
          '💙 Meu propósito:\n'
          '• Oferecer um espaço seguro para suas emoções\n'
          '• Praticar escuta ativa e empática\n'
          '• Compartilhar técnicas de bem-estar\n'
          '• Apoiar seu autoconhecimento\n'
          '• Estar presente nos momentos difíceis\n\n'
          'Em que posso te ajudar? :D',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Obrigado(a), Luma! 💙'),
          ),
        ],
      ),
    );
  }

  void _showChatTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dicas para nossa conversa 🌟'),
        content: const Text(
          '🗣️ **Seja autêntico(a)**: Seus sentimentos são sempre válidos aqui\n\n'
          '⏰ **Sem pressa**: Vamos no seu ritmo, sem pressão\n\n'
          '🎯 **Compartilhe detalhes**: Quanto mais você me contar, melhor posso te acompanhar\n\n'
          '❓ **Faça perguntas**: Sobre técnicas, estratégias ou qualquer dúvida\n\n'
          '🔄 **Continue a conversa**: Cada troca constrói nossa conexão\n\n'
          '💪 **Celebre pequenas vitórias**: Toda conquista merece reconhecimento\n\n'
          'Lembre-se: este é seu espaço. Use-o como se sentir mais confortável! 💙',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vamos conversar!'),
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
