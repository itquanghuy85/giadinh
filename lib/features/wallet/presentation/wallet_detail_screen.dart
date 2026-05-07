import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/shared/models/transaction.dart';
import 'package:family_finance/shared/models/wallet.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/utils/money_formatter.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:family_finance/shared/widgets/secure_money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ── Providers ─────────────────────────────────────────────────
final _filterMonthProvider   = StateProvider.autoDispose<int?>((ref) => null);
final _filterYearProvider    = StateProvider.autoDispose<int?>((ref) => null);
final _filterTypeProvider    = StateProvider.autoDispose<String?>((ref) => null);
final _filterCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);

// ═══════════════════════════════════════════════════════════════
class WalletDetailScreen extends ConsumerStatefulWidget {
  const WalletDetailScreen({super.key, required this.wallet});

  final WalletModel wallet;

  @override
  ConsumerState<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends ConsumerState<WalletDetailScreen> {
  static const _categories = [
    'Ăn uống', 'Xăng', 'Đi chợ', 'Học phí',
    'Mua sắm', 'Điện nước', 'Sửa chữa', 'Khác',
    'Chuyển khoản', 'Nhận chuyển khoản',
  ];

  @override
  Widget build(BuildContext context) {
    final uid      = ref.watch(authControllerProvider).user?.uid ?? '';
    final role     = ref.watch(authControllerProvider).profile?.role ?? UserRole.childLimited;
    final month    = ref.watch(_filterMonthProvider);
    final year     = ref.watch(_filterYearProvider);
    final type     = ref.watch(_filterTypeProvider);
    final category = ref.watch(_filterCategoryProvider);

    final txStream = ref.watch(firestoreServiceProvider).streamWalletTransactions(
      uid, widget.wallet.id,
      month: month,
      year: year,
      type: type,
      category: category,
    );

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(widget.wallet.name),
      ),
      body: Column(
        children: [
          // ── Số dư ────────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số dư hiện tại', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                SecureMoneyText(
                  amount: widget.wallet.balance,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          // ── Filter bar ────────────────────────────────────────
          _FilterBar(
            categories: _categories,
            selectedMonth: month,
            selectedYear: year,
            selectedType: type,
            selectedCategory: category,
            onMonthYearChanged: (m, y) {
              ref.read(_filterMonthProvider.notifier).state = m;
              ref.read(_filterYearProvider.notifier).state  = y;
            },
            onTypeChanged: (t) => ref.read(_filterTypeProvider.notifier).state = t,
            onCategoryChanged: (c) => ref.read(_filterCategoryProvider.notifier).state = c,
            onClear: () {
              ref.read(_filterMonthProvider.notifier).state    = null;
              ref.read(_filterYearProvider.notifier).state     = null;
              ref.read(_filterTypeProvider.notifier).state     = null;
              ref.read(_filterCategoryProvider.notifier).state = null;
            },
          ),

          // ── Transaction list ──────────────────────────────────
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: txStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.border),
                        SizedBox(height: 12),
                        Text('Chưa có giao dịch nào', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                // Summary
                final income   = items.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
                final expense  = items.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text('${items.length} giao dịch', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const Spacer(),
                          if (income > 0)
                            Text('+${MoneyFormatter.format(income)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.income, fontWeight: FontWeight.w600)),
                          if (income > 0 && expense > 0) const SizedBox(width: 8),
                          if (expense > 0)
                            Text('-${MoneyFormatter.format(expense)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final tx = items[i];
                          final canEdit = role.canDeleteTransaction || tx.createdBy == uid;
                          return _TxTile(
                            tx: tx,
                            walletId: widget.wallet.id,
                            canEdit: canEdit,
                            uid: uid,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction tile with swipe ───────────────────────────────
class _TxTile extends ConsumerWidget {
  const _TxTile({required this.tx, required this.walletId, required this.canEdit, required this.uid});
  final TransactionModel tx;
  final String walletId;
  final bool canEdit;
  final String uid;

  Color get _color {
    switch (tx.type) {
      case TransactionType.income:   return AppColors.income;
      case TransactionType.expense:  return AppColors.expense;
      case TransactionType.transfer: return AppColors.transfer;
    }
  }

  String get _sign {
    if (tx.type == TransactionType.income) return '+';
    return '-';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('dd/MM HH:mm').format(tx.createdAt);

    if (!canEdit) {
      return _buildCard(context, dateStr);
    }

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => false,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () => _showEdit(context, ref),
              icon: const Icon(Icons.edit, color: AppColors.transfer),
              tooltip: 'Sửa',
            ),
            IconButton(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete, color: AppColors.expense),
              tooltip: 'Xóa',
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onLongPress: () => _showActionMenu(context, ref),
        child: _buildCard(context, dateStr),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String dateStr) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withOpacity(0.12),
          radius: 18,
          child: Text(
            _sign,
            style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx.note.isNotEmpty) Text(tx.note, style: const TextStyle(fontSize: 12)),
            Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        trailing: Text(
          '${_sign}${MoneyFormatter.format(tx.amount)}',
          style: TextStyle(fontWeight: FontWeight.w700, color: _color),
        ),
      ),
    );
  }

  Future<void> _showActionMenu(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.transfer),
            title: const Text('Sửa giao dịch'),
            onTap: () { Navigator.pop(ctx); _showEdit(context, ref); },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.expense),
            title: const Text('Xoá giao dịch', style: TextStyle(color: AppColors.expense)),
            onTap: () { Navigator.pop(ctx); _confirmDelete(context, ref); },
          ),
        ],
      ),
    );
  }

  Future<void> _showEdit(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditTxSheet(
        tx: tx,
        walletId: walletId,
        uid: uid,
        onSave: (updated, delta) async {
          final svc = ref.read(firestoreServiceProvider);
          final batch = svc.db.batch();
          final txRef = svc.db.collection('users').doc(uid).collection('transactions').doc(tx.id);
          final walletRef = svc.db.collection('users').doc(uid).collection('wallets').doc(walletId);
          batch.update(txRef, updated.toMap());
          if (delta != 0) {
            batch.update(walletRef, {'balance': FieldValue.increment(delta)});
          }
          await batch.commit();
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xoá giao dịch?'),
        content: Text('Xoá "${tx.category}" – ${MoneyFormatter.format(tx.amount)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final svc = ref.read(firestoreServiceProvider);
    final batch = svc.db.batch();
    final txRef = svc.db.collection('users').doc(uid).collection('transactions').doc(tx.id);
    final walletRef = svc.db.collection('users').doc(uid).collection('wallets').doc(walletId);
    batch.delete(txRef);
    // Reverse balance
    final reversal = tx.type == TransactionType.income ? -tx.amount : tx.amount;
    batch.update(walletRef, {'balance': FieldValue.increment(reversal)});
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xoá giao dịch')));
    }
  }
}

// ── Edit transaction sheet ────────────────────────────────────
class _EditTxSheet extends StatefulWidget {
  const _EditTxSheet({
    required this.tx,
    required this.walletId,
    required this.uid,
    required this.onSave,
  });
  final TransactionModel tx;
  final String walletId;
  final String uid;
  final Future<void> Function(TransactionModel updated, double delta) onSave;

  @override
  State<_EditTxSheet> createState() => _EditTxSheetState();
}

class _EditTxSheetState extends State<_EditTxSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  late String _category;
  bool _saving = false;

  static const _categories = [
    'Ăn uống', 'Xăng', 'Đi chợ', 'Học phí',
    'Mua sắm', 'Điện nước', 'Sửa chữa', 'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.tx.amount.toStringAsFixed(0);
    _noteCtrl.text   = widget.tx.note;
    _category        = _categories.contains(widget.tx.category) ? widget.tx.category : 'Khác';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newAmount = double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (newAmount == null || newAmount <= 0) return;
    setState(() => _saving = true);
    try {
      final updated = TransactionModel(
        id: widget.tx.id,
        ownerUid: widget.tx.ownerUid,
        walletId: widget.tx.walletId,
        amount: newAmount,
        type: widget.tx.type,
        category: _category,
        note: _noteCtrl.text.trim(),
        createdAt: widget.tx.createdAt,
        createdBy: widget.tx.createdBy,
      );
      // Delta cho ví: nếu thu → delta = newAmount - oldAmount; nếu chi → delta = -(newAmount - oldAmount)
      final rawDelta = newAmount - widget.tx.amount;
      final delta = widget.tx.type == TransactionType.income ? rawDelta : -rawDelta;
      await widget.onSave(updated, delta);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4, width: 44,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
            ),
          ),
          Text('Sửa giao dịch', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorFormatter()],
            decoration: const InputDecoration(labelText: 'Số tiền'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Danh mục'),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),
          TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Lưu thay đổi'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categories,
    required this.selectedMonth,
    required this.selectedYear,
    required this.selectedType,
    required this.selectedCategory,
    required this.onMonthYearChanged,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onClear,
  });

  final List<String> categories;
  final int? selectedMonth;
  final int? selectedYear;
  final String? selectedType;
  final String? selectedCategory;
  final void Function(int? month, int? year) onMonthYearChanged;
  final void Function(String?) onTypeChanged;
  final void Function(String?) onCategoryChanged;
  final VoidCallback onClear;

  bool get _hasFilter =>
      selectedMonth != null || selectedType != null || selectedCategory != null;

  static const _types = ['income', 'expense', 'transfer'];
  static const _typeLabels = {'income': 'Thu', 'expense': 'Chi', 'transfer': 'Chuyển'};

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Month/Year picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedMonth != null
                      ? DateTime(selectedYear ?? now.year, selectedMonth!)
                      : now,
                  firstDate: DateTime(now.year - 3),
                  lastDate: now,
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) {
                  onMonthYearChanged(picked.month, picked.year);
                }
              },
              child: Chip(
                label: Text(
                  selectedMonth != null
                      ? '${selectedMonth!}/${selectedYear ?? now.year}'
                      : 'Tháng',
                  style: TextStyle(
                    fontSize: 12,
                    color: selectedMonth != null ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                backgroundColor: selectedMonth != null
                    ? AppColors.primary.withOpacity(0.1)
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            // Type filter
            ..._types.map((t) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(_typeLabels[t]!, style: const TextStyle(fontSize: 12)),
                selected: selectedType == t,
                onSelected: (_) => onTypeChanged(selectedType == t ? null : t),
                selectedColor: AppColors.primary.withOpacity(0.15),
                checkmarkColor: AppColors.primary,
              ),
            )),
            // Category dropdown
            DropdownButton<String>(
              value: selectedCategory,
              hint: const Text('Danh mục', style: TextStyle(fontSize: 12)),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Tất cả')),
                ...categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))),
              ],
              onChanged: onCategoryChanged,
            ),
            if (_hasFilter) ...[
              const SizedBox(width: 6),
              TextButton(
                onPressed: onClear,
                child: const Text('Xoá lọc', style: TextStyle(fontSize: 12, color: AppColors.expense)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

