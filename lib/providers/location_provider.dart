import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/location_data.dart';
import '../models/app_user.dart';
import '../models/geofence.dart';
import '../models/danger_zone.dart';
import '../models/daily_report.dart';
import '../models/timeline_event.dart';
import '../models/schedule_config.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/background_location_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../core/constants/app_constants.dart';

class LocationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final ReportService _reportService = ReportService();

  final Map<String, LocationData?> _childLocations = {};
  final Map<String, List<LocationData>> _locationHistories = {};
  final Map<String, StreamSubscription> _locationSubscriptions = {};
  final Map<String, StreamSubscription> _historySubscriptions = {};

  List<Geofence> _geofences = [];
  StreamSubscription? _geofenceSubscription;
  final Map<String, bool> _childGeofenceStatus = {};

  // Danger zones
  List<DangerZone> _dangerZones = [];
  StreamSubscription? _dangerZoneSubscription;
  final Map<String, bool> _childDangerZoneStatus = {};

  // Battery alerts tracking
  final Map<String, int> _lastBatteryAlertLevel = {};
  final Map<String, DateTime> _lastUpdateTime = {};

  // Auto check-in cooldown
  final Map<String, DateTime> _lastCheckinTime = {};

  // Daily report & timeline
  DailyReport? _selectedReport;
  List<TimelineEvent> _timelineEvents = [];
  StreamSubscription? _reportSubscription;
  StreamSubscription? _timelineSubscription;

  // Schedule config
  ScheduleConfig? _scheduleConfig;
  StreamSubscription? _scheduleSubscription;

  bool _isTracking = false;
  LocationData? _currentLocation;

  Map<String, LocationData?> get childLocations => _childLocations;
  Map<String, List<LocationData>> get locationHistories => _locationHistories;
  List<Geofence> get geofences => _geofences;
  List<DangerZone> get dangerZones => _dangerZones;
  bool get isTracking => _isTracking;
  LocationData? get currentLocation => _currentLocation;
  DailyReport? get selectedReport => _selectedReport;
  List<TimelineEvent> get timelineEvents => _timelineEvents;
  ScheduleConfig? get scheduleConfig => _scheduleConfig;

  // ─── PARENT: Listen to children's locations ───

  void listenToChildLocation(String childId) {
    _locationSubscriptions[childId]?.cancel();
    _locationSubscriptions[childId] =
        _firestoreService.locationStream(childId).listen((location) {
      _childLocations[childId] = location;

      if (location != null) {
        _checkGeofences(childId, location);
        _checkDangerZones(childId, location);
        _checkBatteryLevel(childId, location);
        _checkAutoCheckin(childId, location);
        _lastUpdateTime[childId] = DateTime.now();
      }

      notifyListeners();
    });
  }

  void listenToChildHistory(String childId) {
    _historySubscriptions[childId]?.cancel();
    _historySubscriptions[childId] = _firestoreService
        .locationHistoryStream(childId)
        .listen((history) {
      _locationHistories[childId] = history;
      notifyListeners();
    });
  }

  void listenToFamilyChildren(List<AppUser> children) {
    for (final child in children) {
      listenToChildLocation(child.uid);
      listenToChildHistory(child.uid);
    }
  }

  // ─── GEOFENCES ───

  void listenToGeofences(String familyId) {
    _geofenceSubscription?.cancel();
    _geofenceSubscription =
        _firestoreService.geofencesStream(familyId).listen((fences) {
      _geofences = fences;
      notifyListeners();
    });
  }

  Future<void> createGeofence(Geofence geofence) async {
    await _firestoreService.createGeofence(geofence);
  }

  Future<void> deleteGeofence(String geofenceId) async {
    await _firestoreService.deleteGeofence(geofenceId);
  }

  void _checkGeofences(String childId, LocationData location) {
    for (final fence in _geofences) {
      final key = '${childId}_${fence.id}';
      final isInside = _locationService.isInsideGeofence(
        location.latitude,
        location.longitude,
        fence.latitude,
        fence.longitude,
        fence.radius,
      );

      final wasInside = _childGeofenceStatus[key];
      _childGeofenceStatus[key] = isInside;

      if (wasInside != null && wasInside != isInside) {
        _notificationService.showGeofenceNotification(
          childName: childId,
          zoneName: fence.name,
          isEntering: isInside,
        );
      }
    }
  }

  // ─── DANGER ZONES ───

  void listenToDangerZones(String familyId) {
    _dangerZoneSubscription?.cancel();
    _dangerZoneSubscription =
        _firestoreService.dangerZonesStream(familyId).listen((zones) {
      _dangerZones = zones;
      notifyListeners();
    });
  }

  Future<void> createDangerZone(DangerZone zone) async {
    await _firestoreService.createDangerZone(zone);
  }

  Future<void> deleteDangerZone(String zoneId) async {
    await _firestoreService.deleteDangerZone(zoneId);
  }

  void _checkDangerZones(String childId, LocationData location) {
    for (final zone in _dangerZones) {
      final key = '${childId}_${zone.id}';
      final isInside = _locationService.isInsideGeofence(
        location.latitude,
        location.longitude,
        zone.latitude,
        zone.longitude,
        zone.radius,
      );

      final wasInside = _childDangerZoneStatus[key];
      _childDangerZoneStatus[key] = isInside;

      if (wasInside != null && !wasInside && isInside) {
        _notificationService.showDangerZoneNotification(
          childName: childId,
          zoneName: zone.name,
        );
      }
    }
  }

  // ─── BATTERY ALERTS ───

  void _checkBatteryLevel(String childId, LocationData location) {
    final level = location.batteryLevel.toInt();
    final lastAlert = _lastBatteryAlertLevel[childId] ?? 100;

    if (level <= AppConstants.batteryCriticalThreshold &&
        lastAlert > AppConstants.batteryCriticalThreshold) {
      _notificationService.showBatteryCriticalNotification(
        childName: childId,
        batteryLevel: level,
      );
      _lastBatteryAlertLevel[childId] = level;
    } else if (level <= AppConstants.batteryLowThreshold &&
        lastAlert > AppConstants.batteryLowThreshold) {
      _notificationService.showBatteryLowNotification(
        childName: childId,
        batteryLevel: level,
      );
      _lastBatteryAlertLevel[childId] = level;
    } else if (level > AppConstants.batteryLowThreshold) {
      _lastBatteryAlertLevel[childId] = level;
    }
  }

  /// Check for connection lost (call periodically from parent screen)
  void checkConnectionLost() {
    final now = DateTime.now();
    for (final entry in _lastUpdateTime.entries) {
      final diff = now.difference(entry.value).inMinutes;
      if (diff >= AppConstants.connectionLostMinutes) {
        _notificationService.showConnectionLostNotification(
          childName: entry.key,
        );
      }
    }
  }

  // ─── AUTO CHECK-IN ───

  void _checkAutoCheckin(String childId, LocationData location) {
    // Check against geofences for auto arrival detection
    for (final fence in _geofences) {
      final isInside = _locationService.isInsideGeofence(
        location.latitude,
        location.longitude,
        fence.latitude,
        fence.longitude,
        fence.radius,
      );

      if (isInside) {
        final cooldownKey = '${childId}_${fence.id}';
        final lastCheckin = _lastCheckinTime[cooldownKey];
        final now = DateTime.now();

        if (lastCheckin == null ||
            now.difference(lastCheckin).inMinutes >=
                AppConstants.checkinCooldownMinutes) {
          _lastCheckinTime[cooldownKey] = now;
          final timeStr = DateFormat('HH:mm').format(now);
          _notificationService.showCheckinNotification(
            childName: childId,
            placeName: fence.name,
            time: timeStr,
          );
        }
      }
    }
  }

  // ─── DAILY REPORT ───

  void listenToDailyReport(String childId, String date) {
    _reportSubscription?.cancel();
    _reportSubscription =
        _firestoreService.dailyReportStream(childId, date).listen((report) {
      _selectedReport = report;
      notifyListeners();
    });
  }

  Future<void> generateAndSaveReport(
    String childId,
    DateTime date,
  ) async {
    final history = _locationHistories[childId] ?? [];
    // Filter for the specific date
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dayPoints = history.where((loc) {
      return DateFormat('yyyy-MM-dd').format(loc.timestamp) == dateStr;
    }).toList();

    // Find home zone (first geofence named "Home" or first one)
    Geofence? homeZone;
    if (_geofences.isNotEmpty) {
      homeZone = _geofences.firstWhere(
        (f) => f.name.toLowerCase().contains('home') ||
            f.name.toLowerCase().contains('nhà'),
        orElse: () => _geofences.first,
      );
    }

    final report = _reportService.calculateDailyReport(
      userId: childId,
      date: date,
      locationPoints: dayPoints,
      homeZone: homeZone,
    );

    await _firestoreService.saveDailyReport(report);
    _selectedReport = report;
    notifyListeners();
  }

  // ─── TIMELINE ───

  void listenToTimeline(String childId, String date) {
    _timelineSubscription?.cancel();
    _timelineSubscription = _firestoreService
        .timelineEventsStream(childId, date)
        .listen((events) {
      _timelineEvents = events;
      notifyListeners();
    });
  }

  Future<void> generateAndSaveTimeline(
    String childId,
    DateTime date,
  ) async {
    final history = _locationHistories[childId] ?? [];
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dayPoints = history.where((loc) {
      return DateFormat('yyyy-MM-dd').format(loc.timestamp) == dateStr;
    }).toList();

    final events = _reportService.generateTimeline(
      userId: childId,
      date: date,
      locationPoints: dayPoints,
      knownPlaces: _geofences,
    );

    for (final event in events) {
      await _firestoreService.saveTimelineEvent(event);
    }

    _timelineEvents = events;
    notifyListeners();
  }

  // ─── SCHEDULE CONFIG ───

  void listenToScheduleConfig(String familyId) {
    _scheduleSubscription?.cancel();
    _scheduleSubscription =
        _firestoreService.scheduleConfigStream(familyId).listen((config) {
      _scheduleConfig = config;
      notifyListeners();
    });
  }

  Future<void> saveScheduleConfig(ScheduleConfig config) async {
    await _firestoreService.saveScheduleConfig(config);
  }

  // ─── CHILD: Start/Stop tracking ───

  Future<void> startTracking(String userId) async {
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) return;

    _isTracking = true;
    notifyListeners();

    _currentLocation = await _locationService.getCurrentLocation(userId);
    if (_currentLocation != null) {
      await _firestoreService.updateLocation(_currentLocation!);
      await _firestoreService.addLocationHistory(_currentLocation!);
    }

    await BackgroundLocationService.startService(userId);
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    await BackgroundLocationService.stopService();
    notifyListeners();
  }

  // ─── CLEANUP ───

  @override
  void dispose() {
    for (final sub in _locationSubscriptions.values) {
      sub.cancel();
    }
    for (final sub in _historySubscriptions.values) {
      sub.cancel();
    }
    _geofenceSubscription?.cancel();
    _dangerZoneSubscription?.cancel();
    _reportSubscription?.cancel();
    _timelineSubscription?.cancel();
    _scheduleSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
