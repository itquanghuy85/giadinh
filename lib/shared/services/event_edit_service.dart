import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/shared/models/family_event.dart';
import 'package:family_finance/shared/services/notification_service.dart';

/// [THÊM MỚI] Service quản lý sự kiện lịch gia đình
class EventEditService {
  EventEditService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Tạo sự kiện mới, return FamilyEvent hoặc null nếu thất bại
  Future<FamilyEvent?> createEvent({
    required String familyId,
    required String title,
    required String assignee,
    required DateTime startAt,
    required String repeat, // none, daily, weekly
    required String colorHex,
    required String eventType, // regular, anniversary, birthday
    String? description,
    required String createdBy,
    bool hasReminder = true,
    int reminderMinutes = 30,
  }) async {
    try {
      final docRef = await _db.collection('families').doc(familyId).collection('events').add({
        'title': title,
        'assignee': assignee,
        'startAt': Timestamp.fromDate(startAt),
        'repeat': repeat,
        'colorHex': colorHex,
        'eventType': eventType,
        'description': description,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'familyId': familyId,
        'hasReminder': hasReminder,
        'reminderMinutes': reminderMinutes,
      });

      if (hasReminder) {
        final remindAt = startAt.subtract(Duration(minutes: reminderMinutes));
        if (remindAt.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleReminder(
            id: _notificationId(docRef.id),
            title: 'Nhắc lịch gia đình',
            body: title,
            scheduled: remindAt,
          );
        }
      }
      
      return FamilyEvent(
        id: docRef.id,
        title: title,
        assignee: assignee,
        startAt: startAt,
        repeat: repeat,
        colorHex: colorHex,
        eventType: eventType,
        description: description,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        familyId: familyId,
        hasReminder: hasReminder,
        reminderMinutes: reminderMinutes,
      );
    } catch (e) {
      throw Exception('Tạo sự kiện thất bại: $e');
    }
  }

  /// Cập nhật sự kiện
  Future<void> updateEvent({
    required String familyId,
    required String eventId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _db
          .collection('families')
          .doc(familyId)
          .collection('events')
          .doc(eventId)
          .update(updates);
    } catch (e) {
      throw Exception('Cập nhật sự kiện thất bại: $e');
    }
  }

  /// Xóa sự kiện
  Future<void> deleteEvent(String familyId, String eventId) async {
    try {
      await NotificationService.instance.cancel(_notificationId(eventId));
      await _db
          .collection('families')
          .doc(familyId)
          .collection('events')
          .doc(eventId)
          .delete();
    } catch (e) {
      throw Exception('Xóa sự kiện thất bại: $e');
    }
  }

  int _notificationId(String eventId) => eventId.hashCode & 0x7fffffff;
}
