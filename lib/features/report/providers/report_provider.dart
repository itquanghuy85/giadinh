import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/repositories/finance_repository.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportMonthProvider = StateProvider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final monthlyReportProvider = StreamProvider.autoDispose<MonthlyReportData>((ref) {
  final uid = ref.watch(authControllerProvider).user?.uid;
  final month = ref.watch(reportMonthProvider);

  if (uid == null || uid.isEmpty) {
    return Stream.value(
      const MonthlyReportData(
        transactions: [],
        totalIncome: 0,
        totalExpense: 0,
        byCategory: {},
      ),
    );
  }

  return ref.watch(financeRepositoryProvider).streamMonthlyReport(ownerId: uid, month: month);
});
