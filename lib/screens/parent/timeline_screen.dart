import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/timeline_event.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_provider.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedChildId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final familyProv = context.watch<FamilyProvider>();
    final locProv = context.watch<LocationProvider>();
    final children =
        familyProv.children.where((u) => u.role == UserRole.child).toList();

    if (_selectedChildId == null && children.isNotEmpty) {
      _selectedChildId = children.first.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTimeline();
      });
    }

    final events = locProv.timelineEvents;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                t('auto_timeline'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),

            // Child selector
            if (children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildChildSelector(children, t),
              ),

            const SizedBox(height: 12),

            // Date selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDateSelector(t),
            ),

            const SizedBox(height: 8),

            // Generate button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextButton.icon(
                onPressed: _generateTimeline,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(t('auto_timeline')),
              ),
            ),

            const SizedBox(height: 8),

            // Timeline
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Text(
                        t('no_timeline'),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return _TimelineItem(
                          event: events[index],
                          isFirst: index == 0,
                          isLast: index == events.length - 1,
                          t: t,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildSelector(List<AppUser> children, String Function(String, [List<String>?]) t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedChildId,
          isExpanded: true,
          hint: Text(t('select_child')),
          items: children.map((child) {
            return DropdownMenuItem(
              value: child.uid,
              child: Text(child.displayName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedChildId = value);
            _loadTimeline();
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector(String Function(String, [List<String>?]) t) {
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(now);

    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
            _loadTimeline();
          },
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Center(
                child: Text(
                  isToday
                      ? t('today')
                      : DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: isToday
              ? null
              : () {
                  setState(() {
                    _selectedDate =
                        _selectedDate.add(const Duration(days: 1));
                  });
                  _loadTimeline();
                },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _loadTimeline() {
    if (_selectedChildId == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<LocationProvider>().listenToTimeline(
          _selectedChildId!,
          dateStr,
        );
  }

  void _generateTimeline() {
    if (_selectedChildId == null) return;
    context.read<LocationProvider>().generateAndSaveTimeline(
          _selectedChildId!,
          _selectedDate,
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadTimeline();
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isFirst;
  final bool isLast;
  final String Function(String, [List<String>?]) t;

  const _TimelineItem({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final isStop = event.type == TimelineEventType.stop;
    final color = isStop ? AppTheme.primaryColor : AppTheme.accentColor;
    final icon = isStop ? Icons.place : Icons.directions_walk;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 12, color: AppTheme.dividerColor),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                        width: 2, color: AppTheme.dividerColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isStop ? t('stop_event') : t('move_event'),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        event.formattedDuration,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (event.placeName != null)
                    Text(
                      event.placeName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('HH:mm').format(event.startTime)} - ${event.endTime != null ? DateFormat('HH:mm').format(event.endTime!) : '...'}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
