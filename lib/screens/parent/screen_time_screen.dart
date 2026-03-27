import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/screen_time_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/firestore_service.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  final FirestoreService _firestore = FirestoreService();
  String? _selectedChildId;
  ScreenTimeConfig? _config;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final children = context.watch<FamilyProvider>().children;
    final familyId = context.read<AuthProvider>().currentUser?.familyId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(t('screen_time'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(t('screen_time'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(t('screen_time_desc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Child selector
            Text(t('select_child'),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: children.map((child) {
                final selected = _selectedChildId == child.uid;
                return ChoiceChip(
                  label: Text(child.displayName),
                  selected: selected,
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  onSelected: (_) {
                    setState(() => _selectedChildId = child.uid);
                    _loadConfig(familyId, child.uid);
                  },
                );
              }).toList(),
            ),

            if (_loading) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator()),
            ],

            if (_selectedChildId != null && !_loading) ...[
              const SizedBox(height: 24),

              // Enable/Disable
              _SectionCard(
                children: [
                  SwitchListTile(
                    title: Text(t('enable_screen_time'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(t('enable_screen_time_desc')),
                    value: _config?.enabled ?? false,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _updateConfig(enabled: v),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Daily Limit
              _SectionCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.hourglass_top,
                        color: AppTheme.primaryColor),
                    title: Text(t('daily_limit')),
                    subtitle: Text(
                        '${_config?.dailyLimitMinutes ?? 120} ${t('minutes')}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            final mins =
                                (_config?.dailyLimitMinutes ?? 120) - 15;
                            if (mins >= 15) {
                              _updateConfig(dailyLimitMinutes: mins);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            final mins =
                                (_config?.dailyLimitMinutes ?? 120) + 15;
                            if (mins <= 720) {
                              _updateConfig(dailyLimitMinutes: mins);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Slider(
                      value: (_config?.dailyLimitMinutes ?? 120).toDouble(),
                      min: 15,
                      max: 720,
                      divisions: 47,
                      activeColor: AppTheme.primaryColor,
                      label:
                          '${_config?.dailyLimitMinutes ?? 120} ${t('minutes')}',
                      onChanged: (v) =>
                          _updateConfig(dailyLimitMinutes: v.toInt()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bedtime
              _SectionCard(
                children: [
                  SwitchListTile(
                    title: Text(t('bedtime'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(t('bedtime_desc')),
                    secondary: const Icon(Icons.bedtime,
                        color: Color(0xFF5C6BC0)),
                    value: _config?.bedtimeEnabled ?? true,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _updateConfig(bedtimeEnabled: v),
                  ),
                  if (_config?.bedtimeEnabled ?? true) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: Text(t('bedtime_start')),
                      trailing: Text(
                        _formatTime(
                            _config?.bedtimeStartHour ?? 21,
                            _config?.bedtimeStartMinute ?? 0),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      onTap: () => _pickTime(
                        initial: TimeOfDay(
                            hour: _config?.bedtimeStartHour ?? 21,
                            minute: _config?.bedtimeStartMinute ?? 0),
                        onPicked: (t) => _updateConfig(
                            bedtimeStartHour: t.hour,
                            bedtimeStartMinute: t.minute),
                      ),
                    ),
                    ListTile(
                      title: Text(t('bedtime_end')),
                      trailing: Text(
                        _formatTime(
                            _config?.bedtimeEndHour ?? 7,
                            _config?.bedtimeEndMinute ?? 0),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      onTap: () => _pickTime(
                        initial: TimeOfDay(
                            hour: _config?.bedtimeEndHour ?? 7,
                            minute: _config?.bedtimeEndMinute ?? 0),
                        onPicked: (t) => _updateConfig(
                            bedtimeEndHour: t.hour,
                            bedtimeEndMinute: t.minute),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // School Time / Downtime
              _SectionCard(
                children: [
                  SwitchListTile(
                    title: Text(t('school_time_downtime'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(t('school_time_downtime_desc')),
                    secondary: const Icon(Icons.school,
                        color: Color(0xFFFF9800)),
                    value: _config?.schoolTimeEnabled ?? false,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => _updateConfig(schoolTimeEnabled: v),
                  ),
                  if (_config?.schoolTimeEnabled ?? false) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: Text(t('school_start')),
                      trailing: Text(
                        _formatTime(
                            _config?.schoolStartHour ?? 7,
                            _config?.schoolStartMinute ?? 30),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      onTap: () => _pickTime(
                        initial: TimeOfDay(
                            hour: _config?.schoolStartHour ?? 7,
                            minute: _config?.schoolStartMinute ?? 30),
                        onPicked: (t) => _updateConfig(
                            schoolStartHour: t.hour,
                            schoolStartMinute: t.minute),
                      ),
                    ),
                    ListTile(
                      title: Text(t('school_end')),
                      trailing: Text(
                        _formatTime(
                            _config?.schoolEndHour ?? 16,
                            _config?.schoolEndMinute ?? 30),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      onTap: () => _pickTime(
                        initial: TimeOfDay(
                            hour: _config?.schoolEndHour ?? 16,
                            minute: _config?.schoolEndMinute ?? 30),
                        onPicked: (t) => _updateConfig(
                            schoolEndHour: t.hour,
                            schoolEndMinute: t.minute),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _DaySelector(
                        selectedDays: _config?.schoolDays ?? [1, 2, 3, 4, 5],
                        onChanged: (days) =>
                            _updateConfig(schoolDays: days),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Bonus Time
              _SectionCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.card_giftcard,
                        color: Color(0xFF4CAF50)),
                    title: Text(t('bonus_time')),
                    subtitle: Text(t('bonus_time_desc')),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        for (final mins in [15, 30, 60])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: const Icon(Icons.add, size: 16),
                              label: Text('+$mins ${t('min_short')}'),
                              onPressed: () => _addBonusTime(mins),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if ((_config?.bonusMinutes ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF4CAF50), size: 20),
                            const SizedBox(width: 8),
                            Text(
                                '${t('bonus_active')}: +${_config!.bonusMinutes} ${t('min_short')}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4CAF50))),
                            const Spacer(),
                            TextButton(
                              onPressed: () =>
                                  _updateConfig(bonusMinutes: 0),
                              child: Text(t('reset')),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _loadConfig(String familyId, String childId) {
    setState(() => _loading = true);
    _firestore.screenTimeConfigStream(childId).first.then((config) {
      if (mounted) {
        setState(() {
          _config = config ??
              ScreenTimeConfig(
                id: const Uuid().v4(),
                familyId: familyId,
                childId: childId,
              );
          _loading = false;
        });
      }
    });
  }

  void _updateConfig({
    bool? enabled,
    int? dailyLimitMinutes,
    bool? bedtimeEnabled,
    int? bedtimeStartHour,
    int? bedtimeStartMinute,
    int? bedtimeEndHour,
    int? bedtimeEndMinute,
    bool? schoolTimeEnabled,
    int? schoolStartHour,
    int? schoolStartMinute,
    int? schoolEndHour,
    int? schoolEndMinute,
    List<int>? schoolDays,
    int? bonusMinutes,
  }) {
    if (_config == null) return;
    final updated = _config!.copyWith(
      enabled: enabled,
      dailyLimitMinutes: dailyLimitMinutes,
      bedtimeEnabled: bedtimeEnabled,
      bedtimeStartHour: bedtimeStartHour,
      bedtimeStartMinute: bedtimeStartMinute,
      bedtimeEndHour: bedtimeEndHour,
      bedtimeEndMinute: bedtimeEndMinute,
      schoolTimeEnabled: schoolTimeEnabled,
      schoolStartHour: schoolStartHour,
      schoolStartMinute: schoolStartMinute,
      schoolEndHour: schoolEndHour,
      schoolEndMinute: schoolEndMinute,
      schoolDays: schoolDays,
      bonusMinutes: bonusMinutes,
    );
    setState(() => _config = updated);
    _firestore.saveScreenTimeConfig(updated);
  }

  void _addBonusTime(int minutes) {
    final current = _config?.bonusMinutes ?? 0;
    _updateConfig(bonusMinutes: current + minutes);
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required void Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) onPicked(picked);
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const _DaySelector({required this.selectedDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final labels = [
      t('mon'), t('tue'), t('wed'), t('thu'),
      t('fri'), t('sat'), t('sun'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = selectedDays.contains(day);
        return GestureDetector(
          onTap: () {
            final days = List<int>.from(selectedDays);
            if (selected) {
              days.remove(day);
            } else {
              days.add(day);
            }
            onChanged(days);
          },
          child: CircleAvatar(
            radius: 18,
            backgroundColor: selected
                ? AppTheme.primaryColor
                : AppTheme.dividerColor,
            child: Text(
              labels[i],
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }
}
