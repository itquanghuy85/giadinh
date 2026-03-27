import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/financial_transaction.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final auth = context.watch<AuthProvider>();
    final familyId = auth.currentUser?.familyId;

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('transactions'))),
        body: const Center(child: Text('No family')),
      );
    }

    final from = _selectedMonth;
    final to = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('transactions')),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Center(
            child: Text(
              DateFormat('MM/yyyy').format(_selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: _firestoreService.transactionsStream(
          familyId,
          fromDate: from,
          toDate: to,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data ?? [];

          double totalIncome = 0;
          double totalExpense = 0;
          for (final tx in transactions) {
            if (tx.type == TransactionType.income) {
              totalIncome += tx.amount;
            } else {
              totalExpense += tx.amount;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: t('total_income'),
                      amount: totalIncome,
                      color: AppTheme.successColor,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: t('total_expense'),
                      amount: totalExpense,
                      color: AppTheme.errorColor,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                title: t('balance'),
                amount: totalIncome - totalExpense,
                color: (totalIncome - totalExpense) >= 0
                    ? AppTheme.primaryColor
                    : AppTheme.errorColor,
                icon: Icons.account_balance_wallet,
              ),
              const SizedBox(height: 24),

              if (transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long,
                            size: 48, color: AppTheme.textHint),
                        const SizedBox(height: 12),
                        Text(t('no_transactions'),
                            style: const TextStyle(
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),

              // Group by date
              ..._buildGroupedList(transactions, t),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedList(
      List<FinancialTransaction> transactions, String Function(String) t) {
    final Map<String, List<FinancialTransaction>> grouped = {};
    for (final tx in transactions) {
      final key = DateFormat('dd/MM/yyyy').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            entry.key,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );
      for (final tx in entry.value) {
        widgets.add(_TransactionTile(
          transaction: tx,
          t: t,
          onDelete: () => _firestoreService.deleteTransaction(tx.id),
        ));
      }
    }
    return widgets;
  }

  void _showAddTransactionDialog(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    TransactionType type = TransactionType.expense;
    String category = 'food';
    DateTime selectedDate = DateTime.now();

    final expenseCategories = [
      'food', 'transport', 'education', 'entertainment',
      'health', 'shopping', 'bills', 'other',
    ];
    final incomeCategories = ['salary', 'bonus', 'investment', 'other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final categories = type == TransactionType.expense
              ? expenseCategories
              : incomeCategories;
          if (!categories.contains(category)) {
            category = categories.first;
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('add_transaction'),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  // Type toggle
                  SegmentedButton<TransactionType>(
                    segments: [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text(t('expense')),
                        icon: const Icon(Icons.arrow_upward, size: 16),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text(t('income')),
                        icon: const Icon(Icons.arrow_downward, size: 16),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (val) =>
                        setState(() => type = val.first),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: t('amount'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: t('category'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(t(c)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Note
                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: t('note'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.note),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount =
                            double.tryParse(amountCtrl.text.trim()) ?? 0;
                        if (amount <= 0) return;

                        final auth = context.read<AuthProvider>();
                        final tx = FinancialTransaction(
                          id: const Uuid().v4(),
                          familyId: auth.currentUser!.familyId!,
                          createdBy: auth.currentUser!.uid,
                          type: type,
                          amount: amount,
                          category: category,
                          note: noteCtrl.text.trim().isNotEmpty
                              ? noteCtrl.text.trim()
                              : null,
                          date: selectedDate,
                          createdAt: DateTime.now(),
                        );
                        _firestoreService.createTransaction(tx);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(t('save')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                Text(
                  '${formatter.format(amount.abs())} đ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FinancialTransaction transaction;
  final String Function(String) t;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.t,
    required this.onDelete,
  });

  IconData _categoryIcon() {
    switch (transaction.category) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.local_hospital;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt;
      case 'salary':
        return Icons.work;
      case 'bonus':
        return Icons.card_giftcard;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final formatter = NumberFormat('#,###');

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isIncome ? AppTheme.successColor : AppTheme.errorColor)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _categoryIcon(),
                color: isIncome ? AppTheme.successColor : AppTheme.errorColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(transaction.category),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (transaction.note != null)
                    Text(
                      transaction.note!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${formatter.format(transaction.amount)} đ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color:
                    isIncome ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
