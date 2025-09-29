import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'dart:async';
import 'dart:typed_data';
import '../widgets/user_avatar.dart';

class ConversationPartner {
  final String id;
  final String name;
  final Uint8List? imageBytes;

  const ConversationPartner({
    required this.id,
    required this.name,
    this.imageBytes,
  });
}

class UserChatScreen extends StatefulWidget {
  final ConversationPartner otherUser;
  
  const UserChatScreen({Key? key, required this.otherUser}) : super(key: key);

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
  
  AuthService? _authService;

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
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (!mounted) return;
    
    try {
      print('💬 Finding conversation between users');
      final currentUserId = _authService?.currentUser?.uid;
      final otherUserId = widget.otherUser.id;
      
      if (currentUserId == null) {
        print('❌ Current user ID is null');
        return;
      }
      
      String conversationId = await _findOrCreateConversation(currentUserId, otherUserId);
      
      if (mounted) {
        setState(() {
          _conversationId = conversationId;
          _isLoading = false;
        });
      }
      
      print('✅ Conversation initialized: $conversationId');
      
      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
    } catch (e) {
      print('❌ Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _findOrCreateConversation(String currentUserId, String otherUserId) async {
    try {
      print('🔍 Looking for existing conversation...');
      
      final conversationsQuery = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .get();
      
      for (var doc in conversationsQuery.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherUserId)) {
          print('✅ Found existing conversation: ${doc.id}');
          return doc.id;
        }
      }
      
      print('📝 Creating new conversation...');
      final conversationRef = FirebaseFirestore.instance.collection('conversations').doc();
      
      await conversationRef.set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
      });
      
      print('✅ Created new conversation: ${conversationRef.id}');
      return conversationRef.id;
      
    } catch (e) {
      print('❌ Error in _findOrCreateConversation: $e');
      rethrow;
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending || _conversationId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUserId = _authService?.currentUser?.uid;
      if (currentUserId == null) return;

      final messageData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': messageText,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      };

      // Add message to conversation's messages subcollection
      final conversationRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId);

      // Garantir que campo updatedAt existe para ordenar corretamente na lista principal
      await conversationRef.collection('messages').add(messageData);

      await conversationRef.update({
        // Estrutura completa usada pelo ConversationsProvider (mantém consistência com firebase_service)
        'lastMessage': {
          'id': messageData['id'],
          'content': messageText,
          'senderId': currentUserId,
          'receiverId': widget.otherUser.id,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
          'isRead': false,
          'isDelivered': true,
        },
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        // Contadores de não lidas: incrementar para o destinatário
        'unreadCount_${widget.otherUser.id}': FieldValue.increment(1),
        // Garantir que meu contador fica zerado
        'unreadCount_$currentUserId': 0,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
      });

      _messageController.clear();
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Send notification to other user
      await _sendNotificationToOtherUser(messageText);

    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao enviar mensagem')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendNotificationToOtherUser(String messageText) async {
    try {
      final senderName = _authService?.currentUser?.displayName ?? 'Usuário';
      // Cria um documento de notificação no Firestore do outro usuário
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUser.id)
          .collection('notifications')
          .add({
        'type': 'message',
        'conversationId': _conversationId ?? '',
        'senderName': senderName,
        'content': messageText,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Widget _buildMessageBubble(DocumentSnapshot messageDoc) {
    final messageData = messageDoc.data() as Map<String, dynamic>;
    final isMe = messageData['senderId'] == _authService?.currentUser?.uid;
    final messageText = messageData['text'] ?? '';
    final messageType = messageData['type'] ?? 'text';
    
    // Handle timestamp
    DateTime? messageTime;
    final timestampData = messageData['timestamp'];
    
    if (timestampData != null) {
      if (timestampData is Timestamp) {
        messageTime = timestampData.toDate();
      } else if (timestampData is int) {
        messageTime = DateTime.fromMillisecondsSinceEpoch(timestampData);
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            UserAvatar(
              imageBytes: widget.otherUser.imageBytes,
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.gray100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: messageType == 'text' 
                    ? Text(
                        messageText,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
                if (messageTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const UserAvatar(
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        title: Row(
          children: [
            UserAvatar(
              imageBytes: widget.otherUser.imageBytes,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUser.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _conversationId == null
                ? const Center(child: Text('Erro ao carregar conversa'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(_conversationId)
                        .collection('messages')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhuma mensagem ainda.\nEnvie a primeira mensagem!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.gray500,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(messages[index]);
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.gray200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocus,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        hintStyle: TextStyle(color: AppColors.gray500),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
