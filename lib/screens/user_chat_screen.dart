import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/global_notification_service.dart';
import '../providers/conversations_provider.dart';
import '../models/conversation_models.dart';
import '../utils/app_colors.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../widgets/user_avatar.dart';

class UserChatScreen extends StatefulWidget {
  final ChatUser otherUser;

  const UserChatScreen({
    super.key,
    required this.otherUser,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();
  
  bool _isLoading = true;
  bool _isSending = false;
  String? _conversationId;
  
  FirebaseService? _firebaseService;
  AuthService? _authService;
  GlobalNotificationService? _globalNotificationService;
  Uint8List? _myImageBytes;

  @override
  void initState() {
    super.initState();
    print('🎬 UserChatScreen initState - Starting initialization');
    print('👤 Other user: ${widget.otherUser.name} (${widget.otherUser.id})');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🚀 PostFrameCallback - About to initialize chat');
      _initializeChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _globalNotificationService = Provider.of<GlobalNotificationService>(context, listen: false);
    
    print('🔧 didChangeDependencies called');
    print('🔥 FirebaseService: ${_firebaseService != null ? "✅ Available" : "❌ NULL"}');
    print('🔐 AuthService: ${_authService != null ? "✅ Available" : "❌ NULL"}');
    print('👥 Current user: ${_authService?.currentUser?.uid ?? "❌ NULL"}');
    // Try to load current user's profile image (base64 fallback)
    _loadMyProfileImage();
  }

  Future<void> _loadMyProfileImage() async {
    try {
      final uid = _authService?.currentUser?.uid;
      if (uid == null) return;
      final profile = await _firebaseService?.getUserProfile(uid);
      final base64 = profile?['profileImageBase64'] as String?;
      if (base64 != null && base64.isNotEmpty) {
        try {
          final bytes = base64Decode(base64);
          setState(() {
            _myImageBytes = bytes;
          });
        } catch (_) {
          // ignore
        }
      }
    } catch (e) {
      print('❌ Error loading my profile image: $e');
    }
  }

  @override
  void dispose() {
    // Limpar a tela ativa de chat ao sair
    _globalNotificationService?.setActiveChatScreen(null);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final userId = _authService?.currentUser?.uid;
      if (userId == null) {
        print('❌ No current user found');
        return;
      }

      print('🚀 Initializing chat between $userId and ${widget.otherUser.id}');

      // Buscar ou criar conversa
      final conversationId = await _firebaseService?.getOrCreateConversation(
        userId, 
        widget.otherUser.id,
      );
      
      print('💬 Conversation ID: $conversationId');
      
      setState(() {
        _conversationId = conversationId;
      });

      if (conversationId != null) {
        print('✅ Chat initialized with conversation ID: $conversationId');
        
        // Informar ao GlobalNotificationService qual chat está ativo
        _globalNotificationService?.setActiveChatScreen(conversationId);
        
        // Marcar mensagens como lidas
        await _firebaseService?.markMessagesAsRead(conversationId, userId);
        print('✅ Chat initialized successfully');
      } else {
        print('❌ Failed to create conversation');
      }

    } catch (e) {
      print('❌ Error initializing chat: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // StreamBuilder para tempo real - MELHORIA IMPLEMENTADA
  Stream<List<ChatMessage>> _messagesStream() {
    if (_conversationId == null) {
      return Stream.value([]);
    }
    
    print('📬 Setting up messages stream for conversation: $_conversationId');
    
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          print('📨 Stream received ${snapshot.docs.length} messages');
          
          final messages = snapshot.docs.map((doc) {
            final data = doc.data();
            
            // Tratar timestamp de forma mais robusta
            DateTime timestamp;
            final timestampData = data['timestamp'];
            if (timestampData is Timestamp) {
              timestamp = timestampData.toDate();
            } else if (timestampData is int) {
              timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
            } else if (timestampData is String) {
              timestamp = DateTime.tryParse(timestampData) ?? DateTime.now();
            } else {
              timestamp = DateTime.now();
            }
            
            return ChatMessage(
              id: doc.id,
              conversationId: _conversationId!,
              senderId: data['senderId'] ?? '',
              receiverId: data['receiverId'] ?? '',
              content: data['content'] ?? '',
              timestamp: timestamp,
              type: MessageType.values.firstWhere(
                (type) => type.toString().split('.').last == data['type'],
                orElse: () => MessageType.text,
              ),
            );
          }).toList();
          
          // Mark as read when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _markConversationAsRead();
            _scrollToBottom();
          });
          
          return messages;
        });
  }

