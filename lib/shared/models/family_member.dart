class FamilyMember {
  const FamilyMember({
    required this.uid,
    required this.name,
    required this.role,
    required this.balance,
  });

  final String uid;
  final String name;
  final String role;
  final double balance;

  factory FamilyMember.fromMap(String uid, Map<String, dynamic> map) {
    return FamilyMember(
      uid: uid,
      name: map['name'] as String? ?? 'Thành viên',
      role: map['role'] as String? ?? 'child',
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'balance': balance,
      };
}
