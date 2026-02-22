import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/geofence.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/common_widgets.dart';

class ParentGeofenceScreen extends StatelessWidget {
  const ParentGeofenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Safe Zones',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Create safe zones and get notified when your child enters or leaves.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Consumer<LocationProvider>(
                builder: (context, locationProv, _) {
                  final geofences = locationProv.geofences;

                  if (geofences.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radar,
                              size: 80,
                              color: AppTheme.textHint.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text(
                            'No safe zones yet',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap + to create your first safe zone',
                            style: TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: geofences.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final fence = geofences[index];
                      return _GeofenceCard(fence: fence);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGeofenceDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Zone'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddGeofenceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final radiusController =
        TextEditingController(text: '200');
    LatLng? selectedLocation;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Safe Zone',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            hintText: 'Zone name (e.g. Home, School)',
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: radiusController,
                          decoration: const InputDecoration(
                            hintText: 'Radius in meters',
                            prefixIcon: Icon(Icons.radar),
                            suffixText: 'meters',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap on map to select location:',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map
                  Expanded(
                    child: ClipRRect(
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(10.8231, 106.6297),
                          zoom: 14,
                        ),
                        onTap: (latLng) {
                          setState(() {
                            selectedLocation = latLng;
                          });
                        },
                        markers: selectedLocation != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: selectedLocation!,
                                ),
                              }
                            : {},
                        circles: selectedLocation != null
                            ? {
                                Circle(
                                  circleId: const CircleId('preview'),
                                  center: selectedLocation!,
                                  radius: double.tryParse(
                                          radiusController.text) ??
                                      200,
                                  fillColor: AppTheme.primaryColor
                                      .withValues(alpha: 0.15),
                                  strokeColor: AppTheme.primaryColor,
                                  strokeWidth: 2,
                                ),
                              }
                            : {},
                        zoomControlsEnabled: false,
                      ),
                    ),
                  ),

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: GradientButton(
                      text: 'Create Safe Zone',
                      icon: Icons.check,
                      onPressed: selectedLocation != null &&
                              nameController.text.isNotEmpty
                          ? () {
                              final auth = ctx.read<AuthProvider>();
                              final locationProv =
                                  ctx.read<LocationProvider>();

                              final geofence = Geofence(
                                id: const Uuid().v4(),
                                familyId: auth.currentUser!.familyId!,
                                name: nameController.text.trim(),
                                latitude: selectedLocation!.latitude,
                                longitude: selectedLocation!.longitude,
                                radius:
                                    double.tryParse(radiusController.text) ??
                                        AppConstants.defaultGeofenceRadius,
                                createdBy: auth.currentUser!.uid,
                                createdAt: DateTime.now(),
                              );

                              locationProv.createGeofence(geofence);
                              Navigator.of(ctx).pop();
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _GeofenceCard extends StatelessWidget {
  final Geofence fence;

  const _GeofenceCard({required this.fence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.radar,
                color: AppTheme.accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fence.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Radius: ${fence.radius.toInt()}m',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<LocationProvider>().deleteGeofence(fence.id);
            },
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.errorColor, size: 22),
          ),
        ],
      ),
    );
  }
}
