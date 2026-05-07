import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/wallet/providers/wallet_provider.dart';
import 'package:family_finance/shared/models/fund.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/utils/money_formatter.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ─────────────────────────────────────────────────
final _fundsStreamProvider = StreamProvider.autoDispose<List<FundModel>>((ref) {
  final familyId = ref.watch(authControllerProvider).profile?.familyId ?? '';
  if (familyId.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamFunds(familyId);
});

// ═══════════════════════════════════════════════════════════════
class FundScreen extends ConsumerWidget {
  const FundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundsAsync = ref.watch(_fundsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Quỹ gia đình'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFund(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tạo quỹ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: fundsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (funds) {
          if (funds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.savings_outlined, size: 64, color: AppColors.border),
                  SizedBox(height: 12),
                  Text('Chưa có quỹ nào', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: funds.length,
            itemBuilder: (context, i) => _FundCard(fund: funds[i]),
          );
        },
      ),
    );
  }

  Future<void> _showCreateFund(BuildContext context, WidgetRef ref) async {
    final familyId = ref.read(authControllerProvider).profile?.familyId ?? '';
    final uid      = ref.read(authControllerProvider).user?.uid ?? '';
    if (familyId.isEmpty) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FundFormSheet(
        familyId: familyId,
        uid: uid,
        onSave: (fund) => ref.read(firestoreServiceProvider).addFund(familyId, fund),
      ),
    );
  }
}

// ── Fund card ─────────────────────────────────────────────────
class _FundCard extends ConsumerWidget {
  const _FundCard({required this.fund});
  final FundModel fund;

