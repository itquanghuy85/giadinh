import 'package:family_finance/shared/models/anniversary.dart';
import 'package:family_finance/shared/services/notification_service.dart';
import 'package:intl/intl.dart';

/// [THÊM MỚI] Xử lý notifications cho kỷ niệm nhắc nhở
class AnniversaryReminderHandler {
  /// Tạo reminder 3 ngày trước kỷ niệm
  static Future<void> scheduleReminder(Anniversary anniversary) async {
    final reminderDate = anniversary.date.subtract(const Duration(days: 3));
    
    if (reminderDate.isBefore(DateTime.now())) {
      return; // Không schedule nếu ngày đã qua
    }

    final title = '🎂 Nhắc nhở kỷ niệm';
    final body = '${anniversary.title} sắp tới trong 3 ngày - ${DateFormat('dd/MM/yyyy').format(anniversary.date)}';
    
    await NotificationService.instance.scheduleReminder(
      id: anniversary.id.hashCode,
      title: title,
      body: body,
      scheduled: reminderDate,
    );
  }

  /// Gửi notification vào đúng ngày kỷ niệm
  static Future<void> notifyOnDay(Anniversary anniversary) async {
    final notificationDate = anniversary.date.copyWith(hour: 9, minute: 0);
    
    if (notificationDate.isBefore(DateTime.now())) {
      return;
    }

    final title = '🎉 Hôm nay là ${_getType(anniversary.type)}!';
    final body = anniversary.title;
    
    await NotificationService.instance.scheduleReminder(
      id: (anniversary.id.hashCode + 1000),
      title: title,
      body: body,
      scheduled: notificationDate,
    );
  }

  static String _getType(String type) {
    switch (type) {
      case 'wedding':
        return 'ngày cưới';
      case 'birthday':
        return 'sinh nhật';
      default:
        return 'kỷ niệm';
    }
  }
}
