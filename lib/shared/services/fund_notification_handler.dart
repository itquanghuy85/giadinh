import 'package:family_finance/shared/models/fund.dart' show FundModel;
import 'package:family_finance/shared/services/notification_service.dart';

/// [THÊM MỚI] Xử lý notifications cho quỹ đạt mục tiêu
class FundNotificationHandler {
  static Future<void> notifyGoalReached(FundModel fund) async {
    final title = '🎉 Mục tiêu đạt được!';
    final body = '${fund.name} đã đạt mục tiêu: ${formatCurrency(fund.currentAmount)} / ${formatCurrency(fund.targetAmount)}';
    
    await NotificationService.instance.showNotification(
      id: fund.id.hashCode,
      title: title,
      body: body,
    );
  }

  static String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K đ';
    }
    return '${amount.toStringAsFixed(0)} đ';
  }
}
