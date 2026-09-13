import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/preferences_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/mood_data.dart';
import '../utils/app_colors.dart';
import '../utils/scaffold_utils.dart';
import '../widgets/luma_voice_widget.dart';
import '../widgets/audio_record_button.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../widgets/user_avatar.dart';
import 'main_navigation.dart';
import '../widgets/navbar_new.dart';

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
  String _userName = ''; // Nome do usuário
  Uint8List? _userImageBytes;
  
  // Services
  FirebaseService? _firebaseService;
  AuthService? _authService;
  
  // Configurações de voz simplificadas
  SpeechRecognitionService? _speechService;
  String _interactionMode = 'text'; // 'text' ou 'voice'
  bool _hasConfigured = false;
  
  // Controle do modo visual de voz
  bool _isVisualVoiceMode = false;
  
  // Controles de áudio para o usuário
  bool _isRecordingAudio = false;
  String _partialSpeechText = '';
  bool _speechRecognitionAvailable = false;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    
    // Inicializar Speech Recognition
    _initializeSpeechRecognition();
    // Restaurar comportamento anterior: inicializar imediatamente ao abrir a tela
    // para garantir mensagem de boas-vindas visível.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndInitializeLuma();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firebaseService = Provider.of<FirebaseService>(context);
    _authService = Provider.of<AuthService>(context);
    
    // Carregar nome do usuário
    _loadUserName();
    // Carregar imagem do usuário (base64 fallback)
    _loadUserImage();
  }

  Future<void> _loadUserImage() async {
    try {
      final userId = _authService?.currentUser?.uid;
      if (userId == null) return;
      final profile = await _firebaseService?.getUserProfile(userId);
      final base64 = profile?['profileImageBase64'] as String?;
      if (base64 != null && base64.isNotEmpty) {
        try {
          final bytes = base64Decode(base64);
          setState(() {
            _userImageBytes = bytes;
          });
        } catch (_) {
          // ignore decode errors
        }
      }
    } catch (e) {
      print('❌ Error loading user image in AI chat: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      // Aguardar um momento para garantir que os providers estão disponíveis
      await Future.delayed(const Duration(milliseconds: 100));
      
      final userId = _authService?.currentUser?.uid;
      print('🔍 Carregando nome do usuário para ID: $userId');
      
      if (userId != null && _firebaseService != null) {
        final userProfile = await _firebaseService!.getUserProfile(userId);
        setState(() {
          _userName = userProfile?['name'] ?? 
                     _authService?.currentUser?.displayName ?? 
                     _authService?.currentUser?.email?.split('@')[0] ?? '';
        });
        print('👤 Nome do usuário carregado no chat: $_userName');
      } else {
        // Fallback para displayName ou email
        setState(() {
          _userName = _authService?.currentUser?.displayName ?? 
                     _authService?.currentUser?.email?.split('@')[0] ?? '';
        });
        print('⚠️ Usando fallback para nome: $_userName');
      }
      
      // Recriar mensagem de boas-vindas com o nome correto se já foi enviada
      if (_messages.isNotEmpty && !_messages.first.isUser) {
        _updateWelcomeMessage();
      }
    } catch (e) {
      print('❌ Error loading user name in chat: $e');
      setState(() {
        _userName = _authService?.currentUser?.displayName ?? 
                   _authService?.currentUser?.email?.split('@')[0] ?? 
                   'Usuário';
      });
    }
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
      
      // Aguardar um pouco para garantir que o nome do usuário seja carregado
      await Future.delayed(const Duration(milliseconds: 500));
      _sendWelcomeMessage();
    } else {
      // Primeira vez - mostrar modal de configuração apenas se a tela estiver visível
      if (mounted) {
        _showInitialSetupModal();
      }
    }
  }

  /// Alterna para modo texto
  Future<void> _switchToTextMode() async {
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
    });
    
    ScaffoldUtils.showSuccessSnackBar('Modo de chat por texto ativado 💬');
  }

  /// Alterna para modo voz
  Future<void> _switchToVoiceMode() async {
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
    });
    
    ScaffoldUtils.showSuccessSnackBar('Modo de conversa por voz ativado 🗣️🦊');
  }

  /// Inicializar serviço de reconhecimento de fala
  Future<void> _initializeSpeechRecognition() async {
    try {
      _speechService = SpeechRecognitionService();
      _speechRecognitionAvailable = await _speechService!.initialize();
      
      if (_speechRecognitionAvailable) {
        print('✅ Reconhecimento de fala inicializado');
        
        // Configurar callbacks
        _speechService!.onResult = (String text) {
          _onSpeechRecognitionResult(text);
        };
        
        _speechService!.onPartialResult = (String text) {
          _onPartialSpeechResult(text);
        };
        
        _speechService!.onError = (String error) {
          _onSpeechRecognitionError(error);
        };
        
        _speechService!.onListeningStart = () {
          setState(() {
            _isRecordingAudio = true;
          });
        };
        
        _speechService!.onListeningStop = () {
          setState(() {
            _isRecordingAudio = false;
            _partialSpeechText = '';
          });
        };
      } else {
        print('❌ Reconhecimento de fala não está disponível');
      }
    } catch (e) {
      print('❌ Erro ao inicializar reconhecimento de fala: $e');
      _speechRecognitionAvailable = false;
    }
  }

  /// Iniciar gravação de áudio
  Future<void> _startAudioRecording() async {
    if (!_speechRecognitionAvailable || _speechService == null) {
      ScaffoldUtils.showErrorSnackBar('Reconhecimento de fala não disponível');
      return;
    }

    if (_isRecordingAudio) return;

    try {
      final started = await _speechService!.startListening(
        localeId: _speechService!.getDefaultLocale(),
      );

      if (!started) {
        ScaffoldUtils.showErrorSnackBar('Não foi possível iniciar a gravação');
      }
    } catch (e) {
      print('❌ Erro ao iniciar gravação: $e');
      ScaffoldUtils.showErrorSnackBar('Erro ao iniciar gravação: $e');
    }
  }

  /// Parar gravação de áudio
  Future<void> _stopAudioRecording() async {
    if (_speechService == null || !_isRecordingAudio) return;

    try {
      await _speechService!.stopListening();
    } catch (e) {
      print('❌ Erro ao parar gravação: $e');
    }
  }

  /// Callback para resultado final do reconhecimento de fala
  void _onSpeechRecognitionResult(String text) {
    if (text.trim().isEmpty) return;

    print('🎤 Texto reconhecido: $text');
    
    // Adicionar o texto reconhecido ao campo de mensagem
    _messageController.text = text.trim();
    
    // Enviar automaticamente se estiver no modo de voz
    if (_interactionMode == 'voice') {
      _sendMessage();
    }
    
    // Limpar texto parcial
    setState(() {
      _partialSpeechText = '';
    });
  }

  /// Callback para resultado parcial do reconhecimento de fala
  void _onPartialSpeechResult(String text) {
    setState(() {
      _partialSpeechText = text;
    });
  }

  /// Callback para erros do reconhecimento de fala
  void _onSpeechRecognitionError(String error) {
    print('❌ Erro no reconhecimento de fala: $error');
    ScaffoldUtils.showErrorSnackBar('Erro no reconhecimento: $error');
    
    setState(() {
      _isRecordingAudio = false;
      _partialSpeechText = '';
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    
    // Limpar recursos de áudio
    _speechService?.dispose();
    
    super.dispose();
  }

  void _updateWelcomeMessage() {
    if (_messages.isNotEmpty && !_messages.first.isUser) {
      // Recriar a mensagem de boas-vindas com o nome correto
      final name = _userName.isNotEmpty ? _userName : 'você';
      String welcomeMessage;
      
      if (widget.userMood?.needsSupport == true) {
        welcomeMessage = "Olá $name, sou a Luma 💙 Percebo que hoje pode não estar sendo um dia fácil para você. "
            "Quero que saiba que é completamente normal sentir-se assim às vezes, e você foi muito corajoso(a) "
            "ao buscar apoio. Este é um espaço seguro onde seus sentimentos são válidos e importantes. "
            "Estou aqui, presente com você. Como posso te acompanhar neste momento?";
      } else {
        // Personalizar mensagem baseada no modo de interação
        if (_interactionMode == 'voice') {
          welcomeMessage = "Olá $name! Sou a Luma ✨ É um prazer te encontrar aqui. Meu nome significa 'luz', "
              "e estou aqui para iluminar sua jornada de bem-estar emocional com minha voz. "
              "Este é um espaço acolhedor onde você pode se expressar livremente. Como você está se sentindo hoje?";
        } else {
          welcomeMessage = "Olá $name! Sou a Luma ✨ É um prazer te encontrar aqui. Meu nome significa 'luz', "
              "e estou aqui para iluminar sua jornada de bem-estar emocional. Este é um espaço acolhedor "
              "onde você pode se expressar livremente, refletir sobre seus sentimentos e descobrir "
              "recursos internos que já possui. Como você está se sentindo hoje?";
        }
      }
      
      setState(() {
        _messages[0] = ChatMessage(
          text: welcomeMessage,
          isUser: false,
          timestamp: _messages[0].timestamp,
        );
      });
      
      print('🔄 Mensagem de boas-vindas atualizada com nome: $name');
    }
  }

  void _sendWelcomeMessage() {
    String welcomeMessage;
    final name = _userName.isNotEmpty ? _userName : 'você';
    
    print('📝 Criando mensagem de boas-vindas com nome: "$name" (_userName: "$_userName")');
    
    if (widget.userMood?.needsSupport == true) {
      welcomeMessage = "Olá $name, sou a Luma 💙 Percebo que hoje pode não estar sendo um dia fácil para você. "
          "Quero que saiba que é completamente normal sentir-se assim às vezes, e você foi muito corajoso(a) "
          "ao buscar apoio. Este é um espaço seguro onde seus sentimentos são válidos e importantes. "
          "Estou aqui, presente com você. Como posso te acompanhar neste momento?";
    } else {
      // Personalizar mensagem baseada no modo de interação
      if (_interactionMode == 'voice') {
        welcomeMessage = "Olá $name! Sou a Luma ✨ É um prazer te encontrar aqui. Meu nome significa 'luz', "
            "e estou aqui para iluminar sua jornada de bem-estar emocional com minha voz. "
            "Este é um espaço acolhedor onde você pode se expressar livremente. Como você está se sentindo hoje?";
      } else {
        welcomeMessage = "Olá $name! Sou a Luma ✨ É um prazer te encontrar aqui. Meu nome significa 'luz', "
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
        userName: _userName.isNotEmpty ? _userName : null,
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
  // Inicialização automática restaurada (mensagem de boas-vindas deve aparecer sem ação extra)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Detectar se devemos mostrar a navbar: se MainNavigation está montado e queremos experiência contínua
  // Exibir navbar dentro do chatbot conforme solicitado
  // Navbar sempre visível nesta tela conforme pedido
  const bool showPersistentNavbar = true;
  // Ajuste: reduzir espaço inferior para trazer conteúdo mais perto da navbar
  const double navBarReservedHeight = 40; // altura da navbar para padding inferior (reduzido de 70)
    
    // Se estiver no modo visual de voz, mostrar a interface da Luma
    if (_isVisualVoiceMode) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.gray50,
        appBar: _buildChatAppBar(isDark, showPersistentNavbar: showPersistentNavbar),
        body: Padding(
          padding: const EdgeInsets.only(bottom: navBarReservedHeight),
          child: Column(
          children: [
            // Interface visual da Luma
            Expanded(
                      child: LumaVoiceWidget(
                                isSpeaking: false,
                              ),
            ),
            
            // Input de texto para modo voz
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Botão de gravação de áudio (se disponível)
                  if (_speechRecognitionAvailable)
                    AudioRecordButton(
                      isRecording: _isRecordingAudio,
                      isEnabled: _speechRecognitionAvailable && !_isLoading,
                      onStartRecording: _startAudioRecording,
                      onStopRecording: _stopAudioRecording,
                      partialText: _partialSpeechText.isNotEmpty ? _partialSpeechText : null,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Input de texto
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocus,
                          decoration: InputDecoration(
                            hintText: 'Digite sua mensagem para a Luma...',
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.gray300),
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
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
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
                ],
              ),
            ),
          ],
        ),
        ),
  bottomNavigationBar: _buildEmbeddedNavbar(),
      );
    }
    
    // Modo texto normal
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.gray50,
      appBar: _buildChatAppBar(isDark, showPersistentNavbar: showPersistentNavbar),
      body: Padding(
  padding: const EdgeInsets.only(bottom: navBarReservedHeight),
        child: Column(
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
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
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
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
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
      ),
  bottomNavigationBar: _buildEmbeddedNavbar(),
    );
  }

  PreferredSizeWidget _buildChatAppBar(bool isDark, {bool showPersistentNavbar = false}) {
    final modeLabel = _interactionMode == 'voice'
        ? 'Voz'
        : 'Texto';

    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      leading: IconButton(
        icon: Icon(showPersistentNavbar ? Icons.arrow_back : Icons.close, color: isDark ? Colors.white : AppColors.textPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar da Luma
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/cabecaLuma.png',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Luma',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey(modeLabel),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (_interactionMode == 'voice'
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.15))
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    modeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _interactionMode == 'voice'
                          ? AppColors.primary
                          : (isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_interactionMode == 'voice')
          IconButton(
            tooltip: 'Trocar para texto',
            icon: Icon(Icons.chat_bubble_outline, color: isDark ? Colors.white70 : AppColors.textSecondary),
            onPressed: _switchToTextMode,
          )
        else
          IconButton(
            tooltip: 'Modo voz',
            icon: Icon(Icons.record_voice_over, color: isDark ? Colors.white70 : AppColors.textSecondary),
            onPressed: _switchToVoiceMode,
          ),
        IconButton(
          tooltip: 'Opções',
          icon: Icon(Icons.more_vert, color: isDark ? Colors.white : AppColors.textPrimary),
          onPressed: showChatOptions,
        ),
      ],
    );
  }

  Widget _buildEmbeddedNavbar() {
    // Não marcar nenhuma aba como selecionada quando dentro da Luma
    // Isso permite que o usuário clique em qualquer aba (incluindo a que estava antes) para voltar
    return CustomNavbar(
      selectedIndex: -1, // -1 = nenhuma aba marcada
      onItemTapped: (index) {
        // Sempre fecha o chat e navega para a aba clicada
        Navigator.of(context).pop();
        MainNavigation.mainNavigationKey.currentState?.switchToTab(index);
      },
      onCenterAvatarTap: () {
        // Não fechar o chat ao tocar novamente no avatar — evita efeito de toggle inesperado.
        // Mantemos o chat aberto; o botão central pode ser usado futuramente para abrir opções.
        return;
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // Avatar da Luma
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/cabecaLuma.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback para o ícone antigo se a imagem não carregar
                    return Container(
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
                    );
                  },
                ),
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
                color: message.isUser
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
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
                      color: message.isUser
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : (isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 12),
            // Avatar do usuário (use profile image bytes if available)
            UserAvatar(
              imageBytes: _userImageBytes,
              radius: 18,
              useAuthPhoto: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
  color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão de gravação de áudio (se disponível e texto parcial)
            if (_speechRecognitionAvailable && (_isRecordingAudio || _partialSpeechText.isNotEmpty))
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_partialSpeechText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mic,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _partialSpeechText,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            
            // Input principal
            Row(
              children: [
                // Botão de áudio
                if (_speechRecognitionAvailable)
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _isRecordingAudio 
                        ? Colors.red.withOpacity(0.1)
                        : (isDark ? const Color(0xFF121212) : AppColors.gray100),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isRecordingAudio 
                          ? Colors.red
                          : (isDark ? Colors.white24 : AppColors.gray300),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _speechRecognitionAvailable && !_isLoading
                        ? (_isRecordingAudio 
                            ? _stopAudioRecording 
                            : _startAudioRecording)
                        : null,
                      icon: Icon(
                        _isRecordingAudio ? Icons.stop : Icons.mic,
                        color: _isRecordingAudio 
                          ? Colors.red
                          : (_speechRecognitionAvailable 
                              ? AppColors.primary 
                              : (isDark ? Colors.white38 : AppColors.gray400)),
                        size: 20,
                      ),
                    ),
                  ),
                
                // Campo de texto
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : AppColors.gray50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white12 : AppColors.gray300,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocus,
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Botão de enviar
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
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
  backgroundColor: isDark ? AppColors.darkSurface : null,
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
            Text('Olá! Sou a Luma', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como você gostaria de conversar comigo?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
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
                title: Text('Chat por Texto', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
                subtitle: Text('Conversaremos apenas escrevendo', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                onTap: () => _finishSetup('text'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Opção Texto com Áudio (se disponível)
            if (_speechRecognitionAvailable)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.mic_rounded, color: AppColors.primary),
                  title: Text('Chat com Áudio', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
                  subtitle: Text('Você pode falar ou escrever suas mensagens', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                  onTap: () => _finishSetup('text'),
                ),
              ),
            
            if (_speechRecognitionAvailable) const SizedBox(height: 12),
            
            // Opção Voz
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.record_voice_over, color: AppColors.primary),
                title: Text('Chat por Voz Completo', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
                subtitle: Text('Conversaremos apenas por áudio', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                onTap: () => _finishSetup('voice'),
              ),
            ),
          ],
        ),
      );
      },
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

  void showChatOptions() {
    showModalBottomSheet(
      context: context,
  backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : null,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isVisualVoiceMode ? 'Opções da Conversa por Voz' : 'Opções da Luma',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Opção para alternar modo
            if (_isVisualVoiceMode)
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                title: Text('Voltar ao Chat por Texto', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
                subtitle: Text('Conversar com balões de mensagem', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _switchToTextMode();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.record_voice_over, color: AppColors.primary),
                title: Text('Chat por Voz', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
                subtitle: Text('Conversar com a Luma visualmente', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  _switchToVoiceMode();
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.primary),
              title: Text('Reiniciar conversa', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              subtitle: Text('Começar uma nova conversa com a Luma', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(context);
                _restartConversation();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: AppColors.primary),
              title: Text('Sobre a Luma', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              subtitle: Text('Conheça sua assistente de bem-estar', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(context);
                _showAboutAI();
              },
            ),
            ListTile(
              leading: const Icon(Icons.tips_and_updates, color: AppColors.primary),
              title: Text('Dicas de conversa', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              subtitle: Text('Como aproveitar melhor nosso tempo juntas', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
              onTap: () {
                Navigator.pop(context);
                _showChatTips();
              },
            ),
          ],
        ),
      );
      },
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
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
  backgroundColor: isDark ? AppColors.darkSurface : null,
        title: Text('Sobre a Luma ✨', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
        content: Text(
          'Olá! Sou a Luma, sua assistente de bem-estar emocional. Meu nome significa "luz" em latim, '
          'representando a esperança e clareza que busco trazer para sua jornada.\n\n'
          '💙 Meu propósito:\n'
          '• Oferecer um espaço seguro para suas emoções\n'
          '• Praticar escuta ativa e empática\n'
          '• Compartilhar técnicas de bem-estar\n'
          '• Apoiar seu autoconhecimento\n'
          '• Estar presente nos momentos difíceis\n\n'
          'Em que posso te ajudar? :D',
          style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Obrigado(a), Luma! 💙'),
          ),
        ],
      );
      },
    );
  }

  void _showChatTips() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
  backgroundColor: isDark ? AppColors.darkSurface : null,
        title: Text('Dicas para nossa conversa 🌟', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
        content: Text(
          '🗣️ **Seja autêntico(a)**: Seus sentimentos são sempre válidos aqui\n\n'
          '⏰ **Sem pressa**: Vamos no seu ritmo, sem pressão\n\n'
          '🎯 **Compartilhe detalhes**: Quanto mais você me contar, melhor posso te acompanhar\n\n'
          '❓ **Faça perguntas**: Sobre técnicas, estratégias ou qualquer dúvida\n\n'
          '🔄 **Continue a conversa**: Cada troca constrói nossa conexão\n\n'
          '💪 **Celebre pequenas vitórias**: Toda conquista merece reconhecimento\n\n'
          'Lembre-se: este é seu espaço. Use-o como se sentir mais confortável! 💙',
          style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vamos conversar!'),
          ),
        ],
      );
      },
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
