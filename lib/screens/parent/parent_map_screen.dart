import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/location_data.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/app_user.dart';
import '../../services/routing_service.dart';
import '../../widgets/common_widgets.dart';

class ParentMapScreen extends StatefulWidget {
  const ParentMapScreen({super.key});

  @override
  State<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends State<ParentMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  String? _selectedChildId;

  // Parent's own location
  LatLng? _myLocation;
  bool _loadingMyLocation = true;

  // Cached addresses
  final Map<String, String> _addressCache = {};

  // ── Navigation state ──
  bool _isNavigating = false;
  RouteData? _activeRoute;
  AppUser? _navigationTarget;
  LocationData? _navigationTargetLocation;
  bool _loadingRoute = false;
  int _currentStepIndex = 0;
  bool _showStepsList = false;
  StreamSubscription<geolocator.Position>? _positionStream;
  LatLng? _liveMyLocation;

  static final LatLng _defaultCenter = LatLng(10.8231, 106.6297); // HCMC

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningToChildren();
      _getMyLocation();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _getMyLocation() async {
    setState(() => _loadingMyLocation = true);
    try {
      final hasPermission =
          await geolocator.Geolocator.isLocationServiceEnabled();
      if (!hasPermission) {
        setState(() => _loadingMyLocation = false);
        return;
      }
      var perm = await geolocator.Geolocator.checkPermission();
      if (perm == geolocator.LocationPermission.denied) {
        perm = await geolocator.Geolocator.requestPermission();
      }
      if (perm == geolocator.LocationPermission.denied ||
          perm == geolocator.LocationPermission.deniedForever) {
        setState(() => _loadingMyLocation = false);
        return;
      }

      final pos = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
        _loadingMyLocation = false;
      });

