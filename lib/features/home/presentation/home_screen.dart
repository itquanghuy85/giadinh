import 'package:family_finance/app/routes/app_routes.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/home/providers/home_provider.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/shared/utils/money_formatter.dart';
import 'package:family_finance/shared/widgets/role_guard.dart';
import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/shared/widgets/secure_money_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(moneyVisibilityProvider);
    final statsAsync = ref.watch(homeStatsProvider);
    final userName = ref.watch(authControllerProvider).profile?.displayName ?? '';
    final today = DateFormat('EEEE, d MMMM', 'vi_VN').format(DateTime.now());

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Không tải được dữ liệu trang chủ: $error'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.invalidate(homeStatsProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (stats) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header: xin chào + ngày
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isNotEmpty ? 'Xin chào, $userName 👋' : 'Xin chào!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      today,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền hiện có', style: TextStyle(color: Colors.white70)),
                      IconButton(
                        onPressed: () => ref.read(moneyVisibilityProvider.notifier).state = !isVisible,
                        icon: Icon(
                          isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SecureMoneyText(
                    amount: stats.totalBalance,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniMetric(label: 'Thu tháng', value: '+${MoneyFormatter.format(stats.monthlyIncome)}'),
                      const SizedBox(width: 8),
                      _MiniMetric(label: 'Chi tháng', value: '-${MoneyFormatter.format(stats.monthlyExpense)}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Chi tiêu 7 ngày', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final hasSpending = stats.weeklySpending.any((v) => v > 0);
              if (!hasSpending) {
                return Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_outlined, color: AppColors.border, size: 32),
                      SizedBox(height: 6),
                      Text('Chưa có chi tiêu tuần này', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                );
              }
              final maxY = stats.weeklySpending.reduce((a, b) => a > b ? a : b);
              return SizedBox(
                height: 110,
                child: BarChart(
                  BarChartData(
                    maxY: maxY <= 0 ? 1 : maxY * 1.2,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    barGroups: stats.weeklySpending.asMap().entries.map((entry) {
                      final highlighted = entry.key == 6;
                      return BarChartGroupData(x: entry.key, barRods: [
                        BarChartRodData(
                          toY: entry.value <= 0 ? 0 : entry.value,
                          color: highlighted ? AppColors.primary : AppColors.primary.withValues(alpha: 0.22),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            RoleGuard(
              roleRequired: const [UserRole.fatherAdmin, UserRole.motherManager],
              child: Column(
                children: [
                  _QuickCard(
                    label: 'Công nợ cần thu',
                    value: 'Xem chi tiết',
                    color: AppColors.income,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.debt),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            _QuickCard(
              label: 'Quỹ du lịch',
              value: 'Mục tiêu',
              color: AppColors.primary,
              progress: 0.68,
              onTap: () => Navigator.pushNamed(context, AppRoutes.fund),
            ),
            const SizedBox(height: 8),
            _QuickCard(
              label: 'Lịch hôm nay',
              value: 'Xem lịch',
              color: AppColors.transfer,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            RoleGuard(
              roleRequired: const [UserRole.fatherAdmin, UserRole.motherManager],
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.report),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Xem báo cáo tháng'),
              ),
            ),
          ],
        );
      },
    ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.progress,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textSecondary)),
                  Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
