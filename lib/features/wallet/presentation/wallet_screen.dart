import 'package:family_finance/app/routes/app_routes.dart';
import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/features/wallet/providers/wallet_provider.dart';
import 'package:family_finance/shared/models/transaction.dart';
import 'package:family_finance/shared/providers/access_scope_provider.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/widgets/role_guard.dart';
import 'package:family_finance/shared/widgets/secure_money_text.dart';
import 'package:family_finance/features/wallet/presentation/wallet_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 120) {
      return;
    }

    ref.read(walletTransactionsProvider.notifier).loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletsProvider);
    final txState = ref.watch(walletTransactionsProvider);
    final role = ref.watch(currentUserRoleProvider) ?? UserRole.childLimited;
    final currentUid = ref.watch(currentUserIdProvider);

    return walletAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Không tải được danh sách ví: $error'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                ref.invalidate(walletsProvider);
                ref.invalidate(walletTransactionsProvider);
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (wallets) {
        if (wallets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 72, color: AppColors.border),
                const SizedBox(height: 16),
                Text('Chưa có ví nào', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Tạo ví đầu tiên để bắt đầu theo dõi chi tiêu', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                if (role != UserRole.childLimited)
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm ví đầu tiên'),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AddWalletDialog(
                        uid: currentUid ?? '',
                        onSuccess: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ví mới được tạo')),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Danh sách ví', style: Theme.of(context).textTheme.titleLarge),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
                      tooltip: 'Tìm kiếm giao dịch',
                    ),
                    Chip(label: Text('Vai trò: ${role.name}')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (role != UserRole.childLimited)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm ví'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AddWalletDialog(
                      uid: currentUid ?? '',
                      onSuccess: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ví mới được tạo')),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ...wallets.map((wallet) {
              final canOpenDetail = role != UserRole.childLimited || wallet.ownerUid == currentUid;
              final canEdit = wallet.ownerUid == currentUid || role == UserRole.fatherAdmin;
              final safeUid = currentUid;
              return GestureDetector(
                onLongPress: canEdit && safeUid != null
                    ? () => _showWalletMenu(context, wallet, safeUid)
                    : null,
                child: Card(
                  child: ListTile(
                    onTap: canOpenDetail
                        ? () => Navigator.pushNamed(context, AppRoutes.walletDetail, arguments: wallet)
                        : null,
                    leading: CircleAvatar(backgroundColor: wallet.dotColor, radius: 6),
                    title: Text(wallet.name),
                    subtitle: wallet.ownerUid == currentUid ? null : Text('Chủ ví: ${wallet.ownerUid}'),
                    trailing: SecureMoneyText(amount: wallet.balance),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Text('Giao dịch gần đây', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...txState.items.map((item) => _TransactionTile(item: item)),
            if (txState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(txState.error!, style: const TextStyle(color: AppColors.expense)),
              ),
            if (txState.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!txState.hasMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text('Đã tải hết giao dịch')),
              ),
          ],
        );
      },
    );
  }

  /// [THÊM MỚI] Hiển thị menu dài (long press)
  void _showWalletMenu(BuildContext context, var wallet, String currentUid) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Sửa số dư'),
              onTap: () {
                Navigator.pop(sheetContext);
                showDialog(
                  context: context,
                  builder: (_) => EditBalanceDialog(
                    wallet: wallet,
                    uid: currentUid,
                    onSuccess: () => messenger.showSnackBar(
                      const SnackBar(content: Text('Cập nhật thành công')),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Đổi tên ví'),
              onTap: () {
                Navigator.pop(sheetContext);
                showDialog(
                  context: context,
                  builder: (_) => EditNameDialog(
                    wallet: wallet,
                    uid: currentUid,
                    onSuccess: () => messenger.showSnackBar(
                      const SnackBar(content: Text('Cập nhật thành công')),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa ví', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                showDialog(
                  context: context,
                  builder: (_) => DeleteWalletDialog(
                    wallet: wallet,
                    uid: currentUid,
                    onSuccess: () => messenger.showSnackBar(
                      const SnackBar(content: Text('Xóa thành công')),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.item});

  final TransactionModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider) ?? UserRole.childLimited;
    final currentUid = ref.watch(currentUserIdProvider);
    final canDelete = role == UserRole.fatherAdmin ||
        (role == UserRole.motherManager && currentUid != null && currentUid == item.ownerUid);
    final isIncome = item.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final sign = isIncome ? '+' : '-';
    final amount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(item.amount);

    return Card(
      child: ListTile(
        title: Text(item.category),
        subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt)} · ${item.note}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$sign$amount',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            RoleGuard(
              roleRequired: const [UserRole.fatherAdmin, UserRole.motherManager],
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: canDelete
                    ? () async {
                        await ref.read(firestoreServiceProvider).deleteTransaction(item.ownerUid, item.id);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
