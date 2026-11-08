class BoardMember {
  const BoardMember({
    required this.id,
    required this.name,
    this.strikesCount = 0,
    this.hasActiveDispute = false,
    this.disputeRecentlyResolved = false,
  });

  factory BoardMember.fromJson(Map<String, dynamic> json) => BoardMember(
        id: json['id'] as String,
        name: json['full_name'] as String? ?? '',
        strikesCount: json['strikes_count'] as int? ?? 0,
        hasActiveDispute: json['has_active_dispute'] as bool? ?? false,
        disputeRecentlyResolved: json['dispute_recently_resolved'] as bool? ?? false,
      );

  final String id;
  final String name;
  final int strikesCount;
  final bool hasActiveDispute;
  final bool disputeRecentlyResolved;
}

class Contributor {
  const Contributor({
    required this.donorId,
    required this.name,
    required this.status,
    required this.kind,
    this.donationId,
    this.receiverId,
    this.sentAt,
    this.providerUsed,
    this.transactionRef,
    this.hasProof = false,
  });

  factory Contributor.fromJson(Map<String, dynamic> json) => Contributor(
        donorId: json['user_id'] as String,
        name: json['full_name'] as String? ?? '',
        // The donation's status (PENDING_CONFIRMATION, CONFIRMED, DISPUTED), the queue status otherwise
        status: json['donation_status'] as String? ?? json['status'] as String? ?? 'CONFIRMED',
        kind: json['kind'] as String? ?? 'REGULAR',
        donationId: json['donation_id'] as String?,
        receiverId: json['receiver_id'] as String?,
        sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '')?.toUtc(),
        providerUsed: json['provider_used'] as String?,
        transactionRef: json['transaction_ref'] as String?,
        hasProof: (json['proof_image_url'] as String?)?.isNotEmpty ?? false,
      );

  final String donorId;
  final String name;
  final String status;
  final String kind;
  final String? donationId;
  final String? receiverId;
  final DateTime? sentAt;
  final String? providerUsed;
  final String? transactionRef;
  final bool hasProof;

  bool get isConfirmed => status == 'CONFIRMED';
  bool get isPending => status == 'PENDING_CONFIRMATION';

  /// Gifts from the Support cash: shown as the Support team, not as a member.
  bool get isFromSupport => kind == 'SUPPORT_FUNDING' || kind == 'SUPPORT_SLOT' || kind == 'TICKET';
}

class Board {
  const Board({
    required this.levelId,
    required this.levelName,
    required this.amount,
    required this.confirmedCount,
    required this.requiredContributors,
    required this.contributors,
    this.center,
    this.nextInLine,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? object(String key) => json[key] as Map<String, dynamic>?;
    return Board(
      levelId: json['level_id'] as int,
      levelName: json['level_name'] as String? ?? '',
      amount: num.tryParse('${json['amount']}') ?? 0,
      confirmedCount: json['confirmed_count'] as int? ?? 0,
      requiredContributors: json['required_contributors'] as int? ?? 6,
      contributors: (json['contributors'] as List<dynamic>? ?? [])
          .map((item) => Contributor.fromJson(item as Map<String, dynamic>))
          .toList(),
      center: object('center') == null ? null : BoardMember.fromJson(object('center')!),
      nextInLine: object('next_in_line') == null ? null : BoardMember.fromJson(object('next_in_line')!),
    );
  }

  final int levelId;
  final String levelName;
  final num amount;
  final int confirmedCount;
  final int requiredContributors;
  final List<Contributor> contributors;
  final BoardMember? center;
  final BoardMember? nextInLine;

  int get emptySlots => (requiredContributors - contributors.length).clamp(0, requiredContributors);

  bool get centerHasDispute =>
      (center?.hasActiveDispute ?? false) || contributors.any((c) => c.status == 'DISPUTED');

  bool get centerDisputeResolved => !centerHasDispute && (center?.disputeRecentlyResolved ?? false);
}

class QueueEntry {
  const QueueEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.position,
    required this.status,
    required this.receivedCount,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['full_name'] as String? ?? '',
        position: json['queue_position'] as int,
        status: json['status'] as String? ?? 'IN_LINE',
        receivedCount: json['received_count'] as int? ?? 0,
      );

  final String id;
  final String userId;
  final String name;
  final int position;
  final String status;
  final int receivedCount;

  bool get isCenter => position == 1 || status == 'CENTER';
}

class PendingMember {
  const PendingMember({required this.userId, required this.name, required this.stage, required this.referralCount});

  factory PendingMember.fromJson(Map<String, dynamic> json) => PendingMember(
        userId: json['user_id'] as String,
        name: json['full_name'] as String? ?? '',
        stage: json['stage'] as String? ?? 'NEEDS_REFERRALS',
        referralCount: json['referral_count'] as int? ?? 0,
      );

  final String userId;
  final String name;

  /// NEEDS_REFERRALS, AWAITING_PAYMENT or AWAITING_CONFIRMATION
  final String stage;
  final int referralCount;
}
