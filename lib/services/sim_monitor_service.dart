import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/security_event.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

/// Detects SIM card changes on Android using platform channel.
/// Stores initial SIM info and compares on subsequent app starts.
class SimMonitorService {
  static const _channel = MethodChannel('com.huluca.giadinh/sim_info');
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  /// Check SIM and compare with stored value.
  /// Returns true if SIM was changed.
  Future<bool> checkSimChange({
    required String userId,
    required String familyId,
  }) async {
    try {
      final simSerial = await _getSimSerial();
      if (simSerial == null || simSerial.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      final storedSerial = prefs.getString(AppConstants.prefSimSerial);

      if (storedSerial == null) {
        // First time, save it
        await prefs.setString(AppConstants.prefSimSerial, simSerial);
        return false;
      }

      if (storedSerial != simSerial) {
        // SIM changed!
        await prefs.setString(AppConstants.prefSimSerial, simSerial);

        _notificationService.showSimChangedNotification(childName: userId);

        await _firestoreService.logSecurityEvent(SecurityEvent(
          id: const Uuid().v4(),
          userId: userId,
          familyId: familyId,
          type: SecurityEventType.simChanged,
          description: 'SIM card changed',
          timestamp: DateTime.now(),
          metadata: {'previousSerial': storedSerial},
        ));

        return true;
      }

      return false;
    } catch (e) {
      // Platform channel might not be available or permission denied
      return false;
    }
  }

  Future<String?> _getSimSerial() async {
    try {
      final result = await _channel.invokeMethod<String>('getSimSerial');
      return result;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
