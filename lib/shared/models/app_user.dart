enum UserRole { fatherAdmin, motherManager, childLimited }

extension UserRolePermission on UserRole {
  bool get isAdmin => this == UserRole.fatherAdmin;
  bool get isManager => this == UserRole.motherManager;
  bool get isChild => this == UserRole.childLimited;

  bool get canDeleteTransaction => isAdmin || isManager;
  bool get canManageMembers => isAdmin;
  bool get canManageFamilyFinance => isAdmin || isManager;
  bool get canViewReports => !isChild;
  bool get canManageCalendar => !isChild;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.familyId,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String familyId;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Thành viên',
      role: _roleFromString(map['role'] as String?),
      familyId: map['familyId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'role': role.name,
        'familyId': familyId,
      };

  static UserRole _roleFromString(String? value) {
    final role = (value ?? '').trim();
    switch (role) {
      case 'fatherAdmin':
      case 'admin':
        return UserRole.fatherAdmin;
      case 'motherManager':
      case 'manager':
        return UserRole.motherManager;
      case 'childLimited':
      case 'child':
        return UserRole.childLimited;
      default:
        // Fallback an toàn theo yêu cầu migration dữ liệu role cũ.
        return UserRole.fatherAdmin;
    }
  }
}
