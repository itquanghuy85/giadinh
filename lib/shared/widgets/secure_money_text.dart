import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/shared/utils/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final moneyVisibilityProvider = StateProvider<bool>((ref) => true);

class SecureMoneyText extends ConsumerWidget {
  const SecureMoneyText({
    super.key,
    required this.amount,
    this.style,
    this.showCurrency = true,
  });

  final double amount;
  final TextStyle? style;
  final bool showCurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(moneyVisibilityProvider);
    final formatted = showCurrency
        ? MoneyFormatter.format(amount)
        : MoneyFormatter.format(amount).replaceAll('đ', '');

    return Text(
      visible ? formatted : '•••••••',
      style: style ?? Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
    );
  }
}
