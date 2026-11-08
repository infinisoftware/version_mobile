/// A gift with its conversation between the donor, the receiver and a moderator.
class SupportCase {
  const SupportCase({
    required this.id,
    required this.levelId,
    required this.levelName,
    required this.donorId,
    required this.donorName,
    required this.receiverId,
    required this.receiverName,
    required this.amount,
    required this.providerUsed,
    required this.status,
    required this.sentAt,
    required this.messagesCount,
    required this.unreadCount,
    required this.kind,
    this.remainingSeconds,
    this.isSlaExpired = false,
    this.proofImageUrl,
  });

  factory SupportCase.fromJson(Map<String, dynamic> json) => SupportCase(
        id: json['id'] as String,
        levelId: json['level_id'] as int? ?? 1,
        levelName: json['level_name'] as String? ?? '',
        donorId: json['donor_id'] as String? ?? '',
        donorName: json['donor_name'] as String? ?? '',
        receiverId: json['receiver_id'] as String? ?? '',
        receiverName: json['receiver_name'] as String? ?? '',
        amount: num.tryParse('${json['amount']}') ?? 0,
        providerUsed: json['provider_used'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING_CONFIRMATION',
        sentAt: json['sent_at'] as String,
        messagesCount: json['messages_count'] as int? ?? 0,
        unreadCount: json['unread_count'] as int? ?? 0,
        kind: json['kind'] as String? ?? 'REGULAR',
        remainingSeconds: json['remaining_seconds'] as int?,
        isSlaExpired: json['is_sla_expired'] as bool? ?? false,
        proofImageUrl: json['proof_image_url'] as String?,
      );

  final String id;
  final int levelId;
  final String levelName;
  final String donorId;
  final String donorName;
  final String receiverId;
  final String receiverName;
  final num amount;
  final String providerUsed;

  /// PENDING_CONFIRMATION, DISPUTED, CONFIRMED or REJECTED
  final String status;
  final String sentAt;
  final int messagesCount;
  final int unreadCount;
  final String kind;
  final int? remainingSeconds;
  final bool isSlaExpired;
  final String? proofImageUrl;

  bool get isOpen => status == 'PENDING_CONFIRMATION' || status == 'DISPUTED';
  bool get isDisputed => status == 'DISPUTED';

  /// Disputes first, then gifts waiting for confirmation (same order as the website).
  int get priority => switch (status) {
        'DISPUTED' => 3,
        'PENDING_CONFIRMATION' => 2,
        _ => 1,
      };
}

class DisputeMessage {
  const DisputeMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.senderId,
    this.attachmentUrl,
  });

  factory DisputeMessage.fromJson(Map<String, dynamic> json) => DisputeMessage(
        id: json['id'] as String,
        senderId: json['sender_id'] as String?,
        senderName: json['sender_name'] as String? ?? '',
        senderRole: json['sender_role'] as String? ?? 'SYSTEM',
        message: json['message'] as String? ?? '',
        attachmentUrl: json['attachment_url'] as String?,
        createdAt: json['created_at'] as String,
      );

  final String id;
  final String? senderId;
  final String senderName;

  /// DONOR, RECEIVER, MODERATOR or SYSTEM
  final String senderRole;
  final String message;
  final String? attachmentUrl;
  final String createdAt;
}
