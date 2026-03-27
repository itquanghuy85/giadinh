import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/security_event.dart';
import '../../providers/location_provider.dart';

class SecurityAlertsScreen extends StatelessWidget {
  const SecurityAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final events = context.watch<LocationProvider>().securityEvents;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(t('security_alerts'))),
      body: events.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user,
                      size: 64, color: AppTheme.textHint),
                  const SizedBox(height: 16),
                  Text(t('no_security_events'),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = events[index];
                return _SecurityEventCard(event: event);
              },
            ),
    );
  }
}

class _SecurityEventCard extends StatelessWidget {
  final SecurityEvent event;
  const _SecurityEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final timeStr =
        DateFormat('HH:mm dd/MM').format(event.timestamp);

    IconData icon;
    Color color;
    String label;

    switch (event.type) {
      case SecurityEventType.gpsDisabled:
        icon = Icons.gps_off;
        color = AppTheme.errorColor;
        label = t('gps_disabled');
        break;
      case SecurityEventType.gpsEnabled:
        icon = Icons.gps_fixed;
        color = AppTheme.successColor;
        label = t('gps_enabled');
        break;
      case SecurityEventType.permissionRevoked:
        icon = Icons.lock;
        color = AppTheme.errorColor;
        label = t('permission_revoked');
        break;
      case SecurityEventType.simChanged:
        icon = Icons.sim_card;
        color = AppTheme.warningColor;
        label = t('sim_changed');
        break;
      case SecurityEventType.connectionLost:
        icon = Icons.signal_wifi_off;
        color = AppTheme.warningColor;
        label = t('connection_lost_event');
        break;
      case SecurityEventType.connectionRestored:
        icon = Icons.wifi;
        color = AppTheme.successColor;
        label = t('connection_restored');
        break;
      case SecurityEventType.nightMovement:
        icon = Icons.nightlight_round;
        color = AppTheme.sosColor;
        label = t('night_movement');
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(event.description,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(timeStr,
              style: const TextStyle(
                  color: AppTheme.textHint, fontSize: 11)),
        ],
      ),
    );
  }
}
