import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/transaction.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/utils/money_formatter.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<TransactionModel> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final uid = ref.read(authControllerProvider).user?.uid ?? '';
      if (uid.isEmpty) return;
      final svc = ref.read(firestoreServiceProvider);
      // Load recent transactions (paginated, client-side filter)
      final result = await svc.getTransactionsPaginated(uid, limit: 200);
      final filtered = result.data.where((t) {
        return t.category.toLowerCase().contains(q) ||
            t.note.toLowerCase().contains(q) ||
            t.amount.toStringAsFixed(0).contains(q);
      }).toList();
      setState(() => _results = filtered);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm giao dịch...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _results = []);
              },
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : _searchCtrl.text.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 64, color: AppColors.border),
                      SizedBox(height: 12),
                      Text('Nhập từ khoá để tìm kiếm',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? const Center(
                      child: Text('Không tìm thấy kết quả',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final tx = _results[i];
                        final color = tx.type == TransactionType.income
                            ? AppColors.income
                            : tx.type == TransactionType.transfer
                                ? AppColors.transfer
                                : AppColors.expense;
                        final sign = tx.type == TransactionType.income ? '+' : '-';
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.12),
                              radius: 18,
                              child: Text(sign,
                                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
                            ),
                            title: Text(tx.category,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tx.note.isNotEmpty)
                                  Text(tx.note, style: const TextStyle(fontSize: 12)),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(tx.createdAt),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '$sign${MoneyFormatter.format(tx.amount)}',
                              style: TextStyle(fontWeight: FontWeight.w700, color: color),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
