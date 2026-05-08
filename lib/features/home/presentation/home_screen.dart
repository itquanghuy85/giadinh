import 'package:family_finance/app/routes/app_routes.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/home/providers/home_provider.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/shared/utils/money_formatter.dart';
import 'package:family_finance/shared/widgets/role_guard.dart';
import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/app/theme/app_space.dart';
import 'package:family_finance/shared/widgets/secure_money_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(homeStatsProvider);
    final auth = ref.watch(authControllerProvider);
    final userName = auth.profile?.displayName ?? '';
    final today = DateFormat('EEE, dd/MM', 'vi_VN').format(DateTime.now());

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Không tải được dashboard: $error'),
            const SizedBox(height: AppSpace.sm),
            FilledButton(
              onPressed: () => ref.invalidate(homeStatsProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (stats) {
        final balance = stats.totalBalance;
        final income = stats.monthlyIncome;
        final expense = stats.monthlyExpense;
        final remain = income - expense;
        final expenseRate = income <= 0 ? 0.0 : (expense / income).clamp(0, 1).toDouble();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(homeStatsProvider),
          child: ListView(
            padding: AppSpace.screen,
            children: [
              _DashboardHeader(userName: userName, today: today, balance: balance),
              const SizedBox(height: AppSpace.md),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpace.sm,
                crossAxisSpacing: AppSpace.sm,
                childAspectRatio: 1.65,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [
                  _MetricCard(
                    label: 'Thu tháng',
                    value: MoneyFormatter.format(income),
                    icon: Icons.trending_up,
                    tone: AppColors.income,
                  ),
                  _MetricCard(
                    label: 'Chi tháng',
                    value: MoneyFormatter.format(expense),
                    icon: Icons.trending_down,
                    tone: AppColors.expense,
                  ),
                  _MetricCard(
                    label: 'Còn lại',
                    value: MoneyFormatter.format(remain),
                    icon: Icons.savings_outlined,
                    tone: remain >= 0 ? AppColors.primary : AppColors.expense,
                  ),
                  _MetricCard(
                    label: 'Tỉ lệ chi',
                    value: '${(expenseRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.speed_outlined,
                    tone: expenseRate > 0.8 ? AppColors.warning : AppColors.transfer,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Text('Xu hướng chi tiêu 7 ngày', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpace.sm),
              _WeeklyChart(weeklySpending: stats.weeklySpending),
              const SizedBox(height: AppSpace.md),
              RoleGuard(
                roleRequired: const [UserRole.fatherAdmin, UserRole.motherManager],
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.debt),
                        icon: const Icon(Icons.request_quote_outlined, size: 18),
                        label: const Text('Công nợ'),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.fund),
                        icon: const Icon(Icons.flag_outlined, size: 18),
                        label: const Text('Quỹ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({
    required this.userName,
    required this.today,
    required this.balance,
  });

  final String userName;
  final String today;
  final double balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(moneyVisibilityProvider);
    return Container(
      padding: AppSpace.card,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF274DBE), Color(0xFF2B62D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  userName.isEmpty ? 'Dashboard tài chính' : 'Dashboard · $userName',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70),
                ),
              ),
              Text(today, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: SecureMoneyText(
                  amount: balance,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
                ),
              ),
              IconButton(
                onPressed: () => ref.read(moneyVisibilityProvider.notifier).state = !isVisible,
                icon: Icon(
                  isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white,
                ),
                tooltip: 'Ẩn/hiện số tiền',
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Tổng tài sản hiện tại',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpace.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: tone),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.weeklySpending});

  final List<double> weeklySpending;

  @override
  Widget build(BuildContext context) {
    final hasData = weeklySpending.any((v) => v > 0);
    if (!hasData) {
      return Card(
        child: SizedBox(
          height: 100,
          child: Center(
            child: Text(
              'Chưa có dữ liệu chi tiêu tuần này',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final maxY = weeklySpending.reduce((a, b) => a > b ? a : b);
    return Card(
      child: SizedBox(
        height: 120,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.2,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                horizontalInterval: maxY <= 0 ? 1 : maxY / 3,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppColors.border.withValues(alpha: 0.5), strokeWidth: 0.8),
              ),
              titlesData: const FlTitlesData(show: false),
              barGroups: weeklySpending.asMap().entries.map((entry) {
                final highlighted = entry.key == weeklySpending.length - 1;
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      color: highlighted ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                      width: 10,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
