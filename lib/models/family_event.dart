import 'package:cloud_firestore/cloud_firestore.dart';

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
    };
  }
}
