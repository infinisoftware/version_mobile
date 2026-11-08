class Level {
  const Level({
    required this.id,
    required this.name,
    required this.amount,
    required this.requiredContributors,
    required this.displayOrder,
    this.userStatus,
    this.receivedCount,
    this.queuePosition,
  });

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        id: json['id'] as int,
        name: json['name'] as String,
        // The API sends decimals as text
        amount: num.tryParse('${json['amount']}') ?? 0,
        requiredContributors: json['required_contributors'] as int? ?? 6,
        displayOrder: json['display_order'] as int? ?? json['id'] as int,
        userStatus: json['user_status'] as String?,
        receivedCount: json['received_count'] as int?,
        queuePosition: json['queue_position'] as int?,
      );

  final int id;
  final String name;
  final num amount;
  final int requiredContributors;
  final int displayOrder;
  final String? userStatus;
  final int? receivedCount;
  final int? queuePosition;

  bool get isCenter => userStatus == 'CENTER';
  bool get isInLine => userStatus == 'IN_LINE';
  bool get isCompleted => userStatus == 'COMPLETED';
  bool get isActive => isCenter || isInLine;

  /// 6 gifts per cycle: 5 to the Center, the 2nd one to the Support team.
  int get centerGifts => requiredContributors - 1;
  num get centerPayout => amount * centerGifts;
  int get received => (receivedCount ?? 0).clamp(0, requiredContributors);

  bool isLocked({required bool qualified}) {
    if (displayOrder == 1) return false;
    return !qualified || userStatus == 'LOCKED';
  }
}
