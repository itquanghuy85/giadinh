import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sos_alert.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class SosProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  List<SosAlert> _alerts = [];
  bool _isSending = false;
  StreamSubscription? _alertsSubscription;

  List<SosAlert> get alerts => _alerts;
  bool get isSending => _isSending;

  void listenToAlerts(String familyId) {
    _alertsSubscription?.cancel();
    _alertsSubscription =
        _firestoreService.sosAlertsStream(familyId).listen((alerts) {
      _alerts = alerts;
      notifyListeners();

      // Show notification for new alerts
      if (alerts.isNotEmpty) {
        final latest = alerts.first;
        _notificationService.showSosNotification(
          childName: latest.childName,
          lat: latest.latitude,
          lng: latest.longitude,
        );
      }
    });
  }

  Future<bool> sendSosAlert({
    required String childId,
    required String childName,
    required String familyId,
  }) async {
    _isSending = true;
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation(childId);

      final alert = SosAlert(
        id: const Uuid().v4(),
        childId: childId,
        childName: childName,
        familyId: familyId,
        latitude: location?.latitude ?? 0,
        longitude: location?.longitude ?? 0,
        timestamp: DateTime.now(),
      );

      await _firestoreService.createSosAlert(alert);
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> resolveAlert(String alertId) async {
    await _firestoreService.resolveSosAlert(alertId);
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
