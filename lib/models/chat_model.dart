import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat conversation between users.
/// Consolidated from chat_model.dart and chat_models.dart into a single canonical model.
class ChatConversation {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final DateTime createdAt;
  final bool isGroup;
  final String? groupName;
  final String? groupImage;
  final Map<String, bool> unreadStatus;

  // Product-related fields for marketplace context
  final String? productId;
  final String? productName;
  final String? productImage;
  final double? productPrice;

  // Backwards-compatibility / UI-friendly fields (made non-nullable with defaults)
  final String? otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final bool isOnline;

  // optional compatibility fields (kept private internally)
  final int? _unreadCountField;
  final DateTime? _lastMessageTimeField;

  const ChatConversation({
    required this.id,
    List<String>? participantIds,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    required this.createdAt,
    this.isGroup = false,
    this.groupName,
    this.groupImage,
    Map<String, bool>? unreadStatus,
    this.productId,
    this.productName,
    this.productImage,
    this.productPrice,
    // compatibility params:
    this.otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    bool? isOnline,
    int? unreadCount,
    DateTime? lastMessageTime,
  })  : participantIds = participantIds ?? const [],
        unreadStatus = unreadStatus ?? const {},
        otherUserName = otherUserName ?? '',
        otherUserAvatar = otherUserAvatar ?? '',
        isOnline = isOnline ?? false,
        _unreadCountField = unreadCount,
        _lastMessageTimeField = lastMessageTime;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: (json['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroup: json['isGroup'] as bool? ?? false,
      groupName: json['groupName'] as String?,
      groupImage: json['groupImage'] as String?,
      unreadStatus: (json['unreadStatus'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          const {},
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      productImage: json['productImage'] as String?,
      productPrice: (json['productPrice'] as num?)?.toDouble(),
      // compatibility keys
      otherUserId: json['otherUserId'] as String?,
      otherUserName: json['otherUserName'] as String? ?? '',
      otherUserAvatar: json['otherUserAvatar'] as String? ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int?,
      lastMessageTime: (json['lastMessageTime'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImage': groupImage,
      'unreadStatus': unreadStatus,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      // compatibility keys
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserAvatar': otherUserAvatar,
      'isOnline': isOnline,
      'unreadCount': _unreadCountField,
      'lastMessageTime':
          _lastMessageTimeField != null ? Timestamp.fromDate(_lastMessageTimeField!) : null,
    };
  }

  ChatConversation copyWith({
    String? id,
    List<String>? participantIds,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    DateTime? createdAt,
    bool? isGroup,
    String? groupName,
    String? groupImage,
    Map<String, bool>? unreadStatus,
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    // compatibility params
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    bool? isOnline,
    int? unreadCount,
    DateTime? lastMessageTime,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      createdAt: createdAt ?? this.createdAt,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupImage: groupImage ?? this.groupImage,
      unreadStatus: unreadStatus ?? this.unreadStatus,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      isOnline: isOnline ?? this.isOnline,
      unreadCount: unreadCount ?? _unreadCountField,
      lastMessageTime: lastMessageTime ?? _lastMessageTimeField,
    );
  }

  /// Return true if the conversation is unread by given user id (uses unreadStatus map).
  bool isUnreadBy(String userId) => unreadStatus[userId] ?? false;

  /// Compatibility getter expected by older UI code: unreadCount (int)
  int get unreadCount => _unreadCountField ?? unreadStatus.values.where((v) => v == true).length;

  /// Compatibility getter expected by older UI code: lastMessageTime
  /// Return non-null DateTime so older call-sites that expect DateTime compile.
  DateTime get lastMessageTime => _lastMessageTimeField ?? lastMessageAt ?? createdAt;

  @override
  String toString() =>
      'ChatConversation(id: $id, participants: $participantIds, product: $productName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatConversation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a single message within a chat conversation.
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.mediaUrl,
    required this.sentAt,
    this.isRead = false,
    this.readAt,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      mediaUrl: json['mediaUrl'] as String?,
      sentAt: (json['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      readAt: (json['readAt'] as Timestamp?)?.toDate(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    MessageType? type,
    String? mediaUrl,
    DateTime? sentAt,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'ChatMessage(id: $id, sender: $senderId, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatMessage && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum MessageType { text, image, video, audio, file, product, location }
