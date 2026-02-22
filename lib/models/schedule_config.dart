import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleConfig {
  final String id;
  final String familyId;
  final bool isEnabled;
  final int schoolStartHour; // 6
  final int schoolStartMinute; // 0
  final int schoolEndHour; // 18
  final int schoolEndMinute; // 0
  final List<int> schoolDays; // 1=Mon, 7=Sun
  final int schoolIntervalSeconds; // 20
  final int offHoursIntervalSeconds; // 180 (3 min)

  ScheduleConfig({
    required this.id,
    required this.familyId,
    this.isEnabled = false,
    this.schoolStartHour = 6,
    this.schoolStartMinute = 0,
    this.schoolEndHour = 18,
    this.schoolEndMinute = 0,
    this.schoolDays = const [1, 2, 3, 4, 5], // Mon-Fri
    this.schoolIntervalSeconds = 20,
    this.offHoursIntervalSeconds = 180,
  });

  factory ScheduleConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleConfig(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      isEnabled: data['isEnabled'] ?? false,
      schoolStartHour: data['schoolStartHour'] ?? 6,
      schoolStartMinute: data['schoolStartMinute'] ?? 0,
      schoolEndHour: data['schoolEndHour'] ?? 18,
      schoolEndMinute: data['schoolEndMinute'] ?? 0,
      schoolDays: List<int>.from(data['schoolDays'] ?? [1, 2, 3, 4, 5]),
      schoolIntervalSeconds: data['schoolIntervalSeconds'] ?? 20,
      offHoursIntervalSeconds: data['offHoursIntervalSeconds'] ?? 180,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'isEnabled': isEnabled,
      'schoolStartHour': schoolStartHour,
      'schoolStartMinute': schoolStartMinute,
      'schoolEndHour': schoolEndHour,
      'schoolEndMinute': schoolEndMinute,
      'schoolDays': schoolDays,
      'schoolIntervalSeconds': schoolIntervalSeconds,
      'offHoursIntervalSeconds': offHoursIntervalSeconds,
    };
  }

  bool isSchoolTime(DateTime now) {
    if (!isEnabled) return true; // If not enabled, always use school interval
    if (!schoolDays.contains(now.weekday)) return false;

    final schoolStart = now.copyWith(
        hour: schoolStartHour, minute: schoolStartMinute, second: 0);
    final schoolEnd =
        now.copyWith(hour: schoolEndHour, minute: schoolEndMinute, second: 0);

    return now.isAfter(schoolStart) && now.isBefore(schoolEnd);
  }

  int get currentIntervalSeconds {
    final now = DateTime.now();
    return isSchoolTime(now) ? schoolIntervalSeconds : offHoursIntervalSeconds;
  }

  ScheduleConfig copyWith({
    String? id,
    String? familyId,
    bool? isEnabled,
    int? schoolStartHour,
    int? schoolStartMinute,
    int? schoolEndHour,
    int? schoolEndMinute,
    List<int>? schoolDays,
    int? schoolIntervalSeconds,
    int? offHoursIntervalSeconds,
  }) {
    return ScheduleConfig(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      isEnabled: isEnabled ?? this.isEnabled,
      schoolStartHour: schoolStartHour ?? this.schoolStartHour,
      schoolStartMinute: schoolStartMinute ?? this.schoolStartMinute,
      schoolEndHour: schoolEndHour ?? this.schoolEndHour,
      schoolEndMinute: schoolEndMinute ?? this.schoolEndMinute,
      schoolDays: schoolDays ?? this.schoolDays,
      schoolIntervalSeconds:
          schoolIntervalSeconds ?? this.schoolIntervalSeconds,
      offHoursIntervalSeconds:
          offHoursIntervalSeconds ?? this.offHoursIntervalSeconds,
    );
  }
}
