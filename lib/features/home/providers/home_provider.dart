import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/providers/access_scope_provider.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeStats {
  const HomeStats({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.weeklySpending,
  });

  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final List<double> weeklySpending;
}

final homeStatsProvider = StreamProvider.autoDispose<HomeStats>((ref) {
  final uid = ref.watch(authControllerProvider).user?.uid;
  if (uid == null) {
    return Stream.value(
      const HomeStats(totalBalance: 0, monthlyIncome: 0, monthlyExpense: 0, weeklySpending: [0, 0, 0, 0, 0, 0, 0]),
    );
  }

  final ownersAsync = ref.watch(accessibleOwnerIdsProvider);
  final owners = ownersAsync.valueOrNull?.isNotEmpty == true
      ? ownersAsync.valueOrNull!
      : <String>[uid];

  if (owners.isEmpty) {
    return Stream.value(
      const HomeStats(totalBalance: 0, monthlyIncome: 0, monthlyExpense: 0, weeklySpending: [0, 0, 0, 0, 0, 0, 0]),
    );
  }

  return ref.watch(financeRepositoryProvider).streamHomeStats(owners).map(
        (data) => HomeStats(
          totalBalance: data.totalBalance,
          monthlyIncome: data.monthlyIncome,
          monthlyExpense: data.monthlyExpense,
          weeklySpending: data.weeklySpending,
        ),
      );
});
