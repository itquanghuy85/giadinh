import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class LocaleBootstrap {
  const LocaleBootstrap._();

  static Future<void> ensureInitialized() async {
    await initializeDateFormatting('vi_VN');
    await initializeDateFormatting('en_US');
    final system = Intl.systemLocale.toLowerCase();
    Intl.defaultLocale = system.startsWith('en') ? 'en_US' : 'vi_VN';
  }
}
