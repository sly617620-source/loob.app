// lib/models/chat_models.dart
class ChatConversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  // Added product related optional fields (nullable)
  final String? productId;
  final String? productName;
  final String? productImage;

  ChatConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.productId,
    this.productName,
    this.productImage,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) => ChatConversation(
        id: json['id'] as String,
        otherUserId: json['otherUserId'] as String,
        otherUserName: json['otherUserName'] as String,
        otherUserAvatar: json['otherUserAvatar'] as String?,
        lastMessage: json['lastMessage'] as String? ?? '',
        lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
        unreadCount: (json['unreadCount'] as int?) ?? 0,
        isOnline: (json['isOnline'] as bool?) ?? false,
        productId: json['productId'] as String?,
        productName: json['productName'] as String?,
        productImage: json['productImage'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'otherUserAvatar': otherUserAvatar,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime.toIso8601String(),
        'unreadCount': unreadCount,
        'isOnline': isOnline,
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
      };
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentType;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.attachmentType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        receiverId: json['receiverId'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['isRead'] as bool? ?? false,
        attachmentUrl: json['attachmentUrl'] as String?,
        attachmentType: json['attachmentType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'attachmentUrl': attachmentUrl,
        'attachmentType': attachmentType,
      };
}
