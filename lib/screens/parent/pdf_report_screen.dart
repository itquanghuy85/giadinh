import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/timeline_event.dart';

class PdfReportScreen extends StatefulWidget {
  const PdfReportScreen({super.key});

  @override
  State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  String? _selectedChildId;
  String? _selectedChildName;
  DateTime _weekStart =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final children = context.watch<FamilyProvider>().children;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(t('pdf_report'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                  const Icon(Icons.picture_as_pdf,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(t('weekly_pdf_report'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(t('pdf_report_desc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Child selector
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
                  onSelected: (_) => setState(() {
                    _selectedChildId = child.uid;
                    _selectedChildName = child.displayName;
                  }),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Week selector
            Row(
              children: [
                Text(t('week_of'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() =>
                      _weekStart = _weekStart
                          .subtract(const Duration(days: 7))),
                ),
                Text(
                  '${DateFormat('dd/MM').format(_weekStart)} - ${DateFormat('dd/MM').format(_weekStart.add(const Duration(days: 6)))}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _weekStart =
                      _weekStart.add(const Duration(days: 7))),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedChildId == null || _generating
                    ? null
                    : _generateAndSharePdf,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                    _generating ? t('generating') : t('generate_pdf')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSharePdf() async {
    if (_selectedChildId == null) return;
    setState(() => _generating = true);

    try {
      final locationProv = context.read<LocationProvider>();
      final history =
          locationProv.locationHistories[_selectedChildId] ?? [];

      // Filter history to selected week only
      final weekEnd = _weekStart.add(const Duration(days: 7));
      final weekPoints = history.where((loc) {
        return !loc.timestamp.isBefore(_weekStart) &&
            loc.timestamp.isBefore(weekEnd);
      }).toList();

      double totalDistance = 0;
      int totalMovingMinutes = 0;
      double maxSpeed = 0;

      for (int i = 0; i < 7; i++) {
        final day = _weekStart.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        final dayPoints = weekPoints.where((loc) {
          return DateFormat('yyyy-MM-dd').format(loc.timestamp) == dateStr;
        }).toList();

        if (dayPoints.isNotEmpty) {
          double dayDist = 0;
          double dayMaxSpd = 0;
          for (int j = 1; j < dayPoints.length; j++) {
            dayDist += _haversineKm(
              dayPoints[j - 1].latitude,
              dayPoints[j - 1].longitude,
              dayPoints[j].latitude,
              dayPoints[j].longitude,
            );
            final spd = dayPoints[j].speed ?? 0;
            if (spd > dayMaxSpd) dayMaxSpd = spd;
          }
          totalDistance += dayDist;
          if (dayMaxSpd > maxSpeed) maxSpeed = dayMaxSpd;
        }
      }

      // Area time — filtered to selected week
      final areaMinutes = locationProv.calculateAreaTime(weekPoints);

      final t = AppLocalizations.of(context).t;
      final pdf = await _buildPdf(
        t: t,
        childName: _selectedChildName ?? '',
        weekStart: _weekStart,
        totalDistance: totalDistance,
        totalMovingMinutes: totalMovingMinutes,
        maxSpeed: maxSpeed,
        areaMinutes: areaMinutes,
        timelineEvents: locationProv.timelineEvents,
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'family_report_${DateFormat('yyyyMMdd').format(_weekStart)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context).t;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<pw.Document> _buildPdf({
    required String Function(String, [List<String>?]) t,
    required String childName,
    required DateTime weekStart,
    required double totalDistance,
    required int totalMovingMinutes,
    required double maxSpeed,
    required Map<String, int> areaMinutes,
    required List<TimelineEvent> timelineEvents,
  }) async {
    final pdf = pw.Document();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final periodStr =
        '${DateFormat('dd/MM/yyyy').format(weekStart)} - ${DateFormat('dd/MM/yyyy').format(weekEnd)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(t('app_name'),
                    style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo)),
                pw.Text(periodStr,
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text('${t('weekly_report')} - $childName',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800)),
            pw.Divider(color: PdfColors.indigo, thickness: 2),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.grey500),
          ),
        ),
        build: (context) => [
          // Summary stats
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfStatBox(t('total_distance'),
                    '${totalDistance.toStringAsFixed(1)} ${t('km')}'),
                _pdfStatBox(t('total_moving_time'),
                    '${totalMovingMinutes ~/ 60}h ${totalMovingMinutes % 60}m'),
                _pdfStatBox(t('max_speed'),
                    '${maxSpeed.toStringAsFixed(1)} ${t('kmh')}'),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Area time
          if (areaMinutes.isNotEmpty) ...[
            pw.Text(t('time_by_area'),
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: [t('pdf_area'), t('pdf_time')],
              data: areaMinutes.entries.map((e) {
                final hours = e.value ~/ 60;
                final mins = e.value % 60;
                return [
                  e.key,
                  hours > 0 ? '${hours}h ${mins}m' : '${mins}m'
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.indigo),
              cellPadding: const pw.EdgeInsets.all(8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),
          ],

          // Timeline
          if (timelineEvents.isNotEmpty) ...[
            pw.Text(t('timeline'),
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800)),
            pw.SizedBox(height: 8),
            ...timelineEvents.take(20).map((event) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                        color: PdfColors.grey300, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                          DateFormat('HH:mm').format(event.startTime),
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11)),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Text(
                          event.placeName ?? event.type.name,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                      pw.Text(event.formattedDuration,
                          style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600)),
                    ],
                  ),
                )),
          ],

          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text(
            '${t('app_name')} - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo)),
        pw.SizedBox(height: 4),
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.grey600)),
      ],
    );
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);
}
