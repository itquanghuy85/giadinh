import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:battery_plus/battery_plus.dart';
import '../models/location_data.dart';

class LocationService {
  final Battery _battery = Battery();
  StreamSubscription<geo.Position>? _positionSubscription;

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return false;
    }

    if (permission == geo.LocationPermission.deniedForever) return false;

    return true;
  }

  Future<bool> requestBackgroundPermission() async {
    final permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.whileInUse) {
      final bgPermission = await geo.Geolocator.requestPermission();
      return bgPermission == geo.LocationPermission.always;
    }
    return permission == geo.LocationPermission.always;
  }

  Future<LocationData?> getCurrentLocation(String userId) async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final batteryLevel = await _battery.batteryLevel;

      return LocationData(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        batteryLevel: batteryLevel.toDouble(),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  Stream<LocationData> getLocationStream(String userId) {
    final controller = StreamController<LocationData>();

    const locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 20, // 20 meters
    );

    _positionSubscription = geo.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) async {
      final batteryLevel = await _battery.batteryLevel;
      controller.add(LocationData(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        batteryLevel: batteryLevel.toDouble(),
        timestamp: DateTime.now(),
      ));
    }, onError: (e) {
      controller.addError(e);
    });

    controller.onCancel = () {
      _positionSubscription?.cancel();
    };

    return controller.stream;
  }

  Future<double> distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return geo.Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  bool isInsideGeofence(
    double lat,
    double lng,
    double fenceLat,
    double fenceLng,
    double radiusInMeters,
  ) {
    final distance =
        geo.Geolocator.distanceBetween(lat, lng, fenceLat, fenceLng);
    return distance <= radiusInMeters;
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}
