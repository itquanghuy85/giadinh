import 'package:family_finance/app/theme/app_colors.dart';
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
  String? _selectedDestWalletId; // Ví đích khi chuyển

  static const _categories = [
    'Ăn uống',
    'Xăng',
    'Đi chợ',
    'Học phí',
    'Mua sắm',
    'Điện nước',
    'Sửa chữa',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.user?.uid;
    final userProfile = auth.profile;
    if (uid == null) return;

    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', ''));
    if (amount == null || amount <= 0 || _selectedWalletId == null) return;

    // --- Chuyển tiền: dùng batch write riêng ---
    if (_type == TransactionType.transfer) {
      if (_selectedDestWalletId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ví đích')),
        );
        return;
      }
      if (_selectedDestWalletId == _selectedWalletId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ví nguồn và ví đích phải khác nhau')),
        );
        return;
      }
      // Validate balance
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
    
    // [THÊM MỚI] Notify for large transactions (> 500k)
    if (amount > 500000) {
      await TransactionNotificationHandler.notifyLargeTransaction(
        tx,
        userProfile?.displayName ?? 'Thành viên',
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  bool get _hasDirtyData =>
      _amountController.text.isNotEmpty || _noteController.text.isNotEmpty;

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

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const [];

    return PopScope(
      canPop: !_hasDirtyData,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
              ),
            ),
            TextField(
              controller: _amountController,
              focusNode: _amountFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(labelText: 'Số tiền'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.income, label: Text('Thu')),
                ButtonSegment(value: TransactionType.expense, label: Text('Chi')),
                ButtonSegment(value: TransactionType.transfer, label: Text('Chuyển')),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() => _type = value.first),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedWalletId,
              hint: const Text('Chọn ví nguồn'),
              items: wallets
                  .map(
                    (w) => DropdownMenuItem<String>(
                      value: w.id,
                      child: Text(w.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedWalletId = value),
            ),
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedDestWalletId,
                hint: const Text('Chọn ví đích'),
                items: wallets
                    .where((w) => w.id != _selectedWalletId)
                    .map(
                      (w) => DropdownMenuItem<String>(
                        value: w.id,
                        child: Text(w.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedDestWalletId = value),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Lưu giao dịch'),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
