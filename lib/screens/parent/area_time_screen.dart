import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_provider.dart';

class AreaTimeScreen extends StatefulWidget {
  const AreaTimeScreen({super.key});

  @override
  State<AreaTimeScreen> createState() => _AreaTimeScreenState();
}

class _AreaTimeScreenState extends State<AreaTimeScreen> {
  String? _selectedChildId;
  DateTime _selectedDate = DateTime.now();
  Map<String, int> _areaMinutes = {};
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final children = context.watch<FamilyProvider>().children;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(t('area_time_analysis'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child selector
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
                  Text(t('select_child'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: children.map((child) {
                      final selected = _selectedChildId == child.uid;
                      return ChoiceChip(
                        label: Text(child.displayName),
                        selected: selected,
                        selectedColor:
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                        onSelected: (_) {
                          setState(() => _selectedChildId = child.uid);
                          _loadAreaTime();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(t('date'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate:
                                DateTime.now().subtract(const Duration(days: 90)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                            _loadAreaTime();
                          }
                        },
                        icon:
                            const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('dd/MM/yyyy')
                            .format(_selectedDate)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_areaMinutes.isNotEmpty) ...[
              // Pie Chart
              Container(
                padding: const EdgeInsets.all(20),
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
                  children: [
                    Text(t('time_by_area'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Legend
                    ..._areaMinutes.entries.map((entry) {
                      final color = _getAreaColor(entry.key);
                      final hours = entry.value ~/ 60;
                      final mins = entry.value % 60;
                      final timeStr = hours > 0
                          ? '${hours}h ${mins}m'
                          : '${mins}m';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _getAreaLabel(entry.key, t),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14),
                              ),
                            ),
                            Text(timeStr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme.primaryColor)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ] else if (_selectedChildId != null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(t('no_area_data'),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _loadAreaTime() {
    if (_selectedChildId == null) return;
    setState(() => _loading = true);

    final locationProv = context.read<LocationProvider>();
    final history = locationProv.locationHistories[_selectedChildId] ?? [];
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayPoints = history.where((loc) {
      return DateFormat('yyyy-MM-dd').format(loc.timestamp) == dateStr;
    }).toList();

    final result = locationProv.calculateAreaTime(dayPoints);

    // Remove zero entries
    result.removeWhere((_, v) => v == 0);

    setState(() {
      _areaMinutes = result;
      _loading = false;
    });
  }

  List<PieChartSectionData> _buildPieSections() {
    final total =
        _areaMinutes.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return [];

    return _areaMinutes.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: _getAreaColor(entry.key),
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12),
      );
    }).toList();
  }

  Color _getAreaColor(String area) {
    switch (area) {
      case 'Home':
        return const Color(0xFF4CAF50);
      case 'School':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String _getAreaLabel(String area, String Function(String, [List<String>?]) t) {
    switch (area) {
      case 'Home':
        return t('area_home');
      case 'School':
        return t('area_school');
      default:
        return area == 'Other' ? t('area_other') : area;
    }
  }
}
