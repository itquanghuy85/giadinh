import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/danger_zone.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

class DangerZoneScreen extends StatelessWidget {
  const DangerZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final locProv = context.watch<LocationProvider>();
    final zones = locProv.dangerZones;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('danger_zones'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('danger_zones_desc'),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FloatingActionButton.small(
                    heroTag: 'add_danger',
                    backgroundColor: AppTheme.errorColor,
                    onPressed: () => _showAddDialog(context, t),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: zones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 64,
                              color:
                                  AppTheme.warningColor.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            t('no_danger_zones'),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('tap_add_danger'),
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: zones.length,
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        return _DangerZoneTile(
                          zone: zone,
                          t: t,
                          onDelete: () {
                            context
                                .read<LocationProvider>()
                                .deleteDangerZone(zone.id);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(
      BuildContext context, String Function(String, [List<String>?]) t) {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController(text: '200');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('add_danger_zone')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t('danger_zone_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      decoration: InputDecoration(
                        labelText: t('latitude'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      decoration: InputDecoration(
                        labelText: t('longitude'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: radiusController,
                decoration: InputDecoration(
                  labelText: '${t('radius_hint')} (${t('meters')})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              final radius = double.tryParse(radiusController.text.trim());

              if (name.isEmpty || lat == null || lng == null || radius == null) {
                return;
              }

              final auth = context.read<AuthProvider>();
              final zone = DangerZone(
                id: const Uuid().v4(),
                familyId: auth.currentUser!.familyId!,
                name: name,
                latitude: lat,
                longitude: lng,
                radius: radius,
                createdBy: auth.currentUser!.uid,
                createdAt: DateTime.now(),
              );

              context.read<LocationProvider>().createDangerZone(zone);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(t('create_danger_zone'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DangerZoneTile extends StatelessWidget {
  final DangerZone zone;
  final String Function(String, [List<String>?]) t;
  final VoidCallback onDelete;

  const _DangerZoneTile({
    required this.zone,
    required this.t,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t('radius', ['${zone.radius.toInt()}']),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.errorColor, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
