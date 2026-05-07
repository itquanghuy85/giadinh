import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:family_finance/shared/models/live_location.dart';
import 'package:family_finance/shared/repositories/location_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Dịch vụ theo dõi vị trí GPS của người dùng và đồng bộ lên Firestore.
///
/// Chiến lược tối ưu pin:
/// - Đang di chuyển (speed > 0.5 m/s): upload khi đi được ≥ 10m HOẶC sau 10 giây
/// - Đứng yên: upload khi đi được ≥ 50m HOẶC sau 3 phút
/// - Android: sử dụng ForegroundService để tracking khi app xuống nền
/// - iOS: sử dụng Background Location mode
class LocationService {
  LocationService({
    required this.userId,
    required this.familyId,
    required this.displayName,
    required this.repository,
    this.photoUrl,
  });

  final String userId;
  final String familyId;
  final String displayName;
  final String? photoUrl;
  final LocationRepository repository;

  final _battery = Battery();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _stationaryFallbackTimer;
  Position? _lastUploadedPosition;
  DateTime _lastUpload = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isRunning = false;

  // ── Ngưỡng tối ưu pin ───────────────────────────────────────────
  static const _movingMinDistanceM = 10.0; // mét
  static const _movingMaxInterval = Duration(seconds: 10);
  static const _stationaryMinDistanceM = 50.0; // mét
  static const _stationaryInterval = Duration(minutes: 3);

  bool get isRunning => _isRunning;

  /// Bắt đầu tracking. Trả về true nếu thành công.
  Future<bool> start() async {
    if (_isRunning) return true;

    final hasPermission = await _checkPermission();
    if (!hasPermission) return false;

    _isRunning = true;
    developer.log('[LocationService] ▶ Started for user=$userId family=$familyId');

    final settings = _buildLocationSettings();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(_onPositionUpdate, onError: _onStreamError);

    // Timer dự phòng cho trường hợp đứng yên lâu
    _stationaryFallbackTimer = Timer.periodic(_stationaryInterval, (_) async {
      try {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) await _uploadPosition(pos, forceUpload: true);
      } catch (_) {}
    });

    // Upload trạng thái online ngay lập tức
    await _uploadOnlineStatus();
    return true;
  }

  /// Dừng tracking và đánh dấu offline trong Firestore.
  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    developer.log('[LocationService] ⏹ Stopped for user=$userId');

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _stationaryFallbackTimer?.cancel();
    _stationaryFallbackTimer = null;

    await repository.setOffline(userId);
  }

  // ── Private helpers ──────────────────────────────────────────────

  Future<bool> _checkPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  /// Cấu hình location stream theo nền tảng.
  LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // trigger khi đi được 5m
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Đang chia sẻ vị trí với gia đình',
          notificationTitle: 'Family Finance',
          enableWakeLock: true,
          notificationChannelName: 'Vị trí gia đình',
        ),
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  Future<void> _onPositionUpdate(Position position) async {
    final now = DateTime.now();
    final timeSinceLastUpload = now.difference(_lastUpload);
    final isMoving = position.speed > 0.5; // m/s ≈ 1.8 km/h

    double distanceMoved = 0;
    if (_lastUploadedPosition != null) {
      distanceMoved = Geolocator.distanceBetween(
        _lastUploadedPosition!.latitude,
        _lastUploadedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    final firstUpload = _lastUploadedPosition == null;
    final movingTrigger =
        isMoving && (distanceMoved >= _movingMinDistanceM || timeSinceLastUpload >= _movingMaxInterval);
    final stationaryTrigger = !isMoving && distanceMoved >= _stationaryMinDistanceM;

    if (firstUpload || movingTrigger || stationaryTrigger) {
      await _uploadPosition(position);
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    developer.log('[LocationService] Stream error: $error', stackTrace: stackTrace);
  }

  Future<void> _uploadPosition(Position position, {bool forceUpload = false}) async {
    try {
      int batteryLevel = -1;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (_) {}

      final loc = LiveLocation(
        userId: userId,
        familyId: familyId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        batteryLevel: batteryLevel,
        isMoving: position.speed > 0.5,
        isOnline: true,
        updatedAt: DateTime.now(),
        displayName: displayName,
        photoUrl: photoUrl,
      );

      await repository.updateLocation(loc);
      _lastUploadedPosition = position;
      _lastUpload = DateTime.now();
      debugPrint(
        '[LocationService] 📍 Uploaded: ${position.latitude.toStringAsFixed(5)},${position.longitude.toStringAsFixed(5)} '
        'speed=${position.speed.toStringAsFixed(1)} battery=$batteryLevel%',
      );
    } catch (e) {
      developer.log('[LocationService] Upload error: $e');
    }
  }

  Future<void> _uploadOnlineStatus() async {
    try {
      Position? pos;
      try {
        pos = await Geolocator.getLastKnownPosition();
        pos ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}

      if (pos != null) {
        await _uploadPosition(pos, forceUpload: true);
      }
    } catch (_) {}
  }
}
