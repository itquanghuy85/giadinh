import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
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
    final t = AppLocalizations.of(context).t;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                t('safe_zones'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                t('safe_zones_desc'),
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
                          Text(
                            t('no_safe_zones'),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('tap_add_zone'),
                            style: const TextStyle(
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
        label: Text(t('add_zone')),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddGeofenceDialog(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final nameController = TextEditingController();
    final radiusController =
        TextEditingController(text: '200');
    LatLng? selectedLocation;
    bool nameNotEmpty = false;

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
                        Text(
                          t('add_safe_zone'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: t('zone_name_hint'),
                            prefixIcon: const Icon(Icons.label_outline),
                          ),
                          onChanged: (val) {
                            setState(() {
                              nameNotEmpty = val.trim().isNotEmpty;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: radiusController,
                          decoration: InputDecoration(
                            hintText: t('radius_hint'),
                            prefixIcon: const Icon(Icons.radar),
                            suffixText: t('meters'),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t('tap_map'),
                          style: const TextStyle(
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
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(10.8231, 106.6297),
                          initialZoom: 14,
                          onTap: (tapPos, latLng) {
                            setState(() {
                              selectedLocation = latLng;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.huluca.giadinh',
                          ),
                          if (selectedLocation != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: selectedLocation!,
                                  radius: double.tryParse(
                                          radiusController.text) ??
                                      200,
                                  useRadiusInMeter: true,
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.15),
                                  borderColor: AppTheme.primaryColor,
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                          if (selectedLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: selectedLocation!,
                                  child: const Icon(Icons.location_on,
                                      color: AppTheme.primaryColor, size: 36),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: GradientButton(
                      text: t('create_safe_zone'),
                      icon: Icons.check,
                      onPressed: selectedLocation != null && nameNotEmpty
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
    final t = AppLocalizations.of(context).t;
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
                  '${t('radius_hint')}: ${fence.radius.toInt()}m',
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
