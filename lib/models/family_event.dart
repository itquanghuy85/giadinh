import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum RepeatType { none, daily, weekly }

class FamilyEvent {
  final String id;
  final String familyId;
  final String title;
  final String? location;
  final DateTime eventTime;
  final String createdBy;
  final DateTime createdAt;
  final bool notified; // Legacy field for backward compatibility
  final List<int> remindedAtMinutes; // e.g. [60, 15, 5]
  final RepeatType repeatType;
  final List<int> repeatDays; // 1=Mon, 2=Tue, ..., 7=Sun (for weekly)

  FamilyEvent({
    required this.id,
    required this.familyId,
    required this.title,
    this.location,
    required this.eventTime,
    required this.createdBy,
    required this.createdAt,
    this.notified = false,
    this.remindedAtMinutes = const [],
    this.repeatType = RepeatType.none,
    this.repeatDays = const [],
  });

  factory FamilyEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawReminded = data['remindedAtMinutes'];
    final reminded = rawReminded is Iterable
        ? rawReminded
            .map((e) => int.tryParse(e.toString()) ?? -1)
            .where((e) => e >= 0)
            .toList()
        : <int>[];

    final legacyNotified = data['notified'] ?? false;
    if (legacyNotified == true && !reminded.contains(15)) {
      reminded.add(15);
    }

    final repeatStr = data['repeatType'] as String? ?? 'none';
    final repeatType = RepeatType.values.firstWhere(
      (e) => e.name == repeatStr,
      orElse: () => RepeatType.none,
    );

    final rawRepeatDays = data['repeatDays'];
    final repeatDays = rawRepeatDays is Iterable
        ? rawRepeatDays
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e >= 1 && e <= 7)
            .toList()
        : <int>[];

    return FamilyEvent(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      title: data['title'] ?? '',
      location: data['location'],
      eventTime: data['eventTime'] != null
          ? (data['eventTime'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      notified: legacyNotified,
      remindedAtMinutes: reminded,
      repeatType: repeatType,
      repeatDays: repeatDays,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'title': title,
      'location': location,
      'eventTime': Timestamp.fromDate(eventTime),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'notified': notified || remindedAtMinutes.contains(15),
      'remindedAtMinutes': remindedAtMinutes,
      'repeatType': repeatType.name,
      'repeatDays': repeatDays,
    };
  }

  /// Generate recurring event instances for the given date range.
  List<FamilyEvent> generateOccurrences(DateTime from, DateTime to) {
    if (repeatType == RepeatType.none) return [this];
    final instances = <FamilyEvent>[];
    final baseTime = TimeOfDay(hour: eventTime.hour, minute: eventTime.minute);

    DateTime cursor = from;
    while (!cursor.isAfter(to)) {
      bool match = false;
      if (repeatType == RepeatType.daily) {
        match = true;
      } else if (repeatType == RepeatType.weekly) {
        // DateTime.weekday: 1=Mon, 7=Sun — same as our repeatDays
        match = repeatDays.contains(cursor.weekday);
      }

      if (match) {
        final dt = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          baseTime.hour,
          baseTime.minute,
        );
        if (!dt.isBefore(from) && !dt.isAfter(to)) {
          instances.add(FamilyEvent(
            id: '$id-${dt.millisecondsSinceEpoch}',
            familyId: familyId,
            title: title,
            location: location,
            eventTime: dt,
            createdBy: createdBy,
            createdAt: createdAt,
            remindedAtMinutes: remindedAtMinutes,
            repeatType: repeatType,
            repeatDays: repeatDays,
          ));
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return instances;
  }
}
