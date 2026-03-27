import 'package:cloud_firestore/cloud_firestore.dart';

enum AppCategory { education, social, entertainment, games, tools, other }

class ManagedApp {
  final String packageName;
  final String appName;
  final AppCategory category;
  final bool blocked;
  final int? dailyLimitMinutes; // null = unlimited
  final bool isPriority; // educational priority

  ManagedApp({
    required this.packageName,
    required this.appName,
    this.category = AppCategory.other,
    this.blocked = false,
    this.dailyLimitMinutes,
    this.isPriority = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'category': category.name,
      'blocked': blocked,
      'dailyLimitMinutes': dailyLimitMinutes,
      'isPriority': isPriority,
    };
  }

  factory ManagedApp.fromMap(Map<String, dynamic> data) {
    return ManagedApp(
      packageName: data['packageName'] ?? '',
      appName: data['appName'] ?? '',
      category: AppCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => AppCategory.other,
      ),
      blocked: data['blocked'] ?? false,
      dailyLimitMinutes: data['dailyLimitMinutes'],
      isPriority: data['isPriority'] ?? false,
    );
  }

  ManagedApp copyWith({
    bool? blocked,
    int? dailyLimitMinutes,
    bool? isPriority,
    AppCategory? category,
    bool clearLimit = false,
  }) {
    return ManagedApp(
      packageName: packageName,
      appName: appName,
      category: category ?? this.category,
      blocked: blocked ?? this.blocked,
      dailyLimitMinutes:
          clearLimit ? null : (dailyLimitMinutes ?? this.dailyLimitMinutes),
      isPriority: isPriority ?? this.isPriority,
    );
  }
}

class AppManagementConfig {
  final String id;
  final String familyId;
  final String childId;
  final bool blockNewInstalls;
  final List<ManagedApp> managedApps;
  final DateTime updatedAt;

  AppManagementConfig({
    required this.id,
    required this.familyId,
    required this.childId,
    this.blockNewInstalls = false,
    this.managedApps = const [],
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'childId': childId,
      'blockNewInstalls': blockNewInstalls,
      'managedApps': managedApps.map((a) => a.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppManagementConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppManagementConfig(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      childId: data['childId'] ?? '',
      blockNewInstalls: data['blockNewInstalls'] ?? false,
      managedApps: (data['managedApps'] as List<dynamic>?)
              ?.map((a) => ManagedApp.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  AppManagementConfig copyWith({
    bool? blockNewInstalls,
    List<ManagedApp>? managedApps,
  }) {
    return AppManagementConfig(
      id: id,
      familyId: familyId,
      childId: childId,
      blockNewInstalls: blockNewInstalls ?? this.blockNewInstalls,
      managedApps: managedApps ?? this.managedApps,
      updatedAt: DateTime.now(),
    );
  }
}
