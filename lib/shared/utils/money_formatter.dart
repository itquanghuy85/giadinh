import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Định dạng tiền tệ Việt Nam theo quy ước hiển thị gọn:
/// - < 1.000đ          → "500đ"
/// - 1.000–999.999đ    → "165.500đ"
/// - 1Tr–999Tr         → "1,5Tr" / "165Tr500" / "999Tr"
/// - ≥ 1 Tỷ            → "1,5 Tỷ" / "2 Tỷ 165Tr"
class MoneyFormatter {
  static final _dot = NumberFormat('#,###', 'vi_VN');

  static String _formatThousands(int value) {
    try {
      return _dot.format(value);
    } catch (_) {
      return value.toString();
    }
  }

  static String format(double amount) {
    if (amount < 0) return '-${format(-amount)}';
    if (amount < 1000) return '${amount.toInt()}đ';

    if (amount < 1000000) {
      return '${_formatThousands(amount.toInt())}đ';
    }

    if (amount < 1000000000) {
      final millions = amount / 1000000;
      final remainder = (amount % 1000000).toInt();
      final roundedK = (remainder ~/ 1000);

      if (remainder == 0) {
        // Nguyên triệu: "1Tr" / "165Tr"
        return '${millions.toInt()}Tr';
      }
      // Có phần lẻ nhỏ dưới 100k → hiển thị dạng "18Tr500"
      if (remainder < 100000 && roundedK > 0) {
        return '${millions.toInt()}Tr${roundedK}';
      }
      // Lẻ lớn → làm tròn 1 chữ số thập phân: "1,5Tr"
      final rounded = (millions * 10).round() / 10;
      if (rounded == rounded.toInt()) {
        return '${rounded.toInt()}Tr';
      }
      final formatted = rounded.toStringAsFixed(1).replaceAll('.', ',');
      return '${formatted}Tr';
    }

    // Từ 1 tỷ trở lên
    final billions = amount / 1000000000;
    final remainderM = ((amount % 1000000000) / 1000000).toInt();

    if (remainderM == 0) {
      final rounded = (billions * 10).round() / 10;
      if (rounded == rounded.toInt()) {
        return '${rounded.toInt()} Tỷ';
      }
      return '${rounded.toStringAsFixed(1).replaceAll('.', ',')} Tỷ';
    }
    return '${billions.toInt()} Tỷ ${remainderM}Tr';
  }

  /// Định dạng đầy đủ (dùng trong báo cáo, không rút gọn)
  static String formatFull(double amount) {
    return '${_formatThousands(amount.toInt())}đ';
  }
}

/// TextInputFormatter hiển thị số có dấu phân cách nghìn khi nhập
/// Trả về text hiển thị dạng "1.500.000" nhưng giữ nguyên con số thực
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('.', '').replaceAll(',', '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    final number = int.tryParse(text);
    if (number == null) return oldValue;

    String formatted;
    try {
      formatted = NumberFormat('#,###', 'vi_VN').format(number);
    } catch (_) {
      formatted = number.toString();
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
