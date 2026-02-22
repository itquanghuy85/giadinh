import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { parent, child }

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final String? familyId;
  final double batteryLevel;
  final bool isOnline;
  final DateTime? lastActive;
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.familyId,
    this.batteryLevel = 100,
    this.isOnline = false,
    this.lastActive,
    this.fcmToken,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'] == 'parent' ? UserRole.parent : UserRole.child,
      familyId: data['familyId'],
      batteryLevel: (data['batteryLevel'] ?? 100).toDouble(),
      isOnline: data['isOnline'] ?? false,
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role == UserRole.parent ? 'parent' : 'child',
      'familyId': familyId,
      'batteryLevel': batteryLevel,
      'isOnline': isOnline,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : FieldValue.serverTimestamp(),
      'fcmToken': fcmToken,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    String? familyId,
    double? batteryLevel,
    bool? isOnline,
    DateTime? lastActive,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  bool get isParent => role == UserRole.parent;
  bool get isChild => role == UserRole.child;
}
