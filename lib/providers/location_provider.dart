import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/location_data.dart';
import '../models/app_user.dart';
import '../models/geofence.dart';
import '../models/danger_zone.dart';
import '../models/daily_report.dart';
import '../models/timeline_event.dart';
import '../models/schedule_config.dart';
import '../models/security_event.dart';
import '../models/family_event.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/background_location_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../core/constants/app_constants.dart';
import '../services/home_widget_service.dart';

class LocationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final ReportService _reportService = ReportService();

  final Map<String, LocationData?> _childLocations = {};
  final Map<String, List<LocationData>> _locationHistories = {};
  final Map<String, StreamSubscription> _locationSubscriptions = {};
  final Map<String, StreamSubscription> _historySubscriptions = {};

  // childId → displayName mapping for notifications
  final Map<String, String> _childNames = {};

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

  // Family events (calendar)
  List<FamilyEvent> _familyEvents = [];
  StreamSubscription? _eventsSubscription;
  Timer? _eventReminderTimer;
  bool _eventReminderEnabled = true;
  List<int> _eventReminderStages =
      List<int>.from(AppConstants.defaultEventReminderStages);

  // Security events
  List<SecurityEvent> _securityEvents = [];
  StreamSubscription? _securitySubscription;

  // Long disconnection tracking
  final Map<String, bool> _longDisconnectAlerted = {};
  Timer? _disconnectionTimer;

  // Night alert settings
  bool _nightAlertEnabled = false;
  int _nightStartHour = AppConstants.defaultNightStartHour;
  int _nightEndHour = AppConstants.defaultNightEndHour;
  final Map<String, DateTime> _lastNightAlertTime = {};

  // Near home cooldown
  final Map<String, DateTime> _lastNearHomeAlertTime = {};

  // GPS status (from child reports)
  final Map<String, bool> _childGpsStatus = {};

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
  List<FamilyEvent> get familyEvents => _familyEvents;
  bool get eventReminderEnabled => _eventReminderEnabled;
  List<int> get eventReminderStages => List.unmodifiable(_eventReminderStages);
  List<SecurityEvent> get securityEvents => _securityEvents;
  bool get nightAlertEnabled => _nightAlertEnabled;
  int get nightStartHour => _nightStartHour;
  int get nightEndHour => _nightEndHour;
  Map<String, bool> get childGpsStatus => _childGpsStatus;

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
        _checkNightMovement(childId, location);
        _checkNearHome(childId, location);
        _lastUpdateTime[childId] = DateTime.now();
        _longDisconnectAlerted[childId] = false;

        // Update home widget
        HomeWidgetService.updateWidget(
          childName: _childDisplayName(childId),
          isOnline: true,
          batteryLevel: location.batteryLevel.toInt(),
          locationText:
              '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
        );
      }

      notifyListeners();
    }, onError: (e) => debugPrint('locationStream error: $e'));
  }

  void listenToChildHistory(String childId) {
    _historySubscriptions[childId]?.cancel();
    _historySubscriptions[childId] = _firestoreService
        .locationHistoryStream(childId)
        .listen((history) {
      _locationHistories[childId] = history;
      notifyListeners();
    }, onError: (e) => debugPrint('historyStream error: $e'));
  }

  void listenToFamilyChildren(List<AppUser> children) {
    for (final child in children) {
      _childNames[child.uid] = child.displayName;
      listenToChildLocation(child.uid);
      listenToChildHistory(child.uid);
    }
  }

  /// Resolve childId to display name for notifications
  String _childDisplayName(String childId) =>
      _childNames[childId] ?? childId;

  // ─── GEOFENCES ───

  void listenToGeofences(String familyId) {
    _geofenceSubscription?.cancel();
    _geofenceSubscription =
        _firestoreService.geofencesStream(familyId).listen((fences) {
      _geofences = fences;
      notifyListeners();
    }, onError: (e) => debugPrint('geofencesStream error: $e'));
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
          childName: _childDisplayName(childId),
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
    }, onError: (e) => debugPrint('dangerZonesStream error: $e'));
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
          childName: _childDisplayName(childId),
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
        childName: _childDisplayName(childId),
        batteryLevel: level,
      );
      _lastBatteryAlertLevel[childId] = level;
    } else if (level <= AppConstants.batteryLowThreshold &&
        lastAlert > AppConstants.batteryLowThreshold) {
      _notificationService.showBatteryLowNotification(
        childName: _childDisplayName(childId),
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
          childName: _childDisplayName(entry.key),
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
            childName: _childDisplayName(childId),
            placeName: fence.name,
            time: timeStr,
          );
        }
      }
    }
  }

  // ─── NIGHT MOVEMENT CHECK ───

  void _checkNightMovement(String childId, LocationData location) {
    if (!_nightAlertEnabled) return;

    final now = DateTime.now();
    final hour = now.hour;

    // Check if current time is within night window
    bool isNightTime;
    if (_nightStartHour > _nightEndHour) {
      // e.g. 22:00 - 06:00 (crosses midnight)
      isNightTime = hour >= _nightStartHour || hour < _nightEndHour;
    } else {
      isNightTime = hour >= _nightStartHour && hour < _nightEndHour;
    }

    if (!isNightTime) return;

    // Check if user is outside Home zone
    final homeZone = _geofences.cast<Geofence?>().firstWhere(
          (f) =>
              f!.name.toLowerCase().contains('home') ||
              f.name.toLowerCase().contains('nhà'),
          orElse: () => null,
        );

    if (homeZone == null) return;

    final isHome = _locationService.isInsideGeofence(
      location.latitude,
      location.longitude,
      homeZone.latitude,
      homeZone.longitude,
      homeZone.radius,
    );

    if (isHome) return;

    // Speed check (moving if speed > 1 m/s ~= 3.6 km/h)
    if (location.speed != null && location.speed! < 1.0) return;

    // Cooldown (once per 30 min)
    final lastAlert = _lastNightAlertTime[childId];
    if (lastAlert != null && now.difference(lastAlert).inMinutes < 30) return;

    _lastNightAlertTime[childId] = now;
    _notificationService.showNightMovementNotification(childName: _childDisplayName(childId));

    // Log security event
    _firestoreService.logSecurityEvent(SecurityEvent(
      id: const Uuid().v4(),
      userId: childId,
      familyId: _geofences.isNotEmpty ? _geofences.first.familyId : '',
      type: SecurityEventType.nightMovement,
      description: 'Night movement detected outside home',
      timestamp: now,
    ));
  }

  // ─── NEAR HOME CHECK ───

  void _checkNearHome(String childId, LocationData location) {
    final homeZone = _geofences.cast<Geofence?>().firstWhere(
          (f) =>
              f!.name.toLowerCase().contains('home') ||
              f.name.toLowerCase().contains('nhà'),
          orElse: () => null,
        );

    if (homeZone == null) return;

    final distance = _haversineDistance(
      location.latitude,
      location.longitude,
      homeZone.latitude,
      homeZone.longitude,
    );

    // Already inside the zone — skip
    if (distance <= homeZone.radius) return;

    // Check if within 500m
    if (distance > AppConstants.nearHomeDistanceMeters) return;

    // Speed check — must be moving
    if (location.speed != null && location.speed! < 1.0) return;

    // Cooldown
    final now = DateTime.now();
    final lastAlert = _lastNearHomeAlertTime[childId];
    if (lastAlert != null &&
        now.difference(lastAlert).inMinutes <
            AppConstants.nearHomeCooldownMinutes) {
      return;
    }

    _lastNearHomeAlertTime[childId] = now;
    _notificationService.showNearHomeNotification(childName: _childDisplayName(childId));
  }

  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  // ─── LONG DISCONNECTION CHECK ───

  void startDisconnectionMonitor() {
    _disconnectionTimer?.cancel();
    _disconnectionTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkLongDisconnection(),
    );
  }

  void _checkLongDisconnection() {
    final now = DateTime.now();
    for (final entry in _lastUpdateTime.entries) {
      final childId = entry.key;
      final lastUpdate = entry.value;
      final diffMinutes = now.difference(lastUpdate).inMinutes;

      if (diffMinutes >= AppConstants.longDisconnectionMinutes &&
          _longDisconnectAlerted[childId] != true) {
        _longDisconnectAlerted[childId] = true;
        _notificationService.showLongDisconnectionNotification(
          childName: _childDisplayName(childId),
          minutes: diffMinutes,
        );

        // Log event
        if (_geofences.isNotEmpty) {
          _firestoreService.logSecurityEvent(SecurityEvent(
            id: const Uuid().v4(),
            userId: childId,
            familyId: _geofences.first.familyId,
            type: SecurityEventType.connectionLost,
            description: 'No location update for $diffMinutes minutes',
            timestamp: now,
          ));
        }
      }
    }
  }

  // ─── NIGHT ALERT SETTINGS ───

  Future<void> loadNightAlertSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _nightAlertEnabled =
        prefs.getBool(AppConstants.prefNightAlertEnabled) ?? false;
    _nightStartHour =
        prefs.getInt(AppConstants.prefNightStartHour) ??
            AppConstants.defaultNightStartHour;
    _nightEndHour =
        prefs.getInt(AppConstants.prefNightEndHour) ??
            AppConstants.defaultNightEndHour;
    notifyListeners();
  }

  Future<void> setNightAlertEnabled(bool enabled) async {
    _nightAlertEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefNightAlertEnabled, enabled);
    notifyListeners();
  }

  Future<void> setNightAlertHours(int startHour, int endHour) async {
    _nightStartHour = startHour;
    _nightEndHour = endHour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefNightStartHour, startHour);
    await prefs.setInt(AppConstants.prefNightEndHour, endHour);
    notifyListeners();
  }

  // ─── FAMILY EVENTS (CALENDAR) ───

  void listenToFamilyEvents(String familyId) {
    _eventsSubscription?.cancel();
    _eventsSubscription =
        _firestoreService.familyEventsStream(familyId).listen((events) {
      _familyEvents = events;
      notifyListeners();
    }, onError: (e) => debugPrint('familyEventsStream error: $e'));

    // Ensure reminder preferences are loaded before timer ticks.
    loadEventReminderSettings();

    // Start event reminder timer
    _eventReminderTimer?.cancel();
    _eventReminderTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkEventReminders(),
    );
  }

  Future<void> createFamilyEvent(FamilyEvent event) async {
    await _firestoreService.createFamilyEvent(event);
  }

  Future<void> deleteFamilyEvent(String eventId) async {
    await _firestoreService.deleteFamilyEvent(eventId);
  }

  Future<void> loadEventReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _eventReminderEnabled =
        prefs.getBool(AppConstants.prefEventReminderEnabled) ?? true;

    final stored = prefs.getStringList(AppConstants.prefEventReminderStages);
    if (stored != null && stored.isNotEmpty) {
      final parsed = stored
          .map((e) => int.tryParse(e) ?? -1)
          .where((e) => e > 0)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
      if (parsed.isNotEmpty) {
        _eventReminderStages = parsed;
      }
    }
    notifyListeners();
  }

  Future<void> setEventReminderEnabled(bool enabled) async {
    _eventReminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefEventReminderEnabled, enabled);
    notifyListeners();
  }

  Future<void> setEventReminderStageEnabled(int minutes, bool enabled) async {
    final next = List<int>.from(_eventReminderStages);
    if (enabled) {
      if (!next.contains(minutes)) next.add(minutes);
    } else {
      next.remove(minutes);
    }
    next.sort((a, b) => b.compareTo(a));
    _eventReminderStages = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConstants.prefEventReminderStages,
      _eventReminderStages.map((e) => '$e').toList(),
    );
    notifyListeners();
  }

  void _checkEventReminders() {
    if (!_eventReminderEnabled || _eventReminderStages.isEmpty) return;

    final now = DateTime.now();
    for (final event in _familyEvents) {
      final diff = event.eventTime.difference(now).inMinutes;
      if (diff <= 0) continue;

      final already = event.remindedAtMinutes.toSet();
      final matched = _eventReminderStages
          .where((m) => diff <= m && !already.contains(m))
          .toList()
        ..sort();

      if (matched.isEmpty) continue;

      // Send the nearest pending reminder stage only to avoid stacked alerts.
      final stage = matched.first;
      _notificationService.showEventReminderNotification(
        eventTitle: event.title,
        location: event.location,
        minutes: stage,
      );
      _firestoreService.markEventReminderStage(event.id, stage);
    }
  }

  // ─── SECURITY EVENTS ───

  void listenToSecurityEvents(String familyId) {
    _securitySubscription?.cancel();
    _securitySubscription =
        _firestoreService.securityEventsStream(familyId).listen((events) {
      _securityEvents = events;

      // Update child GPS status from events
      for (final event in events) {
        if (event.type == SecurityEventType.gpsDisabled) {
          _childGpsStatus[event.userId] = false;
        } else if (event.type == SecurityEventType.gpsEnabled) {
          _childGpsStatus[event.userId] = true;
        }
      }

      notifyListeners();
    }, onError: (e) => debugPrint('securityEventsStream error: $e'));
  }

  // ─── AREA TIME ANALYSIS ───

  Map<String, int> calculateAreaTime(
    List<LocationData> points,
  ) {
    final result = <String, int>{'Home': 0, 'School': 0, 'Other': 0};
    if (points.length < 2) return result;

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final minutes = curr.timestamp.difference(prev.timestamp).inMinutes;
      if (minutes > 30) continue; // skip large gaps

      String area = 'Other';
      for (final fence in _geofences) {
        final inside = _locationService.isInsideGeofence(
          curr.latitude,
          curr.longitude,
          fence.latitude,
          fence.longitude,
          fence.radius,
        );
        if (inside) {
          final name = fence.name.toLowerCase();
          if (name.contains('home') || name.contains('nhà')) {
            area = 'Home';
          } else if (name.contains('school') || name.contains('trường')) {
            area = 'School';
          } else {
            area = fence.name;
          }
          break;
        }
      }

      result[area] = (result[area] ?? 0) + minutes;
    }

    return result;
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
    }, onError: (e) => debugPrint('timelineStream error: $e'));
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
    }, onError: (e) => debugPrint('scheduleConfigStream error: $e'));
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
    _eventsSubscription?.cancel();
    _securitySubscription?.cancel();
    _disconnectionTimer?.cancel();
    _eventReminderTimer?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
