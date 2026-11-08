class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.messagesCount,
    this.lastMessagePreview,
    this.assignedToName,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        category: json['category'] as String? ?? 'QUESTION_GENERALE',
        subject: json['subject'] as String? ?? '',
        priority: json['priority'] as String? ?? 'NORMALE',
        status: json['status'] as String? ?? 'OPEN',
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String? ?? json['created_at'] as String,
        messagesCount: json['messages_count'] as int? ?? 0,
        lastMessagePreview: json['last_message_preview'] as String?,
        assignedToName: json['assigned_to_name'] as String?,
      );

  final String id;
  final String category;
  final String subject;
  final String priority;

  /// OPEN, ANSWERED or CLOSED
  final String status;
  final String createdAt;
  final String updatedAt;
  final int messagesCount;
  final String? lastMessagePreview;
  final String? assignedToName;

  bool get isClosed => status == 'CLOSED';
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.senderId,
    this.attachmentUrl,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: json['id'] as String,
        senderId: json['sender_id'] as String?,
        senderName: json['sender_name'] as String? ?? '',
        senderRole: json['sender_role'] as String? ?? 'MEMBER',
        message: json['message'] as String? ?? '',
        attachmentUrl: json['attachment_url'] as String?,
        createdAt: json['created_at'] as String,
      );

  final String id;
  final String? senderId;
  final String senderName;

  /// MEMBER, or the Support team
  final String senderRole;
  final String message;
  final String? attachmentUrl;
  final String createdAt;

  bool get isFromSupport => senderRole != 'MEMBER';
}
