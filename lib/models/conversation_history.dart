class ConversationHistory {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? otherUserAvatarBase64;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;
  final bool isOnline;

  ConversationHistory({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  this.otherUserAvatarBase64,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory ConversationHistory.fromFirestore(Map<String, dynamic> data, String currentUserId) {
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    
    final lastMessage = data['lastMessage'] as Map<String, dynamic>?;
    
    return ConversationHistory(
      conversationId: data['id'] ?? '',
      otherUserId: otherUserId,
      otherUserName: data['otherUserName'] ?? 'Usuário',
      otherUserAvatar: data['otherUserAvatar'],
  otherUserAvatarBase64: data['otherUserAvatarBase64'],
      lastMessage: lastMessage?['content'],
      lastMessageTime: lastMessage?['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastMessage!['timestamp'])
          : null,
      lastMessageSenderId: lastMessage?['senderId'],
      unreadCount: data['unreadCount_$currentUserId'] ?? 0,
      isOnline: data['otherUserOnline'] ?? false,
    );
  }

  // Helper para verificar se a última mensagem foi enviada pelo usuário atual
  bool get lastMessageWasSentByMe => lastMessageSenderId != null && lastMessageSenderId != otherUserId;
  
  // Helper para formatar o tempo da última mensagem
  String get formattedLastMessageTime {
    if (lastMessageTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);
    
    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${lastMessageTime!.day}/${lastMessageTime!.month}';
    }
  }
  
  // Helper para preview da última mensagem
  String get lastMessagePreview {
    if (lastMessage == null || lastMessage!.isEmpty) return 'Nenhuma mensagem';
    
    final prefix = lastMessageWasSentByMe ? 'Você: ' : '';
    final maxLength = 50;
    
    if (lastMessage!.length <= maxLength) {
      return '$prefix$lastMessage';
    } else {
      return '$prefix${lastMessage!.substring(0, maxLength)}...';
    }
  }
}
