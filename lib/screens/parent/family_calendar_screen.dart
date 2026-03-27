import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/family_event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

class FamilyCalendarScreen extends StatelessWidget {
  const FamilyCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final locationProv = context.watch<LocationProvider>();
    final now = DateTime.now();
    final events = locationProv.familyEvents;

    // Split into upcoming and past
    final upcoming =
        events.where((e) => e.eventTime.isAfter(now)).toList();
    final past =
        events.where((e) => !e.eventTime.isAfter(now)).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(t('family_calendar'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: events.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 64, color: AppTheme.textHint),
                  const SizedBox(height: 16),
                  Text(t('no_events'),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(t('tap_add_event'),
                      style: const TextStyle(
                          color: AppTheme.textHint, fontSize: 14)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(title: t('upcoming_events')),
                  const SizedBox(height: 8),
                  ...upcoming
                      .map((e) => _EventCard(event: e, isPast: false)),
                  const SizedBox(height: 20),
                ],
                if (past.isNotEmpty) ...[
                  _SectionHeader(title: t('past_events')),
                  const SizedBox(height: 8),
                  ...past
                      .map((e) => _EventCard(event: e, isPast: true)),
                ],
              ],
            ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('add_event'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: t('event_title'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: t('event_location_optional'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              ));
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(selectedTime.format(ctx)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final auth = context.read<AuthProvider>();
                    final event = FamilyEvent(
                      id: const Uuid().v4(),
                      familyId: auth.currentUser!.familyId!,
                      title: titleCtrl.text.trim(),
                      location: locationCtrl.text.trim().isNotEmpty
                          ? locationCtrl.text.trim()
                          : null,
                      eventTime: selectedDate,
                      createdBy: auth.currentUser!.uid,
                      createdAt: DateTime.now(),
                    );
                    context.read<LocationProvider>().createFamilyEvent(event);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(t('create_event')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final FamilyEvent event;
  final bool isPast;
  const _EventCard({required this.event, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final timeStr = DateFormat('HH:mm').format(event.eventTime);
    final dateStr = DateFormat('dd/MM/yyyy').format(event.eventTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: isPast
            ? Border.all(color: AppTheme.dividerColor)
            : Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        boxShadow: isPast
            ? null
            : [
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
              color: (isPast ? AppTheme.textHint : AppTheme.primaryColor)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.event,
              color: isPast ? AppTheme.textHint : AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color:
                        isPast ? AppTheme.textHint : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr ${t("at_time")} $timeStr',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '📍 ${event.location}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isPast)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.errorColor, size: 20),
              onPressed: () => context
                  .read<LocationProvider>()
                  .deleteFamilyEvent(event.id),
            ),
        ],
      ),
    );
  }
}
