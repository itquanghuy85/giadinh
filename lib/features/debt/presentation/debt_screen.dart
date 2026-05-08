import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/wallet/providers/wallet_provider.dart';
import 'package:family_finance/shared/models/debt.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/utils/money_formatter.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ── Provider ─────────────────────────────────────────────────
final _debtsStreamProvider = StreamProvider.autoDispose<List<DebtModel>>((ref) {
  final familyId = ref.watch(authControllerProvider).profile?.familyId ?? '';
  if (familyId.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamDebts(familyId);
});

// ═══════════════════════════════════════════════════════════════
class DebtScreen extends ConsumerStatefulWidget {
  const DebtScreen({super.key});

  @override
  ConsumerState<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends ConsumerState<DebtScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(_debtsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Công nợ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cần thu'),
            Tab(text: 'Cần trả'),
          ],
          labelColor: AppColors.income,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.income,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDebt,
        icon: const Icon(Icons.add),
        label: const Text('Thêm công nợ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (debts) {
          final lends   = debts.where((d) => d.direction == 'lend').toList();
          final borrows = debts.where((d) => d.direction == 'borrow').toList();
          final totalLend   = lends.where((d) => !d.isPaid).fold(0.0, (s, d) => s + d.amount);
          final totalBorrow = borrows.where((d) => !d.isPaid).fold(0.0, (s, d) => s + d.amount);
          return Column(
            children: [
              // KPI bar
              if (debts.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _KpiChip(label: 'Cần thu', amount: totalLend, color: AppColors.income),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 28, color: AppColors.border),
                      const SizedBox(width: 12),
                      _KpiChip(label: 'Cần trả', amount: totalBorrow, color: AppColors.expense),
                      const Spacer(),
                      Text('Net: ',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        MoneyFormatter.format(totalLend - totalBorrow),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: (totalLend - totalBorrow) >= 0 ? AppColors.income : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DebtList(debts: lends,   color: AppColors.income,  onAction: _onAction),
                    _DebtList(debts: borrows, color: AppColors.expense,  onAction: _onAction),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onAction(_DebtAction action, DebtModel debt) {
    switch (action) {
      case _DebtAction.markPaid:
        _confirmMarkPaid(debt);
      case _DebtAction.edit:
        _showAddDebt(existing: debt);
      case _DebtAction.delete:
        _confirmDelete(debt);
    }
  }

  Future<void> _confirmMarkPaid(DebtModel debt) async {
    final auth     = ref.read(authControllerProvider);
    final uid      = auth.user?.uid ?? '';
    final familyId = auth.profile?.familyId ?? '';
    final wallets  = ref.read(walletsProvider).valueOrNull ?? [];

    String? chosenWallet;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Xác nhận đã trả'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Đánh dấu "${debt.personName}" ${debt.isLend ? "đã trả cho bạn" : "bạn đã trả"} '
                  '${MoneyFormatter.format(debt.amount)}?'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Cộng/trừ vào ví (tuỳ chọn)'),
                initialValue: chosenWallet,
                items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                onChanged: (v) => setSt(() => chosenWallet = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    // lend → nhận tiền về (cộng ví), borrow → trả tiền đi (trừ ví)
    final delta = debt.isLend ? debt.amount : -debt.amount;
    await ref.read(firestoreServiceProvider).markDebtPaid(
          familyId: familyId,
          debt: debt,
          uid: uid,
          walletId: chosenWallet,
          walletDelta: chosenWallet != null ? delta : null,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật trạng thái')));
  }

  Future<void> _confirmDelete(DebtModel debt) async {
    final familyId = ref.read(authControllerProvider).profile?.familyId ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá công nợ?'),
        content: Text('Xoá khoản "${debt.personName}" – ${MoneyFormatter.format(debt.amount)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(firestoreServiceProvider).deleteDebt(familyId, debt.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xoá công nợ')));
  }

  Future<void> _showAddDebt({DebtModel? existing}) async {
    final familyId = ref.read(authControllerProvider).profile?.familyId ?? '';
    final uid      = ref.read(authControllerProvider).user?.uid ?? '';
    if (familyId.isEmpty) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddDebtSheet(
        familyId: familyId,
        uid: uid,
        existing: existing,
        onSave: (debt) async {
          if (existing == null) {
            await ref.read(firestoreServiceProvider).addDebt(familyId, debt);
          } else {
            await ref.read(firestoreServiceProvider).updateDebt(familyId, debt);
          }
        },
      ),
    );
  }
}

// ── Tab list ─────────────────────────────────────────────────
enum _DebtAction { markPaid, edit, delete }

class _DebtList extends StatelessWidget {
  const _DebtList({required this.debts, required this.color, required this.onAction});
  final List<DebtModel> debts;
  final Color color;
  final void Function(_DebtAction, DebtModel) onAction;

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.border),
            SizedBox(height: 12),
            Text('Chưa có công nợ nào', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: debts.length,
      itemBuilder: (context, i) {
        final debt = debts[i];
        return Dismissible(
          key: ValueKey(debt.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.expense.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => onAction(_DebtAction.edit, debt),
                  icon: const Icon(Icons.edit, color: AppColors.transfer),
                ),
                IconButton(
                  onPressed: () => onAction(_DebtAction.delete, debt),
                  icon: const Icon(Icons.delete, color: AppColors.expense),
                ),
              ],
            ),
          ),
          confirmDismiss: (_) async {
            onAction(_DebtAction.edit, debt);
            return false;
          },
          child: _DebtCard(debt: debt, color: color, onAction: onAction),
        );
      },
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt, required this.color, required this.onAction});
  final DebtModel debt;
  final Color color;
  final void Function(_DebtAction, DebtModel) onAction;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(debt.dueDate);
    final badgeColor = debt.isPaid
        ? Colors.grey
        : debt.isOverdue
            ? AppColors.expense
            : color;
    final badgeText = debt.isPaid
        ? 'Đã trả'
        : debt.isOverdue
            ? 'Quá hạn'
            : 'Đang chờ';

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          radius: 16,
          child: Icon(debt.isLend ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 14),
        ),
        title: Text(debt.personName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
          'Hạn: $dateStr${debt.note.isNotEmpty ? ' · ${debt.note}' : ''}',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MoneyFormatter.format(debt.amount),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badgeText, style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        onTap: debt.isPaid
            ? null
            : () => onAction(_DebtAction.markPaid, debt),
      ),
    );
  }
}

