import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  static const String _appGroupId = 'com.huluca.giadinh';
  static const String _androidWidgetName = 'FamilyWidgetProvider';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidget({
    required String childName,
    required bool isOnline,
    required int batteryLevel,
    String? locationText,
  }) async {
    final now = DateFormat('HH:mm dd/MM').format(DateTime.now());
    final status = isOnline ? 'Online' : 'Offline';

    await Future.wait([
      HomeWidget.saveWidgetData<String>('child_name', childName),
      HomeWidget.saveWidgetData<String>('status', status),
      HomeWidget.saveWidgetData<String>('battery', batteryLevel.toString()),
      HomeWidget.saveWidgetData<String>(
          'location_text', locationText ?? ''),
      HomeWidget.saveWidgetData<String>('last_update', now),
    ]);

    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }

  static Future<void> clearWidget() async {
    await Future.wait([
      HomeWidget.saveWidgetData<String>('child_name', '---'),
      HomeWidget.saveWidgetData<String>('status', 'Offline'),
      HomeWidget.saveWidgetData<String>('battery', '--'),
      HomeWidget.saveWidgetData<String>('location_text', ''),
      HomeWidget.saveWidgetData<String>('last_update', ''),
    ]);

    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }
}
