import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/app_user.dart';
import '../../widgets/common_widgets.dart';

class ParentMapScreen extends StatefulWidget {
  const ParentMapScreen({super.key});

  @override
  State<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends State<ParentMapScreen> {
  GoogleMapController? _mapController;
  String? _selectedChildId;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(10.8231, 106.6297), // Ho Chi Minh City default
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningToChildren();
    });
  }

  void _startListeningToChildren() {
    final children = context.read<FamilyProvider>().children;
    final locationProvider = context.read<LocationProvider>();
    locationProvider.listenToFamilyChildren(children);
  }

  Set<Marker> _buildMarkers() {
    final locationProvider = context.read<LocationProvider>();
    final children = context.read<FamilyProvider>().children;
    final markers = <Marker>{};

    for (final child in children) {
      final location = locationProvider.childLocations[child.uid];
      if (location != null) {
        markers.add(
          Marker(
            markerId: MarkerId(child.uid),
            position: LatLng(location.latitude, location.longitude),
            infoWindow: InfoWindow(
              title: child.displayName,
              snippet:
                  'Battery: ${location.batteryLevel.toInt()}% • ${_timeAgo(location.timestamp)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              child.isOnline
                  ? BitmapDescriptor.hueAzure
                  : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_selectedChildId == null) return {};

    final locationProvider = context.read<LocationProvider>();
    final history = locationProvider.locationHistories[_selectedChildId];
    if (history == null || history.isEmpty) return {};

    final points =
        history.map((l) => LatLng(l.latitude, l.longitude)).toList();

    return {
      Polyline(
        polylineId: PolylineId(_selectedChildId!),
        points: points,
        color: AppTheme.primaryColor.withValues(alpha: 0.7),
        width: 4,
        patterns: [PatternItem.dash(10), PatternItem.gap(5)],
      ),
    };
  }

  Set<Circle> _buildGeofenceCircles() {
    final locationProvider = context.read<LocationProvider>();
    return locationProvider.geofences
        .map((fence) => Circle(
              circleId: CircleId(fence.id),
              center: LatLng(fence.latitude, fence.longitude),
              radius: fence.radius,
              fillColor: AppTheme.accentColor.withValues(alpha: 0.1),
              strokeColor: AppTheme.accentColor.withValues(alpha: 0.5),
              strokeWidth: 2,
            ))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          Consumer2<LocationProvider, FamilyProvider>(
            builder: (context, locationProv, familyProv, _) {
              return GoogleMap(
                initialCameraPosition: _defaultPosition,
                onMapCreated: (controller) => _mapController = controller,
                markers: _buildMarkers(),
                polylines: _buildPolylines(),
                circles: _buildGeofenceCircles(),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                padding: const EdgeInsets.only(top: 120, bottom: 100),
              );
            },
          ),

          // Top Bar
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
                    const Expanded(
                      child: Text(
                        'Family Map',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    // Refresh
                    IconButton(
                      onPressed: _startListeningToChildren,
                      icon: const Icon(Icons.refresh,
                          color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Children List
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
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No children connected yet.\nShare your family code to add members.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: children.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final child = children[index];
                            final location =
                                locationProv.childLocations[child.uid];
                            return _ChildChip(
                              child: child,
                              batteryLevel:
                                  location?.batteryLevel ?? child.batteryLevel,
                              isSelected: _selectedChildId == child.uid,
                              onTap: () {
                                setState(() {
                                  _selectedChildId =
                                      _selectedChildId == child.uid
                                          ? null
                                          : child.uid;
                                });
                                if (location != null) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      LatLng(location.latitude,
                                          location.longitude),
                                      16,
                                    ),
                                  );
                                }
                              },
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
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ChildChip extends StatelessWidget {
  final AppUser child;
  final double batteryLevel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChildChip({
    required this.child,
    required this.batteryLevel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryColor,
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
                Text(
                  child.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusChip(isOnline: child.isOnline),
                const SizedBox(width: 8),
                BatteryIndicator(level: batteryLevel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
