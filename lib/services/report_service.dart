import 'dart:math';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/location_data.dart';
import '../models/daily_report.dart';
import '../models/timeline_event.dart';
import '../models/geofence.dart';
import '../core/constants/app_constants.dart';

class ReportService {
  /// Calculate daily report from location history
  DailyReport calculateDailyReport({
    required String userId,
    required DateTime date,
    required List<LocationData> locationPoints,
    Geofence? homeZone,
  }) {
    if (locationPoints.isEmpty) {
      return DailyReport(
        id: const Uuid().v4(),
        userId: userId,
        date: DateFormat('yyyy-MM-dd').format(date),
        totalDistanceKm: 0,
        maxSpeedKmh: 0,
        totalMovingTimeMinutes: 0,
        locationPointsCount: 0,
        createdAt: DateTime.now(),
      );
    }

    // Sort by timestamp
    final sorted = List<LocationData>.from(locationPoints)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalDistanceMeters = 0;
    double maxSpeedMs = 0;
    int movingTimeSeconds = 0;
    DateTime? leftHomeTime;
    DateTime? arrivedHomeTime;

    // Place visit counter
    final placeVisits = <String, int>{};

    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];

      // Distance
      final dist = _distanceBetween(
        prev.latitude, prev.longitude,
        curr.latitude, curr.longitude,
      );
      totalDistanceMeters += dist;

      // Speed
      final speed = curr.speed ?? 0;
      if (speed > maxSpeedMs) maxSpeedMs = speed;

      // Moving time (speed > 0.5 m/s ≈ walking)
      if (speed > 0.5) {
        final timeDiff = curr.timestamp.difference(prev.timestamp).inSeconds;
        if (timeDiff < 300) {
          // Skip gaps > 5 min
          movingTimeSeconds += timeDiff;
        }
      }

      // Home detection
      if (homeZone != null) {
        final wasHome = _isInsideCircle(
          prev.latitude, prev.longitude,
          homeZone.latitude, homeZone.longitude,
          homeZone.radius,
        );
        final isHome = _isInsideCircle(
          curr.latitude, curr.longitude,
          homeZone.latitude, homeZone.longitude,
          homeZone.radius,
        );

        if (wasHome && !isHome && leftHomeTime == null) {
          leftHomeTime = curr.timestamp;
        }
        if (!wasHome && isHome) {
          arrivedHomeTime = curr.timestamp;
        }
      }
    }

    // Detect most visited place from geofence-like clustering
    String? mostVisitedPlace;
    int mostVisitedCount = 0;
    if (placeVisits.isNotEmpty) {
      final topEntry = placeVisits.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      mostVisitedPlace = topEntry.key;
      mostVisitedCount = topEntry.value;
    }

    return DailyReport(
      id: const Uuid().v4(),
      userId: userId,
      date: DateFormat('yyyy-MM-dd').format(date),
      totalDistanceKm:
          double.parse((totalDistanceMeters / 1000).toStringAsFixed(2)),
      maxSpeedKmh: double.parse((maxSpeedMs * 3.6).toStringAsFixed(1)),
      totalMovingTimeMinutes: (movingTimeSeconds / 60).round(),
      mostVisitedPlace: mostVisitedPlace,
      mostVisitedCount: mostVisitedCount,
      leftHomeTime: leftHomeTime,
      arrivedHomeTime: arrivedHomeTime,
      locationPointsCount: sorted.length,
      createdAt: DateTime.now(),
    );
  }

  /// Generate timeline events from location history
  List<TimelineEvent> generateTimeline({
    required String userId,
    required DateTime date,
    required List<LocationData> locationPoints,
    List<Geofence>? knownPlaces,
  }) {
    if (locationPoints.length < 2) return [];

    final sorted = List<LocationData>.from(locationPoints)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final events = <TimelineEvent>[];
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // State machine for detecting stops and moves
    double anchorLat = sorted.first.latitude;
    double anchorLng = sorted.first.longitude;
    DateTime segmentStart = sorted.first.timestamp;
    bool isStationary = true;

    for (int i = 1; i < sorted.length; i++) {
      final point = sorted[i];
      final dist = _distanceBetween(
        anchorLat, anchorLng,
        point.latitude, point.longitude,
      );

      if (isStationary) {
        // Currently stationary - check if moved
        if (dist > AppConstants.stopDistanceThreshold) {
          final dwellMinutes =
              point.timestamp.difference(segmentStart).inMinutes;
          if (dwellMinutes >= AppConstants.stopDwellMinutes) {
            // Record stop event
            events.add(TimelineEvent(
              id: const Uuid().v4(),
              userId: userId,
              date: dateStr,
              type: TimelineEventType.stop,
              placeName: _findNearestPlace(
                anchorLat, anchorLng, knownPlaces,
              ),
              latitude: anchorLat,
              longitude: anchorLng,
              startTime: segmentStart,
              endTime: point.timestamp,
              durationMinutes: dwellMinutes,
            ));
          }
          // Switch to moving
          isStationary = false;
          segmentStart = point.timestamp;
          anchorLat = point.latitude;
          anchorLng = point.longitude;
        }
      } else {
        // Currently moving - check if stopped
        final speed = point.speed ?? 0;
        if (speed < 0.5 || dist < AppConstants.stopDistanceThreshold) {
          // Possibly stopped
          final nextPoints = sorted.skip(i).take(3);
          final allSlow = nextPoints.every((p) => (p.speed ?? 0) < 0.5);
          if (allSlow) {
            // Record move event
            final moveDuration =
                point.timestamp.difference(segmentStart).inMinutes;
            if (moveDuration > 1) {
              events.add(TimelineEvent(
                id: const Uuid().v4(),
                userId: userId,
                date: dateStr,
                type: TimelineEventType.move,
                latitude: point.latitude,
                longitude: point.longitude,
                startTime: segmentStart,
                endTime: point.timestamp,
                durationMinutes: moveDuration,
              ));
            }
            // Switch to stationary
            isStationary = true;
            segmentStart = point.timestamp;
            anchorLat = point.latitude;
            anchorLng = point.longitude;
          }
        } else {
          anchorLat = point.latitude;
          anchorLng = point.longitude;
        }
      }
    }

    // Close last segment
    final lastPoint = sorted.last;
    final lastDuration = lastPoint.timestamp.difference(segmentStart).inMinutes;
    if (lastDuration > 0) {
      events.add(TimelineEvent(
        id: const Uuid().v4(),
        userId: userId,
        date: dateStr,
        type: isStationary ? TimelineEventType.stop : TimelineEventType.move,
        placeName: isStationary
            ? _findNearestPlace(anchorLat, anchorLng, knownPlaces)
            : null,
        latitude: lastPoint.latitude,
        longitude: lastPoint.longitude,
        startTime: segmentStart,
        endTime: lastPoint.timestamp,
        durationMinutes: lastDuration,
      ));
    }

    return events;
  }

  /// Find nearest named place
  String? _findNearestPlace(
    double lat,
    double lng,
    List<Geofence>? places,
  ) {
    if (places == null || places.isEmpty) return null;
    for (final place in places) {
      if (_isInsideCircle(lat, lng, place.latitude, place.longitude,
          place.radius)) {
        return place.name;
      }
    }
    return null;
  }

  /// Haversine distance in meters
  double _distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  bool _isInsideCircle(
    double lat,
    double lng,
    double centerLat,
    double centerLng,
    double radiusMeters,
  ) {
    return _distanceBetween(lat, lng, centerLat, centerLng) <= radiusMeters;
  }
}
