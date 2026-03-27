import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/family_event.dart';
import '../../models/security_event.dart';
import '../../models/schedule_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_provider.dart';
import 'family_calendar_screen.dart';
import 'parent_map_screen.dart';
import 'schedule_screen.dart';
import 'security_alerts_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  _AgendaWindow _agendaWindow = _AgendaWindow.today;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final auth = context.watch<AuthProvider>();
    final family = context.watch<FamilyProvider>();
    final location = context.watch<LocationProvider>();

    final children = family.children;
    final onlineChildren = children.where((c) => c.isOnline).length;
    final offlineChildren = children.length - onlineChildren;
    final upcomingEvents = location.familyEvents
        .where((e) => e.eventTime.isAfter(_now))
        .toList()
      ..sort((a, b) => a.eventTime.compareTo(b.eventTime));
    final todayAlerts = location.securityEvents
        .where((e) => _isSameDay(e.timestamp, _now))
        .length;

    final agenda = _buildAgendaItems(
      t: t,
      schedule: location.scheduleConfig,
      events: location.familyEvents,
      now: _now,
      window: _agendaWindow,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (auth.currentUser?.familyId != null) {
              context
                  .read<LocationProvider>()
                  .listenToFamilyEvents(auth.currentUser!.familyId!);
              context
                  .read<LocationProvider>()
                  .listenToSecurityEvents(auth.currentUser!.familyId!);
            }
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildHeader(
                t,
                userName: auth.currentUser?.displayName ?? 'Parent',
                familyName: auth.currentFamily?.name ?? '',
              ),
              const SizedBox(height: 16),
              _buildReminderBanner(t),
              const SizedBox(height: 14),
              _buildStatsGrid(
                t,
                onlineChildren: onlineChildren,
                offlineChildren: offlineChildren,
                upcomingCount: upcomingEvents.length,
                todayAlerts: todayAlerts,
              ),
              const SizedBox(height: 18),
              _buildSectionTitle(t('home_quick_actions')),
              const SizedBox(height: 10),
              _buildQuickActions(t),
              const SizedBox(height: 18),
              _buildSectionTitle(t('home_agenda_today')),
              const SizedBox(height: 10),
              _buildAgendaFilters(t),
              const SizedBox(height: 10),
              _buildAgendaList(t, agenda),
              const SizedBox(height: 18),
              _buildSectionTitle(t('home_recent_alerts')),
              const SizedBox(height: 10),
              _buildRecentAlerts(t, location.securityEvents, family),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    String Function(String, [List<String>?]) t, {
    required String userName,
    required String familyName,
  }) {
    final dateText = DateFormat('EEE, dd MMM yyyy').format(_now);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Icon(Icons.home_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('home_welcome_parent', [userName]),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  familyName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderBanner(String Function(String, [List<String>?]) t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: Color(0xFFFF8F00), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t('home_reminder_info'),
              style: const TextStyle(
                color: Color(0xFF6D4C41),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    String Function(String, [List<String>?]) t, {
    required int onlineChildren,
    required int offlineChildren,
    required int upcomingCount,
    required int todayAlerts,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          icon: Icons.wifi_tethering_rounded,
          label: t('home_online_children'),
          value: '$onlineChildren',
          color: const Color(0xFF2E7D32),
        ),
        _StatCard(
          icon: Icons.wifi_off_rounded,
          label: t('home_offline_children'),
          value: '$offlineChildren',
          color: const Color(0xFFC62828),
        ),
        _StatCard(
          icon: Icons.event_available_rounded,
          label: t('home_upcoming_events'),
          value: '$upcomingCount',
          color: const Color(0xFF1565C0),
        ),
        _StatCard(
          icon: Icons.warning_amber_rounded,
          label: t('home_security_today'),
          value: '$todayAlerts',
          color: const Color(0xFFEF6C00),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildQuickActions(String Function(String, [List<String>?]) t) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ActionChip(
          icon: Icons.add_circle_outline_rounded,
          label: t('home_quick_add_event'),
          onTap: () => _showQuickAddEvent(),
        ),
        _ActionChip(
          icon: Icons.map_rounded,
          label: t('map'),
          onTap: () => _open(context, const ParentMapScreen()),
        ),
        _ActionChip(
          icon: Icons.calendar_month_rounded,
          label: t('family_calendar'),
          onTap: () => _open(context, const FamilyCalendarScreen()),
        ),
        _ActionChip(
          icon: Icons.schedule_rounded,
          label: t('smart_schedule'),
          onTap: () => _open(context, const ScheduleScreen()),
        ),
        _ActionChip(
          icon: Icons.security_rounded,
          label: t('security_alerts'),
          onTap: () => _open(context, const SecurityAlertsScreen()),
        ),
      ],
    );
  }

  Widget _buildAgendaFilters(String Function(String, [List<String>?]) t) {
    return Row(
      children: [
        _FilterChip(
          label: t('today'),
          selected: _agendaWindow == _AgendaWindow.today,
          onTap: () => setState(() => _agendaWindow = _AgendaWindow.today),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: t('home_filter_3days'),
          selected: _agendaWindow == _AgendaWindow.threeDays,
          onTap: () => setState(() => _agendaWindow = _AgendaWindow.threeDays),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: t('home_filter_7days'),
          selected: _agendaWindow == _AgendaWindow.sevenDays,
          onTap: () => setState(() => _agendaWindow = _AgendaWindow.sevenDays),
        ),
      ],
    );
  }

  Widget _buildAgendaList(
    String Function(String, [List<String>?]) t,
    List<_AgendaItem> agenda,
  ) {
    if (agenda.isEmpty) {
      return _EmptyCard(message: t('home_no_agenda'));
    }

    return Column(
      children: agenda.take(8).map((item) {
        final mins = item.time.difference(_now).inMinutes;
        final isSoon = mins >= 0 && mins <= 60;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSoon ? const Color(0xFFFFB300) : AppTheme.dividerColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.kind == _AgendaKind.event
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('dd/MM HH:mm').format(item.time),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _timeUntilLabel(t, item.time),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isSoon ? const Color(0xFFFF8F00) : AppTheme.textSecondary,
                      fontWeight: isSoon ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentAlerts(
    String Function(String, [List<String>?]) t,
    List<SecurityEvent> events,
    FamilyProvider family,
  ) {
    if (events.isEmpty) {
      return _EmptyCard(message: t('no_security_events'));
    }

    final names = {
      for (final c in family.children) c.uid: c.displayName,
      for (final m in family.members) m.uid: m.displayName,
    };

    return Column(
      children: events.take(5).map((e) {
        final childName = names[e.userId] ?? e.userId;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(_iconForSecurity(e.type), size: 20, color: _colorForSecurity(e.type)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelForSecurity(t, e.type),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      childName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('HH:mm').format(e.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<_AgendaItem> _buildAgendaItems({
    required String Function(String, [List<String>?]) t,
    required ScheduleConfig? schedule,
    required List<FamilyEvent> events,
    required DateTime now,
    required _AgendaWindow window,
  }) {
    final items = <_AgendaItem>[];

    DateTime rangeEnd;
    switch (window) {
      case _AgendaWindow.today:
        rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case _AgendaWindow.threeDays:
        rangeEnd = now.add(const Duration(days: 3));
        break;
      case _AgendaWindow.sevenDays:
        rangeEnd = now.add(const Duration(days: 7));
        break;
    }

    for (final e in events) {
      final inRange = e.eventTime.isAfter(now.subtract(const Duration(hours: 1))) &&
          e.eventTime.isBefore(rangeEnd);
      if (inRange) {
        items.add(
          _AgendaItem(
            kind: _AgendaKind.event,
            title: e.title,
            subtitle: e.location,
            time: e.eventTime,
          ),
        );
      }
    }

    if (schedule != null && schedule.isEnabled && window == _AgendaWindow.today) {
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        schedule.schoolStartHour,
        schedule.schoolStartMinute,
      );
      final end = DateTime(
        now.year,
        now.month,
        now.day,
        schedule.schoolEndHour,
        schedule.schoolEndMinute,
      );

      if (end.isAfter(now.subtract(const Duration(hours: 2)))) {
        items.add(
          _AgendaItem(
            kind: _AgendaKind.schedule,
            title: t('home_school_mode_start'),
            subtitle: '${schedule.schoolIntervalSeconds}s interval',
            time: start,
          ),
        );
        items.add(
          _AgendaItem(
            kind: _AgendaKind.schedule,
            title: t('home_school_mode_end'),
            subtitle: '${schedule.offHoursIntervalSeconds}s interval',
            time: end,
          ),
        );
      }
    }

    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  void _showQuickAddEvent() {
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
        builder: (ctx, setLocalState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('home_quick_add_event'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: t('event_title'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: t('event_location_optional'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setLocalState(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setLocalState(() {
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
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(selectedTime.format(ctx)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final auth = context.read<AuthProvider>();
                    final user = auth.currentUser;
                    final familyId = user?.familyId;
                    if (user == null || familyId == null) return;

                    final event = FamilyEvent(
                      id: const Uuid().v4(),
                      familyId: familyId,
                      title: titleCtrl.text.trim(),
                      location: locationCtrl.text.trim().isNotEmpty
                          ? locationCtrl.text.trim()
                          : null,
                      eventTime: selectedDate,
                      createdBy: user.uid,
                      createdAt: DateTime.now(),
                    );
                    context.read<LocationProvider>().createFamilyEvent(event);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
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

  String _timeUntilLabel(
    String Function(String, [List<String>?]) t,
    DateTime time,
  ) {
    final diff = time.difference(_now).inMinutes;
    if (diff < -1) return t('home_agenda_past');
    if (diff <= 1) return t('home_agenda_now');
    if (diff < 60) return t('home_agenda_in_min', ['$diff']);
    final h = diff ~/ 60;
    return t('home_agenda_in_hour', ['$h']);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  IconData _iconForSecurity(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.gpsDisabled:
        return Icons.gps_off_rounded;
      case SecurityEventType.gpsEnabled:
        return Icons.gps_fixed_rounded;
      case SecurityEventType.permissionRevoked:
        return Icons.lock_outline_rounded;
      case SecurityEventType.simChanged:
        return Icons.sim_card_alert_rounded;
      case SecurityEventType.connectionLost:
        return Icons.wifi_off_rounded;
      case SecurityEventType.connectionRestored:
        return Icons.wifi_rounded;
      case SecurityEventType.nightMovement:
        return Icons.nights_stay_rounded;
    }
  }

  Color _colorForSecurity(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.gpsDisabled:
      case SecurityEventType.permissionRevoked:
      case SecurityEventType.simChanged:
      case SecurityEventType.connectionLost:
      case SecurityEventType.nightMovement:
        return AppTheme.errorColor;
      case SecurityEventType.gpsEnabled:
      case SecurityEventType.connectionRestored:
        return AppTheme.successColor;
    }
  }

  String _labelForSecurity(
    String Function(String, [List<String>?]) t,
    SecurityEventType type,
  ) {
    switch (type) {
      case SecurityEventType.gpsDisabled:
        return t('gps_disabled');
      case SecurityEventType.gpsEnabled:
        return t('gps_enabled');
      case SecurityEventType.permissionRevoked:
        return t('permission_revoked');
      case SecurityEventType.simChanged:
        return t('sim_changed');
      case SecurityEventType.connectionLost:
        return t('connection_lost_event');
      case SecurityEventType.connectionRestored:
        return t('connection_restored');
      case SecurityEventType.nightMovement:
        return t('night_movement');
    }
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum _AgendaKind { event, schedule }

enum _AgendaWindow { today, threeDays, sevenDays }

class _AgendaItem {
  final _AgendaKind kind;
  final String title;
  final String? subtitle;
  final DateTime time;

  const _AgendaItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
