import 'package:cloud_firestore/cloud_firestore.dart';

class ScreenTimeConfig {
  final String id;
  final String familyId;
  final String childId;
  final bool enabled;

  // Daily limit in minutes
  final int dailyLimitMinutes;

  // Bedtime
  final bool bedtimeEnabled;
  final int bedtimeStartHour;
  final int bedtimeStartMinute;
  final int bedtimeEndHour;
  final int bedtimeEndMinute;

  // School time / Downtime
  final bool schoolTimeEnabled;
  final int schoolStartHour;
  final int schoolStartMinute;
  final int schoolEndHour;
  final int schoolEndMinute;
  final List<int> schoolDays; // 1=Mon ... 7=Sun

  // Bonus time
  final int bonusMinutes;
  final DateTime? bonusDate; // Only valid for this date

  final DateTime updatedAt;

  ScreenTimeConfig({
    required this.id,
    required this.familyId,
    required this.childId,
    this.enabled = true,
    this.dailyLimitMinutes = 120,
    this.bedtimeEnabled = true,
    this.bedtimeStartHour = 21,
    this.bedtimeStartMinute = 0,
    this.bedtimeEndHour = 7,
    this.bedtimeEndMinute = 0,
    this.schoolTimeEnabled = false,
    this.schoolStartHour = 7,
    this.schoolStartMinute = 30,
    this.schoolEndHour = 16,
    this.schoolEndMinute = 30,
    this.schoolDays = const [1, 2, 3, 4, 5],
    this.bonusMinutes = 0,
    this.bonusDate,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'childId': childId,
      'enabled': enabled,
      'dailyLimitMinutes': dailyLimitMinutes,
      'bedtimeEnabled': bedtimeEnabled,
      'bedtimeStartHour': bedtimeStartHour,
      'bedtimeStartMinute': bedtimeStartMinute,
      'bedtimeEndHour': bedtimeEndHour,
      'bedtimeEndMinute': bedtimeEndMinute,
      'schoolTimeEnabled': schoolTimeEnabled,
      'schoolStartHour': schoolStartHour,
      'schoolStartMinute': schoolStartMinute,
      'schoolEndHour': schoolEndHour,
      'schoolEndMinute': schoolEndMinute,
      'schoolDays': schoolDays,
      'bonusMinutes': bonusMinutes,
      'bonusDate': bonusDate != null ? Timestamp.fromDate(bonusDate!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ScreenTimeConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScreenTimeConfig(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      childId: data['childId'] ?? '',
      enabled: data['enabled'] ?? true,
      dailyLimitMinutes: data['dailyLimitMinutes'] ?? 120,
      bedtimeEnabled: data['bedtimeEnabled'] ?? true,
      bedtimeStartHour: data['bedtimeStartHour'] ?? 21,
      bedtimeStartMinute: data['bedtimeStartMinute'] ?? 0,
      bedtimeEndHour: data['bedtimeEndHour'] ?? 7,
      bedtimeEndMinute: data['bedtimeEndMinute'] ?? 0,
      schoolTimeEnabled: data['schoolTimeEnabled'] ?? false,
      schoolStartHour: data['schoolStartHour'] ?? 7,
      schoolStartMinute: data['schoolStartMinute'] ?? 30,
      schoolEndHour: data['schoolEndHour'] ?? 16,
      schoolEndMinute: data['schoolEndMinute'] ?? 30,
      schoolDays: List<int>.from(data['schoolDays'] ?? [1, 2, 3, 4, 5]),
      bonusMinutes: data['bonusMinutes'] ?? 0,
      bonusDate: data['bonusDate'] != null
          ? (data['bonusDate'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  ScreenTimeConfig copyWith({
    bool? enabled,
    int? dailyLimitMinutes,
    bool? bedtimeEnabled,
    int? bedtimeStartHour,
    int? bedtimeStartMinute,
    int? bedtimeEndHour,
    int? bedtimeEndMinute,
    bool? schoolTimeEnabled,
    int? schoolStartHour,
    int? schoolStartMinute,
    int? schoolEndHour,
    int? schoolEndMinute,
    List<int>? schoolDays,
    int? bonusMinutes,
    DateTime? bonusDate,
  }) {
    return ScreenTimeConfig(
      id: id,
      familyId: familyId,
      childId: childId,
      enabled: enabled ?? this.enabled,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      bedtimeEnabled: bedtimeEnabled ?? this.bedtimeEnabled,
      bedtimeStartHour: bedtimeStartHour ?? this.bedtimeStartHour,
      bedtimeStartMinute: bedtimeStartMinute ?? this.bedtimeStartMinute,
      bedtimeEndHour: bedtimeEndHour ?? this.bedtimeEndHour,
      bedtimeEndMinute: bedtimeEndMinute ?? this.bedtimeEndMinute,
      schoolTimeEnabled: schoolTimeEnabled ?? this.schoolTimeEnabled,
      schoolStartHour: schoolStartHour ?? this.schoolStartHour,
      schoolStartMinute: schoolStartMinute ?? this.schoolStartMinute,
      schoolEndHour: schoolEndHour ?? this.schoolEndHour,
      schoolEndMinute: schoolEndMinute ?? this.schoolEndMinute,
      schoolDays: schoolDays ?? this.schoolDays,
      bonusMinutes: bonusMinutes ?? this.bonusMinutes,
      bonusDate: bonusDate ?? this.bonusDate,
      updatedAt: DateTime.now(),
    );
  }
}
