enum NotificationType {
  message,
  order,
  system,
  submission,
  payment,
  campaign,
  approval,
  sale,
  review
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? targetId;
  final int colorValue;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.targetId,
    this.colorValue = 0xFFD4AF37,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? targetId,
    int? colorValue,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      targetId: targetId ?? this.targetId,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.values.firstWhere(
        (e) => e.index == (json['type'] as int? ?? 0),
        orElse: () => NotificationType.system,
      ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
        targetId: json['targetId'] as String?,
        colorValue: json['colorValue'] as int? ?? 0xFFD4AF37,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.index,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'targetId': targetId,
        'colorValue': colorValue,
      };
}
