import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/app/theme/app_space.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/report/data/pdf_service.dart';
import 'package:family_finance/features/report/providers/report_provider.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportMonthProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final uid = ref.watch(authControllerProvider).user?.uid ?? '';
    final svc = ref.read(firestoreServiceProvider);
    final mFmt = DateFormat('MM/yyyy', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text('Báo cáo ${mFmt.format(month)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Chọn tháng',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: month,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                ref.read(reportMonthProvider.notifier).state = DateTime(picked.year, picked.month);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Xuất PDF',
            onPressed: uid.isEmpty
                ? null
                : () async {
                    try {
                      await PdfService.exportMonthlyReport(
                        uid: uid,
                        month: month.month,
                        year: month.year,
                        db: svc.db,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất PDF: $e')));
                    }
                  },
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Không tải được báo cáo: $e'),
              const SizedBox(height: AppSpace.sm),
              FilledButton(
                onPressed: () => ref.invalidate(monthlyReportProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (report) {
          final fmt = NumberFormat('#,###', 'vi_VN');
          final sortedCats = report.byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          if (report.transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpace.screen,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insights_outlined, size: 52, color: AppColors.border),
                    const SizedBox(height: AppSpace.sm),
                    Text('Chưa có giao dịch trong tháng ${mFmt.format(month)}'),
                    const SizedBox(height: AppSpace.sm),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(monthlyReportProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalExpense = report.totalExpense;
          final pieSections = sortedCats.take(5).toList();
          final sectionColors = <Color>[
            AppColors.expense,
            AppColors.warning,
            AppColors.transfer,
            AppColors.primary,
            const Color(0xFF7A5CD1),
          ];

          return ListView(
            padding: AppSpace.screen,
            children: [
              Row(
                children: [
                  Expanded(child: _SummaryCard(label: 'Tổng thu', amount: report.totalIncome, color: AppColors.income, sign: '+')),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: _SummaryCard(label: 'Tổng chi', amount: report.totalExpense, color: AppColors.expense, sign: '-')),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              _SummaryCard(
                label: 'Cân đối',
                amount: report.balance,
                color: report.balance >= 0 ? AppColors.income : AppColors.expense,
                sign: report.balance >= 0 ? '+' : '',
              ),
              const SizedBox(height: AppSpace.md),
              Text('Phân bổ chi tiêu theo danh mục', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpace.sm),
              Card(
                child: Padding(
                  padding: AppSpace.card,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            sections: pieSections.asMap().entries.map((entry) {
                              final percent = totalExpense <= 0 ? 0.0 : (entry.value.value / totalExpense) * 100;
                              return PieChartSectionData(
                                value: entry.value.value,
                                color: sectionColors[entry.key % sectionColors.length],
                                radius: 14,
                                title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
                                titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: pieSections.asMap().entries.map((entry) {
                            final color = sectionColors[entry.key % sectionColors.length];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      entry.value.key,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '-${fmt.format(entry.value.value)}đ',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppColors.expense,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text('${report.transactions.length} giao dịch trong tháng',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.amount, required this.color, required this.sign});

  final String label;
  final double amount;
  final Color color;
  final String sign;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');
    return Card(
      child: Padding(
        padding: AppSpace.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpace.xs),
            Text(
              '$sign${fmt.format(amount.abs())}đ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
