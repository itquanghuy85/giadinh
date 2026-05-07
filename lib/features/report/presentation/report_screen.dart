import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/report/data/pdf_service.dart';
import 'package:family_finance/features/report/providers/report_provider.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportMonthProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final uid    = ref.watch(authControllerProvider).user?.uid ?? '';
    final svc    = ref.read(firestoreServiceProvider);
    final mFmt   = DateFormat('MM/yyyy', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text('Báo cáo ${mFmt.format(month)}'),
        actions: [
          // Chọn tháng
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
                ref.read(reportMonthProvider.notifier).state =
                    DateTime(picked.year, picked.month);
              }
            },
          ),
          // Xuất PDF
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi xuất PDF: $e')),
                      );
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
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => ref.invalidate(monthlyReportProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (report) {
          final fmt = NumberFormat('#,###', 'vi_VN');
          final sortedCats = report.byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          if (report.transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insights_outlined, size: 52, color: AppColors.border),
                    const SizedBox(height: 10),
                    Text('Chưa có giao dịch trong tháng ${mFmt.format(month)}'),
                    const SizedBox(height: 10),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tổng hợp
              Row(
                children: [
                  Expanded(child: _SummaryCard(label: 'Tổng thu', amount: report.totalIncome, color: AppColors.income, sign: '+')),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryCard(label: 'Tổng chi', amount: report.totalExpense, color: AppColors.expense, sign: '-')),
                ],
              ),
              const SizedBox(height: 10),
              _SummaryCard(
                label: 'Cân đối',
                amount: report.balance,
                color: report.balance >= 0 ? AppColors.income : AppColors.expense,
                sign: report.balance >= 0 ? '+' : '',
              ),
              const SizedBox(height: 20),

              // Top danh mục
              if (sortedCats.isNotEmpty) ...[
                Text('Chi tiêu theo danh mục', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ...sortedCats.take(8).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: report.totalExpense > 0 ? (e.value / report.totalExpense).clamp(0, 1) : 0,
                            backgroundColor: AppColors.border,
                            color: AppColors.expense,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      )),
                      const SizedBox(width: 12),
                      Text('-${fmt.format(e.value)}đ',
                          style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],

              // Số giao dịch
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              '$sign${fmt.format(amount.abs())}đ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