// ── KPI chip ─────────────────────────────────────────────────
class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.label, required this.amount, required this.color});
  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text(MoneyFormatter.format(amount),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ── Add/Edit sheet ────────────────────────────────────────────
class _AddDebtSheet extends StatefulWidget {
  const _AddDebtSheet({
    required this.familyId,
    required this.uid,
    required this.onSave,
    this.existing,
  });
  final String familyId;
  final String uid;
  final DebtModel? existing;
  final Future<void> Function(DebtModel) onSave;

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  DateTime _dueDate     = DateTime.now().add(const Duration(days: 7));
  String   _direction   = 'lend';
  bool     _saving      = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text   = e.personName;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _noteCtrl.text   = e.note;
      _dueDate          = e.dueDate;
      _direction        = e.direction;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _nameCtrl.text.isNotEmpty || _amountCtrl.text.isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Huỷ?'),
        content: const Text('Dữ liệu chưa lưu sẽ mất.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Tiếp tục')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Thoát')),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _save() async {
    final name   = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final debt = DebtModel(
        id:         widget.existing?.id ?? '',
        personName: name,
        amount:     amount,
        dueDate:    _dueDate,
        direction:  _direction,
        status:     widget.existing?.status ?? 'pending',
        note:       _noteCtrl.text.trim(),
        createdBy:  widget.uid,
        createdAt:  widget.existing?.createdAt ?? DateTime.now(),
      );
      await widget.onSave(debt);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && mounted) Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 4, width: 44,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Text(
                widget.existing == null ? 'Thêm công nợ' : 'Sửa công nợ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'lend',   label: Text('Cho vay (cần thu)')),
                  ButtonSegment(value: 'borrow', label: Text('Đi vay (cần trả)')),
                ],
                selected: {_direction},
                onSelectionChanged: (v) => setState(() => _direction = v.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên người'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorFormatter()],
                decoration: const InputDecoration(labelText: 'Số tiền'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Ngày hạn'),
                  child: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
              ),
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
                      : const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

