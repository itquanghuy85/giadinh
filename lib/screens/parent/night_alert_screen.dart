import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/location_provider.dart';

class NightAlertScreen extends StatelessWidget {
  const NightAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final locationProv = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(t('night_alert'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                children: [
                  const Icon(Icons.nightlight_round,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(t('night_alert'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(t('night_alert_desc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Enable toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.cardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_moon,
                      color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('enable_night_alert'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(t('night_alert_toggle_desc'),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: locationProv.nightAlertEnabled,
                    activeTrackColor:
                        AppTheme.primaryColor.withValues(alpha: 0.5),
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) =>
                        locationProv.setNightAlertEnabled(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time configuration
            if (locationProv.nightAlertEnabled) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.cardShadow,
                        blurRadius: 10,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('night_time_window'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerTile(
                            label: t('night_start'),
                            hour: locationProv.nightStartHour,
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: locationProv.nightStartHour,
                                    minute: 0),
                              );
                              if (time != null) {
                                locationProv.setNightAlertHours(
                                    time.hour, locationProv.nightEndHour);
                              }
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward,
                              color: AppTheme.textHint),
                        ),
                        Expanded(
                          child: _TimePickerTile(
                            label: t('night_end'),
                            hour: locationProv.nightEndHour,
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: locationProv.nightEndHour,
                                    minute: 0),
                              );
                              if (time != null) {
                                locationProv.setNightAlertHours(
                                    locationProv.nightStartHour, time.hour);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.warningColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t('night_alert_info'),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final int hour;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.hour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
