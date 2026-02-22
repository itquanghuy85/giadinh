import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_provider.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
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
        _loadReport();
      });
    }

    final report = locProv.selectedReport;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                t('smart_daily_report'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              // Child selector
              if (children.isNotEmpty)
                _buildChildSelector(children, t),

              const SizedBox(height: 16),

              // Date selector
              _buildDateSelector(t),

              const SizedBox(height: 24),

              // Report content
              if (report != null) ...[
                _buildSummaryCards(report, t),
                const SizedBox(height: 16),
                _buildDetailCards(report, t),
              ] else
                _buildEmptyState(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildSelector(List<AppUser> children, String Function(String) t) {
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      child.displayName.isNotEmpty
                          ? child.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(child.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedChildId = value);
            _loadReport();
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector(String Function(String) t) {
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(now);
    final isYesterday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    String dateLabel;
    if (isToday) {
      dateLabel = t('today');
    } else if (isYesterday) {
      dateLabel = t('yesterday');
    } else {
      dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
            _loadReport();
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
                  dateLabel,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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
                  _loadReport();
                },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(dynamic report, String Function(String) t) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.straighten,
            label: t('total_distance'),
            value: '${report.totalDistanceKm}',
            unit: t('km'),
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.speed,
            label: t('max_speed'),
            value: '${report.maxSpeedKmh}',
            unit: t('kmh'),
            color: AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCards(dynamic report, String Function(String) t) {
    return Column(
      children: [
        _DetailTile(
          icon: Icons.timer,
          title: t('total_moving_time'),
          value: report.formattedMovingTime,
          color: AppTheme.accentColor,
        ),
        if (report.mostVisitedPlace != null)
          _DetailTile(
            icon: Icons.place,
            title: t('most_visited'),
            value: '${report.mostVisitedPlace} (${report.mostVisitedCount}x)',
            color: AppTheme.primaryLight,
          ),
        if (report.leftHomeTime != null)
          _DetailTile(
            icon: Icons.home_outlined,
            title: t('left_home'),
            value: DateFormat('HH:mm').format(report.leftHomeTime!),
            color: AppTheme.warningColor,
          ),
        if (report.arrivedHomeTime != null)
          _DetailTile(
            icon: Icons.home,
            title: t('arrived_home'),
            value: DateFormat('HH:mm').format(report.arrivedHomeTime!),
            color: AppTheme.successColor,
          ),
      ],
    );
  }

  Widget _buildEmptyState(String Function(String) t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.assessment_outlined,
                size: 64, color: AppTheme.textHint.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              t('no_report'),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text(t('daily_report'),
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _loadReport() {
    if (_selectedChildId == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<LocationProvider>().listenToDailyReport(
          _selectedChildId!,
          dateStr,
        );
  }

  void _generateReport() {
    if (_selectedChildId == null) return;
    context.read<LocationProvider>().generateAndSaveReport(
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
      _loadReport();
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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
