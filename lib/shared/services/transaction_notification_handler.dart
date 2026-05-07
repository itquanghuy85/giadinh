import 'package:family_finance/shared/models/transaction.dart';
import 'package:family_finance/shared/services/notification_service.dart';

/// [THÊM MỚI] Xử lý notifications cho giao dịch
class TransactionNotificationHandler {
  static Future<void> notifyLargeTransaction(TransactionModel transaction, String familyMemberName) async {
    const thresholdVND = 500000;
    
    if (transaction.amount < thresholdVND) return;
    
    final title = '💰 Giao dịch lớn';
    final typeLabel = transaction.type == TransactionType.expense ? 'Chi' : 'Thu';
    final body = '$typeLabel ${transaction.category}: ${formatCurrency(transaction.amount)} từ $familyMemberName';
    
    await NotificationService.instance.showNotification(
      id: transaction.id.hashCode,
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
