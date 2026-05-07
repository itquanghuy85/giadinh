import 'package:cloud_firestore/cloud_firestore.dart';

/// [SỬA] Cập nhật model FamilyEvent thêm type, description, createdBy
class FamilyEvent {
  const FamilyEvent({
    required this.id,
    required this.title,
    required this.assignee,
    required this.startAt,
    required this.repeat,
    required this.colorHex,
    this.eventType = 'regular', // regular, anniversary, birthday
    this.description,
    this.createdBy,
    this.createdAt,
    this.familyId,
    this.hasReminder = true,
    this.reminderMinutes = 30,
  });

  final String id;
  final String title;
  final String assignee;
  final DateTime startAt;
  final String repeat; // none, daily, weekly
  final String colorHex;
  final String eventType;
  final String? description;
  final String? createdBy;
  final DateTime? createdAt;
  final String? familyId;
  final bool hasReminder;
  final int reminderMinutes;

  factory FamilyEvent.fromMap(String id, Map<String, dynamic> map) {
    return FamilyEvent(
      id: id,
      title: map['title'] as String? ?? '',
      assignee: map['assignee'] as String? ?? '',
      startAt: (map['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repeat: map['repeat'] as String? ?? 'none',
      colorHex: map['colorHex'] as String? ?? 'FF534AB7',
      eventType: map['eventType'] as String? ?? 'regular',
      description: map['description'] as String?,
      createdBy: map['createdBy'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      familyId: map['familyId'] as String?,
      hasReminder: map['hasReminder'] as bool? ?? true,
      reminderMinutes: (map['reminderMinutes'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'assignee': assignee,
        'startAt': Timestamp.fromDate(startAt),
        'repeat': repeat,
        'colorHex': colorHex,
        'eventType': eventType,
        'description': description,
        'createdBy': createdBy,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'familyId': familyId,
        'hasReminder': hasReminder,
        'reminderMinutes': reminderMinutes,
      };
}
