import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/schedule_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late ScheduleConfig _config;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final locProv = context.watch<LocationProvider>();
    final auth = context.watch<AuthProvider>();
    final familyId = auth.currentUser?.familyId;

    if (!_initialized && familyId != null) {
      _initialized = true;
      locProv.listenToScheduleConfig(familyId);
    }

    final saved = locProv.scheduleConfig;
    if (saved != null) {
      _config = saved;
    } else {
      _config = ScheduleConfig(
        id: const Uuid().v4(),
        familyId: familyId ?? '',
        isEnabled: false,
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(t('smart_schedule'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                t('smart_schedule'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                t('schedule_desc'),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Enable toggle
              _buildToggle(t),

              const SizedBox(height: 20),

              // School hours
              _buildSchoolHours(t),

              const SizedBox(height: 20),

              // School days
              _buildSchoolDays(t),

              const SizedBox(height: 20),

              // Tracking intervals info
              _buildIntervalInfo(t),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(t('save'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String Function(String, [List<String>?]) t) {
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
          Icon(
            _config.isEnabled ? Icons.schedule : Icons.schedule_outlined,
            color: _config.isEnabled
                ? AppTheme.primaryColor
                : AppTheme.textHint,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              t('school_mode'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(isEnabled: val);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolHours(String Function(String, [List<String>?]) t) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('school_hours'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimePickerTile(
                  label: t('school_start'),
                  hour: _config.schoolStartHour,
                  minute: _config.schoolStartMinute,
                  onChanged: (h, m) {
                    setState(() {
                      _config = _config.copyWith(
                        schoolStartHour: h,
                        schoolStartMinute: m,
                      );
                    });
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: AppTheme.textHint),
              ),
              Expanded(
                child: _TimePickerTile(
                  label: t('school_end'),
                  hour: _config.schoolEndHour,
                  minute: _config.schoolEndMinute,
                  onChanged: (h, m) {
                    setState(() {
                      _config = _config.copyWith(
                        schoolEndHour: h,
                        schoolEndMinute: m,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolDays(String Function(String, [List<String>?]) t) {
    final dayLabels = [
      t('mon'),
      t('tue'),
      t('wed'),
      t('thu'),
      t('fri'),
      t('sat'),
      t('sun'),
    ];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('school_days'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayNum = index + 1; // 1=Mon ... 7=Sun
              final isSelected = _config.schoolDays.contains(dayNum);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    final newDays = List<int>.from(_config.schoolDays);
                    if (isSelected) {
                      newDays.remove(dayNum);
                    } else {
                      newDays.add(dayNum);
                    }
                    _config = _config.copyWith(schoolDays: newDays);
                  });
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.dividerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      dayLabels[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalInfo(String Function(String, [List<String>?]) t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('tracking_interval'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _IntervalRow(
            icon: Icons.school,
            label: t('school_interval'),
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          _IntervalRow(
            icon: Icons.nightlight_round,
            label: t('off_hours_interval'),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  void _save() {
    context.read<LocationProvider>().saveScheduleConfig(_config);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _config.isEnabled
              ? AppLocalizations.of(context).t('schedule_enabled')
              : AppLocalizations.of(context).t('schedule_disabled'),
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final void Function(int h, int m) onChanged;

  const _TimePickerTile({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
        if (time != null) {
          onChanged(time.hour, time.minute);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IntervalRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
