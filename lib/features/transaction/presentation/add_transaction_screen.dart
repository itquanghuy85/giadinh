import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/app/theme/app_space.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/wallet/providers/wallet_provider.dart';
import 'package:family_finance/shared/models/transaction.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/services/transaction_notification_handler.dart';
import 'package:family_finance/shared/utils/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();

  TransactionType _type = TransactionType.expense;
  String _selectedCategory = 'Ăn uống';
  String? _selectedWalletId;
  String? _selectedDestWalletId;

  static const _categories = [
    ('Ăn uống', Icons.restaurant_outlined),
    ('Xăng', Icons.local_gas_station_outlined),
    ('Đi chợ', Icons.shopping_basket_outlined),
    ('Học phí', Icons.school_outlined),
    ('Mua sắm', Icons.shopping_cart_outlined),
    ('Điện nước', Icons.bolt_outlined),
    ('Sửa chữa', Icons.build_outlined),
    ('Khác', Icons.widgets_outlined),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _amountFocus.requestFocus());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  bool get _hasDirtyData => _amountController.text.isNotEmpty || _noteController.text.isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_hasDirtyData) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy nhập?'),
        content: const Text('Dữ liệu chưa lưu sẽ bị mất.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tiếp tục')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thoát')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.user?.uid;
    final userProfile = auth.profile;
    if (uid == null) return;

    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', ''));
    if (amount == null || amount <= 0 || _selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập số tiền và chọn ví nguồn')));
      return;
    }

    if (_type == TransactionType.transfer) {
      if (_selectedDestWalletId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ví đích')));
        return;
      }
      if (_selectedDestWalletId == _selectedWalletId) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ví nguồn và ví đích phải khác nhau')));
        return;
      }

      final wallets = ref.read(walletsProvider).valueOrNull ?? [];
      final source = wallets.where((w) => w.id == _selectedWalletId).firstOrNull;
      if (source != null && source.balance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không đủ tiền. Số dư ví: ${MoneyFormatter.format(source.balance)}')),
        );
        return;
      }

      await ref.read(firestoreServiceProvider).transferBetweenWallets(
            uid: uid,
            sourceWalletId: _selectedWalletId!,
            destWalletId: _selectedDestWalletId!,
            amount: amount,
            note: _noteController.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final tx = TransactionModel(
      id: '',
      ownerUid: uid,
      walletId: _selectedWalletId!,
      amount: amount,
      type: _type,
      category: _selectedCategory,
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
      createdBy: uid,
    );

    await ref.read(firestoreServiceProvider).addTransaction(uid, tx);

    if (amount > 500000) {
      await TransactionNotificationHandler.notifyLargeTransaction(
        tx,
        userProfile?.displayName ?? 'Thành viên',
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const [];

    return PopScope(
      canPop: !_hasDirtyData,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && context.mounted) Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpace.lg,
          right: AppSpace.lg,
          top: AppSpace.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.lg,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F8FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: const Color(0xFF1A1A1A),
              displayColor: const Color(0xFF1A1A1A),
            ),
          ),
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 46,
                  margin: const EdgeInsets.only(bottom: AppSpace.sm),
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
                ),
              ),
              Text('Thêm giao dịch', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _amountController,
                focusNode: _amountFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorFormatter()],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  labelStyle: TextStyle(color: Color(0xFF555555)),
                  hintStyle: TextStyle(color: Color(0xFF999999)),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SegmentedButton<TransactionType>(
                style: ButtonStyle(
                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                  textStyle: WidgetStateProperty.all(Theme.of(context).textTheme.labelMedium),
                ),
                segments: const [
                  ButtonSegment(value: TransactionType.income, label: Text('Thu')),
                  ButtonSegment(value: TransactionType.expense, label: Text('Chi')),
                  ButtonSegment(value: TransactionType.transfer, label: Text('Chuyển')),
                ],
                selected: {_type},
                onSelectionChanged: (value) => setState(() => _type = value.first),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: _categories.map((entry) {
                  final cat = entry.$1;
                  final icon = entry.$2;
                  final selected = cat == _selectedCategory;
                  return ChoiceChip(
                    avatar: Icon(icon, size: 14, color: selected ? AppColors.primary : AppColors.textSecondary),
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? AppColors.primary : const Color(0xFF555555),
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundColor: const Color(0xFFF0F0F0),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpace.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedWalletId,
                hint: const Text('Chọn ví nguồn'),
                items: wallets
                    .map((w) => DropdownMenuItem<String>(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedWalletId = value),
              ),
              if (_type == TransactionType.transfer) ...[
                const SizedBox(height: AppSpace.sm),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDestWalletId,
                  hint: const Text('Chọn ví đích'),
                  items: wallets
                      .where((w) => w.id != _selectedWalletId)
                      .map((w) => DropdownMenuItem<String>(value: w.id, child: Text(w.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedDestWalletId = value),
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
              ),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Lưu giao dịch'),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
