import 'dart:async';
import 'package:flutter/material.dart';
import '../models/location_data.dart';
import '../models/app_user.dart';
import '../models/geofence.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/background_location_service.dart';
import '../services/notification_service.dart';

class LocationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  final Map<String, LocationData?> _childLocations = {};
  final Map<String, List<LocationData>> _locationHistories = {};
  final Map<String, StreamSubscription> _locationSubscriptions = {};
  final Map<String, StreamSubscription> _historySubscriptions = {};

  List<Geofence> _geofences = [];
  StreamSubscription? _geofenceSubscription;
  final Map<String, bool> _childGeofenceStatus = {}; // childId_geofenceId -> inside

  bool _isTracking = false;
  LocationData? _currentLocation;

  Map<String, LocationData?> get childLocations => _childLocations;
  Map<String, List<LocationData>> get locationHistories => _locationHistories;
  List<Geofence> get geofences => _geofences;
  bool get isTracking => _isTracking;
  LocationData? get currentLocation => _currentLocation;

  // ─── PARENT: Listen to children's locations ───

  void listenToChildLocation(String childId) {
    _locationSubscriptions[childId]?.cancel();
    _locationSubscriptions[childId] =
        _firestoreService.locationStream(childId).listen((location) {
      _childLocations[childId] = location;

      // Check geofences
      if (location != null) {
        _checkGeofences(childId, location);
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

      // Detect transition
      if (wasInside != null && wasInside != isInside) {
        _notificationService.showGeofenceNotification(
          childName: childId, // In real app, resolve to name
          zoneName: fence.name,
          isEntering: isInside,
        );
      }
    }
  }

  // ─── CHILD: Start/Stop tracking ───

  Future<void> startTracking(String userId) async {
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) return;

    _isTracking = true;
    notifyListeners();

    // Get initial location
    _currentLocation = await _locationService.getCurrentLocation(userId);
    if (_currentLocation != null) {
      await _firestoreService.updateLocation(_currentLocation!);
      await _firestoreService.addLocationHistory(_currentLocation!);
    }

    // Start background service
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
    _locationService.dispose();
    super.dispose();
  }
}
