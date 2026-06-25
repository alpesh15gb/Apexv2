class NotificationModel {
  final String id;
  final String tenantId;
  final String userId;
  final String title;
  final String message;
  final String notificationType;
  final String? channel;
  final String status;
  final DateTime? sentAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.channel,
    required this.status,
    this.sentAt,
    this.readAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType: json['notification_type'] as String,
      channel: json['channel'] as String?,
      status: json['status'] as String? ?? 'unread',
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      metadata: json['metadata_'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'user_id': userId,
      'title': title,
      'message': message,
      'notification_type': notificationType,
      'channel': channel,
      'status': status,
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'metadata_': metadata,
    };
  }
}
