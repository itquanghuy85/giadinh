import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/security_event.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

/// Monitors GPS service status and location permissions.
/// Reports anomalies to parents and logs events.
class GpsMonitorService extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  Timer? _permissionCheckTimer;

  bool _gpsEnabled = true;
  bool _permissionGranted = true;
  DateTime? _lastGpsAlertTime;
  DateTime? _lastPermissionAlertTime;

  String? _userId;
  String? _familyId;

  bool get gpsEnabled => _gpsEnabled;
  bool get permissionGranted => _permissionGranted;

  void startMonitoring({required String userId, required String familyId}) {
    _userId = userId;
    _familyId = familyId;

    // Listen to GPS service status changes
    _serviceStatusSub?.cancel();
    _serviceStatusSub =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      final wasEnabled = _gpsEnabled;
      _gpsEnabled = status == ServiceStatus.enabled;

      if (wasEnabled && !_gpsEnabled) {
        _onGpsDisabled();
      } else if (!wasEnabled && _gpsEnabled) {
        _onGpsEnabled();
      }

      notifyListeners();
    });

    // Check permission periodically
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = Timer.periodic(
      const Duration(seconds: AppConstants.permissionCheckIntervalSeconds),
      (_) => _checkPermission(),
    );

    // Initial check
    _checkGpsStatus();
    _checkPermission();
  }

  Future<void> _checkGpsStatus() async {
    _gpsEnabled = await Geolocator.isLocationServiceEnabled();
    notifyListeners();
  }

  Future<void> _checkPermission() async {
    final permission = await Geolocator.checkPermission();
    final wasGranted = _permissionGranted;
    _permissionGranted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (wasGranted && !_permissionGranted) {
      _onPermissionRevoked();
    }

    notifyListeners();
  }

  void _onGpsDisabled() {
    if (_userId == null || _familyId == null) return;

    // Cooldown check
    final now = DateTime.now();
    if (_lastGpsAlertTime != null &&
        now.difference(_lastGpsAlertTime!).inMinutes <
            AppConstants.gpsAlertCooldownMinutes) {
      return;
    }
    _lastGpsAlertTime = now;

    // Send notification
    _notificationService.showGpsDisabledNotification(childName: _userId!);

    // Log to Firestore
    _firestoreService.logSecurityEvent(SecurityEvent(
      id: const Uuid().v4(),
      userId: _userId!,
      familyId: _familyId!,
      type: SecurityEventType.gpsDisabled,
      description: 'GPS/Location services disabled',
      timestamp: now,
    ));
  }

  void _onGpsEnabled() {
    if (_userId == null || _familyId == null) return;

    _firestoreService.logSecurityEvent(SecurityEvent(
      id: const Uuid().v4(),
      userId: _userId!,
      familyId: _familyId!,
      type: SecurityEventType.gpsEnabled,
      description: 'GPS/Location services re-enabled',
      timestamp: DateTime.now(),
    ));
  }

  void _onPermissionRevoked() {
    if (_userId == null || _familyId == null) return;

    final now = DateTime.now();
    if (_lastPermissionAlertTime != null &&
        now.difference(_lastPermissionAlertTime!).inMinutes <
            AppConstants.gpsAlertCooldownMinutes) {
      return;
    }
    _lastPermissionAlertTime = now;

    _notificationService.showPermissionRevokedNotification(
        childName: _userId!);

    _firestoreService.logSecurityEvent(SecurityEvent(
      id: const Uuid().v4(),
      userId: _userId!,
      familyId: _familyId!,
      type: SecurityEventType.permissionRevoked,
      description: 'Location permission revoked',
      timestamp: now,
    ));
  }

  void stopMonitoring() {
    _serviceStatusSub?.cancel();
    _permissionCheckTimer?.cancel();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
