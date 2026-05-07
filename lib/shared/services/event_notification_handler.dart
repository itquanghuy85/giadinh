import 'package:family_finance/shared/models/family_event.dart';
import 'package:family_finance/shared/services/notification_service.dart';

/// [THÊM MỚI] Xử lý notifications cho sự kiện gia đình
class EventNotificationHandler {
  static Future<void> notifyEventCreated(FamilyEvent event, String creatorName) async {
    final eventTypeLabel = _getEventTypeLabel(event.eventType);
    final title = '📅 $eventTypeLabel mới';
    final body = '${event.title} - do $creatorName tạo';
    
    await NotificationService.instance.showNotification(
      id: event.id.hashCode,
      title: title,
      body: body,
    );
  }

  static String _getEventTypeLabel(String? eventType) {
    switch (eventType) {
      case 'anniversary':
        return 'Kỷ niệm';
      case 'birthday':
        return 'Sinh nhật';
      default:
        return 'Sự kiện';
    }
  }
}
