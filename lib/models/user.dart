class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.inviteCode,
    required this.referralCount,
    required this.isAdmin,
    required this.isOwner,
    required this.emailVerified,
    required this.strikesCount,
    this.username,
    this.sponsorId,
    this.firstName,
    this.lastName,
    this.country,
    this.memberSince,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        whatsapp: json['whatsapp'] as String? ?? '',
        inviteCode: json['invite_code'] as String? ?? '',
        referralCount: json['referral_count'] as int? ?? 0,
        isAdmin: json['is_admin'] as bool? ?? false,
        isOwner: json['is_owner'] as bool? ?? false,
        emailVerified: json['email_verified'] as bool? ?? false,
        strikesCount: json['strikes_count'] as int? ?? 0,
        username: json['username'] as String?,
        sponsorId: json['sponsor_id'] as String?,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        country: json['country'] as String?,
        memberSince: json['member_since'] as String?,
      );

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String whatsapp;
  final String inviteCode;
  final int referralCount;
  final bool isAdmin;
  final bool isOwner;
  final bool emailVerified;
  final int strikesCount;
  final String? username;
  final String? sponsorId;
  final String? firstName;
  final String? lastName;
  final String? country;
  final String? memberSince;

  /// Only administrators and the owner change their first and last name (the server checks it too).
  bool get canEditName => isAdmin || isOwner;

  /// Same rule as useAuth.ts on the website.
  bool get isQualified => isAdmin || referralCount >= 2;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p[0]).join();
    return letters.toUpperCase();
  }
}