  void _markConversationAsRead() {
    if (_conversationId != null) {
      final conversationsProvider = Provider.of<ConversationsProvider>(context, listen: false);
      conversationsProvider.markConversationAsRead(_conversationId!);
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    print('🚀 Attempting to send message: "$messageText"');
    print('🔍 _conversationId: $_conversationId');
    print('🔍 _isSending: $_isSending');
    
    if (messageText.isEmpty || _isSending || _conversationId == null) {
      print('❌ Cannot send message - empty text, already sending, or no conversation ID');
      return;
    }

    final userId = _authService?.currentUser?.uid;
    if (userId == null) {
      print('❌ No user ID found');
      return;
    }

    print('✅ All conditions met, proceeding to send message');

    setState(() {
      _isSending = true;
    });

    try {
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: _conversationId!,
        senderId: userId,
        receiverId: widget.otherUser.id,
        content: messageText,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      print('📝 Created message object: ${message.id}');
      
      _messageController.clear();
      _scrollToBottom();

      print('🔥 Sending to Firebase...');
      // Enviar para o Firebase
      await _firebaseService?.sendChatMessage(message);
      print('✅ Message sent to Firebase successfully');

    } catch (e) {
      print('❌ Error sending message: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao enviar mensagem. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.gray200,
                  backgroundImage: widget.otherUser.profileImageUrl != null
                      ? NetworkImage(widget.otherUser.profileImageUrl!)
                      : null,
                  child: widget.otherUser.profileImageUrl == null
                      ? const Icon(Icons.person, size: 20, color: AppColors.gray500)
                      : null,
                ),
                if (widget.otherUser.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.otherUser.isOnline 
                        ? 'Online'
                        : _getLastSeenText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.otherUser.isOnline 
                          ? Colors.green 
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
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
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Lista de mensagens com StreamBuilder - MELHORIA IMPLEMENTADA
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _messagesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Erro ao carregar mensagens: ${snapshot.error}'),
                        );
                      }
                      
                      final messages = snapshot.data ?? [];
                      
                      if (messages.isEmpty) {
                        return _buildEmptyState();
                      }
                      
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final showDate = _shouldShowDateHeader(index, messages);
                          
                          return Column(
                            children: [
                              if (showDate) _buildDateHeader(message.timestamp),
                              _buildMessageBubble(message),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Campo de entrada de mensagem
                _buildMessageInput(),
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
            'Carregando conversa...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.gray200,
              backgroundImage: widget.otherUser.profileImageUrl != null
                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                  : null,
              child: widget.otherUser.profileImageUrl == null
                  ? const Icon(Icons.person, size: 40, color: AppColors.gray500)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Conversa com ${widget.otherUser.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vocês ainda não conversaram. Que tal enviar a primeira mensagem?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    String dateText;
    if (difference.inDays == 0) {
      dateText = 'Hoje';
    } else if (difference.inDays == 1) {
      dateText = 'Ontem';
    } else if (difference.inDays < 7) {
      final weekdays = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
      dateText = weekdays[date.weekday % 7];
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.gray300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.gray300)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == _authService?.currentUser?.uid;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.gray200,
              backgroundImage: widget.otherUser.profileImageUrl != null
                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                  : null,
              child: widget.otherUser.profileImageUrl == null
                  ? const Icon(Icons.person, size: 16, color: AppColors.gray500)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
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
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead 
                              ? Icons.done_all 
                              : message.isDelivered 
                                  ? Icons.done_all 
                                  : Icons.done,
                          size: 14,
                          color: message.isRead 
                              ? Colors.blue.shade300
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            UserAvatar(
              imageBytes: _myImageBytes,
              radius: 16,
              useAuthPhoto: true,
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
                    hintText: 'Digite uma mensagem...',
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
                onPressed: _isSending ? null : _sendMessage,
                icon: Icon(
                  _isSending ? Icons.hourglass_empty : Icons.send,
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

  bool _shouldShowDateHeader(int index, List<ChatMessage> messages) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    
    final previousDate = DateTime(
      previousMessage.timestamp.year,
      previousMessage.timestamp.month,
      previousMessage.timestamp.day,
    );
    
    return !currentDate.isAtSameMomentAs(previousDate);
  }

  String _formatMessageTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getLastSeenText() {
    if (widget.otherUser.lastSeen == null) return 'Offline';
    
    final difference = DateTime.now().difference(widget.otherUser.lastSeen!);
    
    if (difference.inMinutes < 1) {
      return 'Visto agora';
    } else if (difference.inHours < 1) {
      return 'Visto há ${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return 'Visto há ${difference.inHours}h';
    } else {
      return 'Visto há ${difference.inDays}d';
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
            Text(
              'Opções da Conversa',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.primary),
              title: const Text('Ver perfil'),
              onTap: () {
                Navigator.pop(context);
                _showUserProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Limpar conversa'),
              onTap: () {
                Navigator.pop(context);
                _confirmClearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Bloquear usuário'),
              onTap: () {
                Navigator.pop(context);
                _confirmBlockUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile() {
    // TODO: Mostrar perfil completo do usuário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar conversa'),
        content: const Text(
          'Tem certeza que deseja limpar todas as mensagens desta conversa? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _confirmBlockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuário'),
        content: Text(
          'Tem certeza que deseja bloquear ${widget.otherUser.name}? '
          'Vocês não poderão mais trocar mensagens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
  }

  void _clearChat() async {
    if (_conversationId == null) return;
    
    try {
      await _firebaseService?.clearConversation(_conversationId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversa limpa com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao limpar conversa'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _blockUser() async {
    final userId = _authService?.currentUser?.uid;
    if (userId == null) return;
    
    try {
      await _firebaseService?.blockUser(userId, widget.otherUser.id);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.otherUser.name} foi bloqueado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao bloquear usuário'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
