class Conversation {
  final String id;
  final String userId1;
  final String userId2;
  final ChatUser otherUser;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isArchived;
  final bool isBlocked;

  Conversation({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.otherUser,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isBlocked = false,
  });

  factory Conversation.fromFirestore(Map<String, dynamic> data, String id) {
    return Conversation(
      id: id,
      userId1: data['userId1'] ?? '',
      userId2: data['userId2'] ?? '',
      otherUser: ChatUser.fromFirestore(data['otherUser'] ?? {}),
      lastMessage: data['lastMessage'] != null 
          ? ChatMessage.fromFirestore(data['lastMessage'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
      unreadCount: data['unreadCount'] ?? 0,
      isArchived: data['isArchived'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'otherUser': otherUser.toFirestore(),
      'lastMessage': lastMessage?.toFirestore(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'isArchived': isArchived,
      'isBlocked': isBlocked,
    };
  }
}

class ChatUser {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String? profileImageBase64;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUser({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.profileImageBase64,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromFirestore(Map<String, dynamic> data) {
    return ChatUser(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Usuário',
      profileImageUrl: data['profileImageUrl'],
      profileImageBase64: data['profileImageBase64'],
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'profileImageBase64': profileImageBase64,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
    };
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.metadata,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'] ?? '',
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (type) => type.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      isRead: data['isRead'] ?? false,
      isDelivered: data['isDelivered'] ?? false,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isDelivered,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum MessageType {
  text,
  image,
  audio,
  video,
  file,
  location,
  system,
}

// Classe para notificações de mensagens
class MessageNotification {
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;

  MessageNotification({
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
  });

  factory MessageNotification.fromFirestore(Map<String, dynamic> data) {
    return MessageNotification(
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