      if (!_isNavigating) {
        _mapController.move(_myLocation!, 14);
      }
    } catch (_) {
      setState(() => _loadingMyLocation = false);
    }
  }

  void _startListeningToChildren() {
    final children = context.read<FamilyProvider>().children;
    final locationProvider = context.read<LocationProvider>();
    locationProvider.listenToFamilyChildren(children);
  }

  /// Calculate distance in km between two LatLng points using Haversine
  double _distanceKm(LatLng from, LatLng to) {
    const Distance distance = Distance();
    final meters = distance.as(LengthUnit.Meter, from, to);
    return meters / 1000.0;
  }

  /// Get address string from lat/lng (cached)
  Future<String> _getAddress(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}';
    if (_addressCache.containsKey(key)) return _addressCache[key]!;

    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          parts.add(p.subLocality!);
        }
        if (p.locality != null && p.locality!.isNotEmpty) {
          parts.add(p.locality!);
        }
        final addr = parts.isNotEmpty ? parts.join(', ') : '$lat, $lng';
        _addressCache[key] = addr;
        return addr;
      }
    } catch (_) {}
    final fallback = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    _addressCache[key] = fallback;
    return fallback;
  }

  /// Open Google Maps navigation
  Future<void> _openNavigation(double destLat, double destLng) async {
    // Try Google Maps first
    final googleUrl = Uri.parse(
        'google.navigation:q=$destLat,$destLng&mode=d');
    final webUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving');

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  // ═══════════════════════════════════════════
  //  IN-APP NAVIGATION
  // ═══════════════════════════════════════════

  /// Start in-app navigation to a child
  Future<void> _startNavigation(AppUser child, LocationData location) async {
    final myLoc = _myLocation;
    if (myLoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('getting_location'))),
      );
      return;
    }

    setState(() {
      _loadingRoute = true;
      _navigationTarget = child;
      _navigationTargetLocation = location;
    });

    final dest = LatLng(location.latitude, location.longitude);
    final route = await RoutingService.getRoute(myLoc, dest);

    if (route == null) {
      setState(() => _loadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).t('route_not_found'))),
        );
      }
      return;
    }

    setState(() {
      _activeRoute = route;
      _isNavigating = true;
      _loadingRoute = false;
      _currentStepIndex = 0;
      _showStepsList = false;
      _liveMyLocation = myLoc;
    });

    _fitRouteBounds(route.points);
    _startLiveTracking();
  }

  /// Stop navigation mode
  void _stopNavigation() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() {
      _isNavigating = false;
      _activeRoute = null;
      _navigationTarget = null;
      _navigationTargetLocation = null;
      _currentStepIndex = 0;
      _showStepsList = false;
      _liveMyLocation = null;
    });
  }

  /// Recalculate route from current position
  Future<void> _recalculateRoute() async {
    final loc = _liveMyLocation ?? _myLocation;
    if (loc == null || _navigationTargetLocation == null) return;

    setState(() => _loadingRoute = true);
    final dest = LatLng(
      _navigationTargetLocation!.latitude,
      _navigationTargetLocation!.longitude,
    );
    final route = await RoutingService.getRoute(loc, dest);

    if (route != null && mounted) {
      setState(() {
        _activeRoute = route;
        _currentStepIndex = 0;
        _loadingRoute = false;
      });
    } else {
      setState(() => _loadingRoute = false);
    }
  }

  /// Start live GPS tracking during navigation
  void _startLiveTracking() {
    _positionStream?.cancel();
    _positionStream = geolocator.Geolocator.getPositionStream(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted || !_isNavigating) return;
      final newLoc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _liveMyLocation = newLoc;
        _myLocation = newLoc;
      });
      _updateCurrentStep(newLoc);
    });
  }

  /// Auto-advance steps when near next step
  void _updateCurrentStep(LatLng currentPos) {
    if (_activeRoute == null) return;
    final steps = _activeRoute!.steps;
    if (_currentStepIndex >= steps.length - 1) return;

    final nextStep = steps[_currentStepIndex + 1];
    final dist = _distanceKm(currentPos, nextStep.location) * 1000;
    if (dist < 30) {
      setState(() => _currentStepIndex++);
    }
  }

  void _fitRouteBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.fromLTRB(60, 120, 60, 280),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final locationProvider = context.read<LocationProvider>();
    final children = context.read<FamilyProvider>().children;
    final markers = <Marker>[];

    // ── Parent "You" marker (use live position during navigation) ──
    final myPos = _liveMyLocation ?? _myLocation;
    if (myPos != null) {
      markers.add(
        Marker(
          point: myPos,
          width: 80,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  AppLocalizations.of(context).t('you'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Child markers ──
    for (final child in children) {
      final location = locationProvider.childLocations[child.uid];
      if (location != null) {
        final childLatLng = LatLng(location.latitude, location.longitude);
        final distKm = myPos != null
            ? _distanceKm(myPos, childLatLng)
            : null;
        final isNavTarget = _isNavigating &&
            _navigationTarget != null &&
            _navigationTarget!.uid == child.uid;

        markers.add(
          Marker(
            point: childLatLng,
            width: 150,
            height: isNavTarget ? 100 : 85,
            child: GestureDetector(
              onTap: () => _showChildDetailSheet(child, location, distKm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isNavTarget ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: isNavTarget
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          child.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isNavTarget
                                  ? Colors.white
                                  : AppTheme.textPrimary),
                        ),
                        if (distKm != null)
                          Text(
                            _formatDistance(distKm),
                            style: TextStyle(
                              fontSize: 10,
                              color: distKm < 1
                                  ? const Color(0xFF4CAF50)
                                  : distKm < 5
                                      ? const Color(0xFFFF9800)
                                      : AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    isNavTarget ? Icons.flag : Icons.location_on,
                    size: isNavTarget ? 40 : 34,
                    color: isNavTarget
                        ? AppTheme.primaryColor
                        : child.isOnline
                            ? AppTheme.primaryColor
                            : AppTheme.errorColor,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // ── Navigation next-step marker ──
    if (_isNavigating && _activeRoute != null) {
      final steps = _activeRoute!.steps;
      if (_currentStepIndex < steps.length - 1) {
        final nextStep = steps[_currentStepIndex + 1];
        markers.add(
          Marker(
            point: nextStep.location,
            width: 36,
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  RoutingService.maneuverIcon(
                    nextStep.maneuverType,
                    nextStep.maneuverModifier,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()} m';
    } else {
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Show detailed bottom sheet for a child with address, distance, and navigation
  void _showChildDetailSheet(
      AppUser child, LocationData location, double? distKm) {
    final t = AppLocalizations.of(context).t;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Name and status
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: child.isOnline
                        ? AppTheme.primaryColor
                        : AppTheme.errorColor,
                    backgroundImage: child.photoUrl != null
                        ? NetworkImage(child.photoUrl!)
                        : null,
                    child: child.photoUrl == null
                        ? Text(
                            child.displayName.isNotEmpty
                                ? child.displayName[0]
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.displayName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        Row(
                          children: [
                            Icon(Icons.circle,
                                size: 8,
                                color: child.isOnline
                                    ? const Color(0xFF4CAF50)
                                    : AppTheme.textHint),
                            const SizedBox(width: 4),
                            Text(
                              child.isOnline ? t('online') : t('offline'),
                              style: TextStyle(
                                  color: child.isOnline
                                      ? const Color(0xFF4CAF50)
                                      : AppTheme.textHint,
                                  fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.battery_std,
                                size: 14, color: AppTheme.textSecondary),
                            Text(' ${location.batteryLevel.toInt()}%',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Distance card
              if (distKm != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: distKm < 1
                          ? [
                              const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              const Color(0xFF4CAF50).withValues(alpha: 0.05)
                            ]
                          : distKm < 5
                              ? [
                                  const Color(0xFFFF9800)
                                      .withValues(alpha: 0.1),
                                  const Color(0xFFFF9800)
                                      .withValues(alpha: 0.05)
                                ]
                              : [
                                  AppTheme.errorColor.withValues(alpha: 0.1),
                                  AppTheme.errorColor.withValues(alpha: 0.05)
                                ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 28,
                        color: distKm < 1
                            ? const Color(0xFF4CAF50)
                            : distKm < 5
                                ? const Color(0xFFFF9800)
                                : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('distance_from_you'),
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                          Text(
                            _formatDistance(distKm),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: distKm < 1
                                  ? const Color(0xFF4CAF50)
                                  : distKm < 5
                                      ? const Color(0xFFFF9800)
                                      : AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Address
              FutureBuilder<String>(
                future: _getAddress(location.latitude, location.longitude),
                builder: (ctx, snap) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place,
                            color: AppTheme.primaryColor, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t('current_location_label'),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                              Text(
                                snap.data ?? t('loading'),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Last seen
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 6),
                  Text(
                    '${t('last_update')}: ${_timeAgo(location.timestamp)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action buttons — in-app nav + external maps
              Row(
                children: [
                  // In-app navigate
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _loadingRoute
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _startNavigation(child, location);
                            },
                      icon: _loadingRoute
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.navigation, size: 20),
                      label: Text(t('navigate_to')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // External Google Maps
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openNavigation(
                            location.latitude, location.longitude);
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(t('google_maps'),
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  List<Polyline> _buildPolylines() {
    final polylines = <Polyline>[];

    // Navigation route (priority)
    if (_isNavigating && _activeRoute != null) {
      polylines.add(
        Polyline(
          points: _activeRoute!.points,
          color: const Color(0xFF4285F4),
          strokeWidth: 6,
          borderColor: const Color(0xFF1A73E8),
          borderStrokeWidth: 2,
        ),
      );
    }

    // History trail (normal mode only)
    if (_selectedChildId != null && !_isNavigating) {
      final locationProvider = context.read<LocationProvider>();
      final history = locationProvider.locationHistories[_selectedChildId];
      if (history != null && history.isNotEmpty) {
        final points =
            history.map((l) => LatLng(l.latitude, l.longitude)).toList();
        polylines.add(
          Polyline(
            points: points,
            color: AppTheme.primaryColor.withValues(alpha: 0.7),
            strokeWidth: 4,
          ),
        );
      }
    }

    return polylines;
  }

  List<CircleMarker> _buildGeofenceCircles() {
    final locationProvider = context.read<LocationProvider>();
    final circles = <CircleMarker>[];

    // My location accuracy circle
    final myPos = _liveMyLocation ?? _myLocation;
    if (myPos != null) {
      circles.add(CircleMarker(
        point: myPos,
        radius: 50,
        useRadiusInMeter: true,
        color: const Color(0xFF1565C0).withValues(alpha: 0.08),
        borderColor: const Color(0xFF1565C0).withValues(alpha: 0.3),
        borderStrokeWidth: 1,
      ));
    }

    // Geofences (hide during navigation for cleaner view)
    if (!_isNavigating) {
      circles.addAll(locationProvider.geofences.map((fence) => CircleMarker(
          point: LatLng(fence.latitude, fence.longitude),
          radius: fence.radius,
          useRadiusInMeter: true,
          color: AppTheme.accentColor.withValues(alpha: 0.1),
          borderColor: AppTheme.accentColor.withValues(alpha: 0.5),
          borderStrokeWidth: 2,
        )));
    }

    return circles;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          Consumer2<LocationProvider, FamilyProvider>(
            builder: (context, locationProv, familyProv, _) {
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _myLocation ?? _defaultCenter,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.huluca.giadinh',
                  ),
                  CircleLayer(circles: _buildGeofenceCircles()),
                  PolylineLayer(polylines: _buildPolylines()),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              );
            },
          ),

          // Top Bar (hide during navigation)
          if (!_isNavigating)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield,
                        color: AppTheme.primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t('family_map'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    // My Location button
                    IconButton(
                      onPressed: () {
                        _getMyLocation();
                      },
                      icon: Icon(
                        Icons.my_location,
                        color: _myLocation != null
                            ? const Color(0xFF1565C0)
                            : AppTheme.textHint,
                      ),
                      tooltip: t('my_location'),
                    ),
                    // Refresh
                    IconButton(
                      onPressed: () {
                        _startListeningToChildren();
                        _getMyLocation();
                      },
                      icon: const Icon(Icons.refresh,
                          color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator for my location
          if (_loadingMyLocation && !_isNavigating)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(t('getting_location'),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // ── NAVIGATION TOP PANEL ──
          if (_isNavigating && _activeRoute != null)
            _buildNavigationTopPanel(t),

          // Loading route indicator
          if (_loadingRoute)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(t('calculating_route'),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),

          // ── NAVIGATION BOTTOM PANEL ──
          if (_isNavigating && _activeRoute != null)
            _buildNavigationBottomPanel(t),

          // ── STEP-BY-STEP LIST ──
          if (_isNavigating && _showStepsList && _activeRoute != null)
            _buildStepsList(t),

          // Bottom Children List (normal mode only)
          if (!_isNavigating)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer2<FamilyProvider, LocationProvider>(
                    builder: (context, familyProv, locationProv, _) {
                      final children = familyProv.children;
                      if (children.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '${t('no_children')}\n${t('share_code')}',
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: AppTheme.textSecondary),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: children.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final child = children[index];
                            final location =
                                locationProv.childLocations[child.uid];
                            final distKm = (_myLocation != null &&
                                    location != null)
                                ? _distanceKm(
                                    _myLocation!,
                                    LatLng(location.latitude,
                                        location.longitude))
                                : null;

                            return _ChildChip(
                              child: child,
                              batteryLevel:
                                  location?.batteryLevel ?? child.batteryLevel,
                              isSelected: _selectedChildId == child.uid,
                              distanceKm: distKm,
                              hasLocation: location != null,
                              onTap: () {
                                setState(() {
                                  _selectedChildId =
                                      _selectedChildId == child.uid
                                          ? null
                                          : child.uid;
                                });
                                if (location != null) {
                                  _mapController.move(
                                    LatLng(location.latitude,
                                        location.longitude),
                                    16,
                                  );
                                }
                              },
                              onNavigate: location != null
                                  ? () => _showChildDetailSheet(
                                      child, location, distKm)
                                  : null,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final t = AppLocalizations.of(context).t;
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return t('just_now');
    if (diff.inMinutes < 60) return t('min_ago', ['${diff.inMinutes}']);
    if (diff.inHours < 24) return t('hour_ago', ['${diff.inHours}']);
    return t('day_ago', ['${diff.inDays}']);
  }

  // ═══════════════════════════════════════════
  //  NAVIGATION UI BUILDERS
  // ═══════════════════════════════════════════

  /// Top panel: current step instruction + ETA
  Widget _buildNavigationTopPanel(
      String Function(String, [List<String>?]) t) {
    final route = _activeRoute!;
    final steps = route.steps;
    final currentStep =
        _currentStepIndex < steps.length ? steps[_currentStepIndex] : null;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    if (currentStep != null)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            RoutingService.maneuverIcon(
                              currentStep.maneuverType,
                              currentStep.maneuverModifier,
                            ),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentStep != null) ...[
                            Text(
                              currentStep.instruction,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentStep.formattedDistance,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _stopNavigation,
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              // ETA bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          t('eta_minutes', ['${route.durationMinutes}']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.straighten,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _formatDistance(route.distanceKm),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '→ ${_navigationTarget?.displayName ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom panel: action buttons during navigation
  Widget _buildNavigationBottomPanel(
      String Function(String, [List<String>?]) t) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _showStepsList = !_showStepsList),
                icon: Icon(
                  _showStepsList
                      ? Icons.expand_less
                      : Icons.format_list_numbered,
                  size: 20,
                ),
                label: Text(t('all_steps')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _loadingRoute ? null : _recalculateRoute,
              icon: _loadingRoute
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.alt_route),
              tooltip: t('recalculate'),
              style: IconButton.styleFrom(
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _fitRouteBounds(_activeRoute!.points),
              icon: const Icon(Icons.zoom_out_map),
              tooltip: t('fit_route'),
              style: IconButton.styleFrom(
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_navigationTargetLocation != null) {
                  _openNavigation(
                    _navigationTargetLocation!.latitude,
                    _navigationTargetLocation!.longitude,
                  );
                }
              },
              icon: const Icon(Icons.open_in_new),
              tooltip: t('google_maps'),
              style: IconButton.styleFrom(
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _stopNavigation,
              icon: const Icon(Icons.close),
              tooltip: t('stop_nav'),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                foregroundColor: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full step-by-step directions list
  Widget _buildStepsList(String Function(String, [List<String>?]) t) {
    final steps = _activeRoute!.steps;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 80 + MediaQuery.of(context).padding.bottom,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.directions,
                      color: AppTheme.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t('turn_by_turn'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${steps.length} ${t('steps_label')}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () =>
                        setState(() => _showStepsList = false),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: steps.length,
                separatorBuilder: (_, i) =>
                    const Divider(height: 1, indent: 60),
                itemBuilder: (ctx, index) {
                  final step = steps[index];
                  final isCurrent = index == _currentStepIndex;
                  final isPast = index < _currentStepIndex;

                  return Material(
                    color: isCurrent
                        ? AppTheme.primaryColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => _mapController.move(step.location, 17),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppTheme.primaryColor
                                    : isPast
                                        ? AppTheme.successColor
                                            .withValues(alpha: 0.1)
                                        : AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: isPast
                                    ? const Icon(Icons.check,
                                        size: 16,
                                        color: AppTheme.successColor)
                                    : Text(
                                        RoutingService.maneuverIcon(
                                          step.maneuverType,
                                          step.maneuverModifier,
                                        ),
                                        style:
                                            const TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.instruction,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCurrent
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isPast
                                          ? AppTheme.textHint
                                          : AppTheme.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (step.streetName != null)
                                    Text(
                                      step.streetName!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  step.formattedDistance,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isPast
                                        ? AppTheme.textHint
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  step.formattedDuration,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildChip extends StatelessWidget {
  final AppUser child;
  final double batteryLevel;
  final bool isSelected;
  final double? distanceKm;
  final bool hasLocation;
  final VoidCallback onTap;
  final VoidCallback? onNavigate;

  const _ChildChip({
    required this.child,
    required this.batteryLevel,
    required this.isSelected,
    required this.hasLocation,
    required this.onTap,
    this.distanceKm,
    this.onNavigate,
  });

  String _formatDist(double km) {
    if (km < 1) return '${(km * 1000).toInt()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 165,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: child.isOnline
                      ? AppTheme.primaryColor
                      : AppTheme.errorColor,
                  backgroundImage: child.photoUrl != null
                      ? NetworkImage(child.photoUrl!)
                      : null,
                  child: child.photoUrl == null
                      ? Text(
                          child.displayName.isNotEmpty
                              ? child.displayName[0]
                              : '?',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    child.displayName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                StatusChip(isOnline: child.isOnline),
                const SizedBox(width: 6),
                BatteryIndicator(level: batteryLevel),
              ],
            ),
            const SizedBox(height: 4),
            // Distance + navigate row
            if (hasLocation)
              Row(
                children: [
                  if (distanceKm != null) ...[
                    Icon(Icons.straighten,
                        size: 12,
                        color: distanceKm! < 1
                            ? const Color(0xFF4CAF50)
                            : distanceKm! < 5
                                ? const Color(0xFFFF9800)
                                : AppTheme.errorColor),
                    const SizedBox(width: 3),
                    Text(
                      _formatDist(distanceKm!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: distanceKm! < 1
                            ? const Color(0xFF4CAF50)
                            : distanceKm! < 5
                                ? const Color(0xFFFF9800)
                                : AppTheme.errorColor,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (onNavigate != null)
                    GestureDetector(
                      onTap: onNavigate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.navigation,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(t('go'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            else
              Text(t('no_location_data'),
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}
