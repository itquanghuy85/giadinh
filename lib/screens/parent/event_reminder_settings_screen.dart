import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/location_provider.dart';

class EventReminderSettingsScreen extends StatelessWidget {
  const EventReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final loc = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('event_reminder_settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              t('event_reminder_settings_desc'),
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _TileCard(
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t('enable_event_reminders'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch(
                  value: loc.eventReminderEnabled,
                  activeTrackColor:
                      AppTheme.primaryColor.withValues(alpha: 0.5),
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (v) {
                    context.read<LocationProvider>().setEventReminderEnabled(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _TileCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('reminder_time_points'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _StageSwitch(minutes: 60),
                const Divider(height: 1),
                _StageSwitch(minutes: 15),
                const Divider(height: 1),
                _StageSwitch(minutes: 5),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _TileCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.textHint),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t('event_reminder_note'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  final Widget child;

  const _TileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: child,
    );
  }
}

class _StageSwitch extends StatelessWidget {
  final int minutes;

  const _StageSwitch({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final loc = context.watch<LocationProvider>();
    final enabled = loc.eventReminderStages.contains(minutes);

    return Row(
      children: [
        const Icon(Icons.schedule_rounded, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            t('event_reminder_before_min', ['$minutes']),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Switch(
          value: enabled,
          activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          activeThumbColor: AppTheme.primaryColor,
          onChanged: loc.eventReminderEnabled
              ? (v) {
                  context
                      .read<LocationProvider>()
                      .setEventReminderStageEnabled(minutes, v);
                }
              : null,
        ),
      ],
    );
  }
}
