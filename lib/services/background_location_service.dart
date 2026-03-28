import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class BackgroundLocationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.locationChannelId,
      AppConstants.locationChannelName,
      description: 'Used for location tracking notification',
      importance: Importance.low,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: AppConstants.locationChannelId,
        initialNotificationTitle: AppConstants.appName,
        initialNotificationContent: 'Location sharing is active',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Initialize Firebase in the background isolate
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Already initialized or failed – continue with best effort
    }

    final prefs = await SharedPreferences.getInstance();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Dynamic interval tracking variables
    int currentIntervalSeconds = AppConstants.locationUpdateIntervalMs ~/ 1000;
    int lastBatteryAlertLevel = 100;

    // Periodic location update with dynamic interval
    _scheduleNextUpdate(
      service,
      prefs,
      currentIntervalSeconds,
      lastBatteryAlertLevel,
    );
  }

  static void _scheduleNextUpdate(
    ServiceInstance service,
    SharedPreferences prefs,
    int intervalSeconds,
    int lastBatteryAlert,
  ) {
    Future.delayed(Duration(seconds: intervalSeconds), () async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          final userId = prefs.getString('current_user_id');
          if (userId == null) {
            _scheduleNextUpdate(service, prefs, intervalSeconds, lastBatteryAlert);
            return;
          }

          try {
            final position = await geo.Geolocator.getCurrentPosition(
              locationSettings: const geo.LocationSettings(
                accuracy: geo.LocationAccuracy.high,
                timeLimit: Duration(seconds: 15),
              ),
            );

            final batteryLevel = await Battery().batteryLevel;

            final db = FirebaseFirestore.instance;

            // Update current location
            await db
                .collection(AppConstants.locationsCollection)
                .doc(userId)
                .set({
              'userId': userId,
              'lat': position.latitude,
              'lng': position.longitude,
              'accuracy': position.accuracy,
              'speed': position.speed,
              'batteryLevel': batteryLevel,
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Add to history
            await db
                .collection(AppConstants.locationsCollection)
                .doc(userId)
                .collection('history')
                .add({
              'userId': userId,
              'lat': position.latitude,
              'lng': position.longitude,
              'accuracy': position.accuracy,
              'speed': position.speed,
              'batteryLevel': batteryLevel,
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Update user status
            await db
                .collection(AppConstants.usersCollection)
                .doc(userId)
                .update({
              'batteryLevel': batteryLevel,
              'isOnline': true,
              'lastActive': FieldValue.serverTimestamp(),
            });

            // ─── SCHEDULE MODE: Dynamic interval ───
            int nextInterval = intervalSeconds;
            final familyId = prefs.getString('family_id');
            if (familyId != null) {
              try {
                final configSnap = await db
                    .collection(AppConstants.scheduleConfigCollection)
                    .where('familyId', isEqualTo: familyId)
                    .limit(1)
                    .get();
                if (configSnap.docs.isNotEmpty) {
                  final configData = configSnap.docs.first.data();
                  final isEnabled = configData['isEnabled'] ?? false;
                  if (isEnabled) {
                    final now = DateTime.now();
                    final schoolStart = configData['schoolStartHour'] ?? 6;
                    final schoolStartMin = configData['schoolStartMinute'] ?? 0;
                    final schoolEnd = configData['schoolEndHour'] ?? 18;
                    final schoolEndMin = configData['schoolEndMinute'] ?? 0;
                    final schoolDays =
                        List<int>.from(configData['schoolDays'] ?? [1, 2, 3, 4, 5]);

                    final schoolStartTime =
                        now.hour * 60 + now.minute >= schoolStart * 60 + schoolStartMin;
                    final schoolEndTime =
                        now.hour * 60 + now.minute < schoolEnd * 60 + schoolEndMin;
                    final isSchoolDay = schoolDays.contains(now.weekday);

                    if (isSchoolDay && schoolStartTime && schoolEndTime) {
                      nextInterval = configData['schoolIntervalSeconds'] ?? 20;
                    } else {
                      nextInterval = configData['offHoursIntervalSeconds'] ?? 180;
                    }
                  }
                }
              } catch (_) {}
            }

            // Update notification
            String modeLabel = nextInterval <= 30 ? '⚡ Intensive' : '🔋 Power Saving';
            service.setForegroundNotificationInfo(
              title: AppConstants.appName,
              content:
                  'Sharing location • Battery: $batteryLevel% • $modeLabel',
            );

            _scheduleNextUpdate(service, prefs, nextInterval, lastBatteryAlert);
          } catch (e) {
            _scheduleNextUpdate(service, prefs, intervalSeconds, lastBatteryAlert);
          }
        }
      }
    });
  }

  static Future<void> startService(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
    await _service.startService();
  }

  static Future<void> stopService() async {
    _service.invoke('stopService');
  }

  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}
