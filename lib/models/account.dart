class PaymentMethod {
  const PaymentMethod({required this.id, required this.providerType, required this.details});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: json['id'] as String,
        providerType: json['provider_type'] as String? ?? '',
        details: (json['details'] as Map<String, dynamic>? ?? {}).map((key, value) => MapEntry(key, '$value')),
      );

  final String id;

  /// ZELLE, CASHAPP, BANK or VIRTUAL_CURRENCY (MONCASH / NATCASH: retired, kept for old records)
  final String providerType;
  final Map<String, String> details;
}

class BoardHistoryItem {
  const BoardHistoryItem({
    required this.cycleId,
    required this.levelId,
    required this.levelName,
    required this.amount,
    required this.status,
    required this.receivedCount,
    required this.requiredContributors,
    this.queuePosition,
  });

  factory BoardHistoryItem.fromJson(Map<String, dynamic> json) => BoardHistoryItem(
        cycleId: json['cycle_id'] as String,
        levelId: json['level_id'] as int? ?? 1,
        levelName: json['level_name'] as String? ?? '',
        amount: num.tryParse('${json['amount']}') ?? 0,
        status: json['status'] as String? ?? 'IN_LINE',
        receivedCount: json['received_count'] as int? ?? 0,
        requiredContributors: json['required_contributors'] as int? ?? 6,
        queuePosition: json['queue_position'] as int?,
      );

  final String cycleId;
  final int levelId;
  final String levelName;
  final num amount;

  /// COMPLETED, CENTER, WAITING or IN_LINE
  final String status;
  final int receivedCount;
  final int requiredContributors;
  final int? queuePosition;

  bool get isDone => status == 'COMPLETED';
}

class LegalAcceptance {
  const LegalAcceptance({
    required this.id,
    required this.documentType,
    required this.documentVersion,
    required this.acceptedAt,
    required this.context,
    required this.signerName,
    required this.signerEmail,
    this.ipAddress,
  });

  factory LegalAcceptance.fromJson(Map<String, dynamic> json) => LegalAcceptance(
        id: json['id'] as String,
        documentType: json['document_type'] as String? ?? 'TERMS',
        documentVersion: json['document_version'] as String? ?? '',
        acceptedAt: json['accepted_at'] as String,
        context: json['context'] as String? ?? 'UPDATE',
        signerName: json['signer_name'] as String? ?? '',
        signerEmail: json['signer_email'] as String? ?? '',
        ipAddress: json['ip_address'] as String?,
      );

  final String id;
  final String documentType;
  final String documentVersion;
  final String acceptedAt;
  final String context;
  final String signerName;
  final String signerEmail;
  final String? ipAddress;
}
