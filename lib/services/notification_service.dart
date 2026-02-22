import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Create notification channels
    await _createNotificationChannels();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.sosChannelId,
          AppConstants.sosChannelName,
          description: 'SOS emergency alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.geofenceChannelId,
          AppConstants.geofenceChannelName,
          description: 'Geofence entry/exit alerts',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.batteryChannelId,
          AppConstants.batteryChannelName,
          description: 'Battery level alerts',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          AppConstants.checkinChannelId,
          AppConstants.checkinChannelName,
          description: 'Auto check-in alerts',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        channelId: message.data['channelId'] ?? AppConstants.sosChannelId,
      );
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String channelId,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == AppConstants.sosChannelId
              ? AppConstants.sosChannelName
              : AppConstants.geofenceChannelName,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
    );
  }

  Future<void> showSosNotification({
    required String childName,
    required double lat,
    required double lng,
  }) async {
    await _localNotifications.show(
      999,
      '🚨 SOS Alert!',
      '$childName needs help! Location: ($lat, $lng)',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.sosChannelId,
          AppConstants.sosChannelName,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  Future<void> showGeofenceNotification({
    required String childName,
    required String zoneName,
    required bool isEntering,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      isEntering ? '✅ Entered Safe Zone' : '⚠️ Left Safe Zone',
      '$childName ${isEntering ? 'entered' : 'left'} "$zoneName"',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.geofenceChannelId,
          AppConstants.geofenceChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showBatteryLowNotification({
    required String childName,
    required int batteryLevel,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '⚠️ Low Battery Warning',
      '$childName battery is at $batteryLevel%',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.batteryChannelId,
          AppConstants.batteryChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showBatteryCriticalNotification({
    required String childName,
    required int batteryLevel,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🔴 Critical Battery',
      '$childName battery critically low at $batteryLevel%! May lose contact soon.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.batteryChannelId,
          AppConstants.batteryChannelName,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
  }

  Future<void> showConnectionLostNotification({
    required String childName,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '📡 Connection Lost',
      'No update from $childName for over 15 minutes',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.batteryChannelId,
          AppConstants.batteryChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showDangerZoneNotification({
    required String childName,
    required String zoneName,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 Danger Zone Alert',
      '$childName entered danger zone "$zoneName"',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.geofenceChannelId,
          AppConstants.geofenceChannelName,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
  }

  Future<void> showCheckinNotification({
    required String childName,
    required String placeName,
    required String time,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '📍 Auto Check-in',
      '$childName arrived at $placeName at $time',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.checkinChannelId,
          AppConstants.checkinChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}
