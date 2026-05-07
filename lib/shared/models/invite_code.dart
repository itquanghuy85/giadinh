/// Model đại diện cho mã mời gia đình
/// Dùng để thành viên mới join vào family
class InviteCode {
  final String id; // Document ID từ Firestore
  final String code; // Mã 6 số
  final String familyId; // Gia đình mà mã này thuộc về
  final String invitedEmail; // Email người được mời
  final String role; // Vai trò: manager, child
  final String createdBy; // uid người tạo mã
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? usedBy; // uid người đã dùng mã
  final DateTime? usedAt;

  InviteCode({
    required this.id,
    required this.code,
    required this.familyId,
    required this.invitedEmail,
    required this.role,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.usedBy,
    this.usedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedBy != null;
  bool get isValid => !isExpired && !isUsed;

  Map<String, dynamic> toMap() => {
        'code': code,
        'familyId': familyId,
        'invitedEmail': invitedEmail,
        'role': role,
        'createdBy': createdBy,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
        'usedBy': usedBy,
        'usedAt': usedAt,
      };

  factory InviteCode.fromMap(String id, Map<String, dynamic> map) {
    return InviteCode(
      id: id,
      code: map['code'] as String? ?? '',
      familyId: map['familyId'] as String? ?? '',
      invitedEmail: map['invitedEmail'] as String? ?? '',
      role: map['role'] as String? ?? 'child',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as dynamic)?.toDate() ?? DateTime.now(),
      usedBy: map['usedBy'] as String?,
      usedAt: (map['usedAt'] as dynamic)?.toDate(),
    );
  }
}