  Color get _progressColor {
    if (fund.isCompleted) return Colors.amber;
    if (fund.progress >= 0.8) return AppColors.primary;
    return AppColors.income;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = (fund.progress * 100).toStringAsFixed(0);

    return GestureDetector(
      onLongPress: () => _showMenu(context, ref),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: Color(int.parse(fund.colorHex, radix: 16)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(fund.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  Text('$pct%', style: TextStyle(fontWeight: FontWeight.w700, color: _progressColor)),
                ],
              ),
              if (fund.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(fund.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fund.progress,
                  minHeight: 8,
                  color: _progressColor,
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${MoneyFormatter.format(fund.currentAmount)} / ${MoneyFormatter.format(fund.targetAmount)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Row(
                    children: [
                      TextButton(onPressed: () => _showDeposit(context, ref), child: const Text('Nạp tiền')),
                      TextButton(
                        onPressed: fund.currentAmount > 0 ? () => _showWithdraw(context, ref) : null,
                        child: const Text('Rút'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final familyId = ref.read(authControllerProvider).profile?.familyId ?? '';
    final uid      = ref.read(authControllerProvider).user?.uid ?? '';
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Sửa quỹ'),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => _FundFormSheet(
                  familyId: familyId,
                  uid: uid,
                  existing: fund,
                  onSave: (f) => ref.read(firestoreServiceProvider).updateFund(familyId, f),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.expense),
            title: const Text('Xoá quỹ', style: TextStyle(color: AppColors.expense)),
            onTap: () async {
              Navigator.pop(ctx);
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Xoá quỹ?'),
                  content: Text('Xoá quỹ "${fund.name}"? Số tiền trong quỹ sẽ mất.'),
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
              if (ok == true) {
                await ref.read(firestoreServiceProvider).deleteFund(familyId, fund.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeposit(BuildContext context, WidgetRef ref) async {
    final familyId = ref.read(authControllerProvider).profile?.familyId ?? '';
    final uid      = ref.read(authControllerProvider).user?.uid ?? '';
    final wallets  = ref.read(walletsProvider).valueOrNull ?? [];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FundTransactionSheet(
        title: 'Nạp tiền vào "${fund.name}"',
        wallets: wallets,
        onConfirm: (amount, walletId) async {
          await ref.read(firestoreServiceProvider).depositToFund(
                familyId: familyId,
                fundId: fund.id,
                amount: amount,
                uid: uid,
                walletId: walletId,
              );
          // Check if fund reached goal after deposit
          final newAmount = fund.currentAmount + amount;
          if (newAmount >= fund.targetAmount && fund.currentAmount < fund.targetAmount) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🎉 Quỹ "${fund.name}" đã đạt mục tiêu!')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showWithdraw(BuildContext context, WidgetRef ref) async {
    final familyId = ref.read(authControllerProvider).profile?.familyId ?? '';
    final uid      = ref.read(authControllerProvider).user?.uid ?? '';
    final wallets  = ref.read(walletsProvider).valueOrNull ?? [];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FundTransactionSheet(
        title: 'Rút tiền từ "${fund.name}"',
        wallets: wallets,
        maxAmount: fund.currentAmount,
        onConfirm: (amount, walletId) => ref.read(firestoreServiceProvider).withdrawFromFund(
              familyId: familyId,
              fundId: fund.id,
              amount: amount,
              uid: uid,
              walletId: walletId,
            ),
      ),
    );
  }
}

// ── Deposit / Withdraw sheet ──────────────────────────────────
class _FundTransactionSheet extends StatefulWidget {
  const _FundTransactionSheet({
    required this.title,
    required this.wallets,
    required this.onConfirm,
    this.maxAmount,
  });
  final String title;
  final List<dynamic> wallets;
  final Future<void> Function(double amount, String walletId) onConfirm;
  final double? maxAmount;

  @override
  State<_FundTransactionSheet> createState() => _FundTransactionSheetState();
}

class _FundTransactionSheetState extends State<_FundTransactionSheet> {
  final _amountCtrl = TextEditingController();
  String? _walletId;
  bool    _saving   = false;

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập số tiền hợp lệ')));
      return;
    }
    if (widget.maxAmount != null && amount > widget.maxAmount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quỹ chỉ còn ${MoneyFormatter.format(widget.maxAmount!)}')),
      );
      return;
    }
    if (_walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chọn ví')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onConfirm(amount, _walletId!);
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
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorFormatter()],
            decoration: const InputDecoration(labelText: 'Số tiền'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Chọn ví'),
            initialValue: _walletId,
            items: widget.wallets
                .map((w) => DropdownMenuItem<String>(value: w.id as String, child: Text(w.name as String)))
                .toList(),
            onChanged: (v) => setState(() => _walletId = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Xác nhận'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create / Edit fund form ───────────────────────────────────
class _FundFormSheet extends StatefulWidget {
  const _FundFormSheet({
    required this.familyId,
    required this.uid,
    required this.onSave,
    this.existing,
  });
  final String familyId;
  final String uid;
  final FundModel? existing;
  final Future<void> Function(FundModel) onSave;

  @override
  State<_FundFormSheet> createState() => _FundFormSheetState();
}

class _FundFormSheetState extends State<_FundFormSheet> {
  final _nameCtrl   = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  String _colorHex  = 'FF534AB7';
  bool   _saving    = false;

  static const _colorOptions = [
    ('FF534AB7', Color(0xFF534AB7)),
    ('FF1D9E75', Color(0xFF1D9E75)),
    ('FFE24B4A', Color(0xFFE24B4A)),
    ('FF378ADD', Color(0xFF378ADD)),
    ('FFFF9800', Color(0xFFFF9800)),
    ('FF9C27B0', Color(0xFF9C27B0)),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text   = e.name;
      _targetCtrl.text = e.targetAmount.toStringAsFixed(0);
      _descCtrl.text   = e.description;
      _colorHex        = e.colorHex;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name   = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    if (name.isEmpty || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điền tên và mục tiêu')));
      return;
    }
    setState(() => _saving = true);
    try {
      final fund = FundModel(
        id:            widget.existing?.id ?? '',
        name:          name,
        currentAmount: widget.existing?.currentAmount ?? 0,
        targetAmount:  target,
        description:   _descCtrl.text.trim(),
        colorHex:      _colorHex,
        createdBy:     widget.uid,
      );
      await widget.onSave(fund);
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                height: 4, width: 44,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
              ),
            ),
            Text(
              widget.existing == null ? 'Tạo quỹ mới' : 'Sửa quỹ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tên quỹ')),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorFormatter()],
              decoration: const InputDecoration(labelText: 'Mục tiêu (số tiền)'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)')),
            const SizedBox(height: 12),
            const Text('Màu đại diện:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colorOptions.map(((String hex, Color color) opt) {
                final selected = _colorHex == opt.$1;
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = opt.$1),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: opt.$2,
                      shape: BoxShape.circle,
                      border: selected ? Border.all(color: Colors.black, width: 2.5) : null,
                    ),
                    child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
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
    );
  }
}

