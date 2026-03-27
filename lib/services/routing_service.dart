import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Route data returned by OSRM API
class RouteData {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final List<RouteStep> steps;

  RouteData({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.steps,
  });
}

/// A single turn-by-turn step
class RouteStep {
  final String instruction;
  final String maneuverType;
  final String? maneuverModifier;
  final double distanceMeters;
  final int durationSeconds;
  final LatLng location;
  final String? streetName;

  RouteStep({
    required this.instruction,
    required this.maneuverType,
    this.maneuverModifier,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.location,
    this.streetName,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toInt()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    if (durationSeconds < 60) return '< 1 min';
    final mins = durationSeconds ~/ 60;
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }
}

/// Service to fetch routes using OSRM (free, no API key)
class RoutingService {
  static const _baseUrl = 'https://router.project-osrm.org';

  /// Fetch driving route between two points
  static Future<RouteData?> getRoute(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['code'] != 'Ok' || data['routes'] == null) return null;

      final route = data['routes'][0];

      // Parse geometry (GeoJSON LineString)
      final coords = route['geometry']['coordinates'] as List;
      final points = coords.map<LatLng>((c) {
        return LatLng(c[1].toDouble(), c[0].toDouble());
      }).toList();

      // Parse summary
      final distanceKm = (route['distance'] as num).toDouble() / 1000;
      final durationMinutes = ((route['duration'] as num).toDouble() / 60).ceil();

      // Parse steps
      final legs = route['legs'] as List;
      final steps = <RouteStep>[];
      for (final leg in legs) {
        for (final step in leg['steps'] as List) {
          final maneuver = step['maneuver'];
          final loc = maneuver['location'] as List;

          steps.add(RouteStep(
            instruction: _buildInstruction(
              maneuver['type'] ?? '',
              maneuver['modifier'] ?? '',
              step['name'] ?? '',
            ),
            maneuverType: maneuver['type'] ?? '',
            maneuverModifier: maneuver['modifier'],
            distanceMeters: (step['distance'] as num).toDouble(),
            durationSeconds: (step['duration'] as num).toInt(),
            location: LatLng(loc[1].toDouble(), loc[0].toDouble()),
            streetName: step['name']?.toString().isNotEmpty == true
                ? step['name']
                : null,
          ));
        }
      }

      return RouteData(
        points: points,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        steps: steps,
      );
    } catch (_) {
      return null;
    }
  }

  /// Build a human-readable instruction from OSRM maneuver data
  static String _buildInstruction(
      String type, String modifier, String name) {
    final street = name.isNotEmpty ? ' → $name' : '';

    switch (type) {
      case 'depart':
        return 'Depart$street';
      case 'arrive':
        return 'Arrive at destination';
      case 'turn':
        return '${_modifierText(modifier)}$street';
      case 'new name':
        return 'Continue$street';
      case 'merge':
        return 'Merge$street';
      case 'on ramp':
      case 'off ramp':
        return '${_modifierText(modifier)}$street';
      case 'fork':
        return 'Fork ${modifier.isNotEmpty ? modifier : 'ahead'}$street';
      case 'end of road':
        return '${_modifierText(modifier)}$street';
      case 'continue':
        return 'Continue$street';
      case 'roundabout':
      case 'rotary':
        return 'Enter roundabout$street';
      case 'roundabout turn':
        return '${_modifierText(modifier)}$street';
      case 'notification':
        return name.isNotEmpty ? name : 'Continue';
      case 'exit roundabout':
      case 'exit rotary':
        return 'Exit roundabout$street';
      default:
        return modifier.isNotEmpty
            ? '${_modifierText(modifier)}$street'
            : 'Continue$street';
    }
  }

  static String _modifierText(String modifier) {
    switch (modifier) {
      case 'left':
        return 'Turn left';
      case 'right':
        return 'Turn right';
      case 'sharp left':
        return 'Sharp left';
      case 'sharp right':
        return 'Sharp right';
      case 'slight left':
        return 'Slight left';
      case 'slight right':
        return 'Slight right';
      case 'straight':
        return 'Go straight';
      case 'uturn':
        return 'U-turn';
      default:
        return 'Continue';
    }
  }

  /// Get the appropriate icon for a maneuver
  static String maneuverIcon(String type, String? modifier) {
    switch (type) {
      case 'depart':
        return '🚗';
      case 'arrive':
        return '🏁';
      case 'roundabout':
      case 'rotary':
        return '🔄';
      default:
        switch (modifier) {
          case 'left':
          case 'sharp left':
          case 'slight left':
            return '⬅️';
          case 'right':
          case 'sharp right':
          case 'slight right':
            return '➡️';
          case 'uturn':
            return '↩️';
          case 'straight':
          default:
            return '⬆️';
        }
    }
  }
}
