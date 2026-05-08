import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/app/theme/app_space.dart';
import 'package:family_finance/app/routes/app_routes.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/family/providers/family_provider.dart';
import 'package:family_finance/features/family/providers/anniversary_provider.dart';
import 'package:family_finance/features/family/presentation/add_anniversary_dialog.dart';
import 'package:family_finance/features/family/presentation/add_member_screen.dart';
import 'package:family_finance/features/family/presentation/photo_viewer_screen.dart';
import 'package:family_finance/features/family/providers/photo_provider.dart';
import 'package:family_finance/features/family/presentation/photo_upload_dialog.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/shared/widgets/role_guard.dart';
import 'package:family_finance/shared/widgets/secure_money_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = ref.watch(authControllerProvider).profile?.familyId;

    if (familyId == null || familyId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_2_outlined, size: 52, color: AppColors.border),
              const SizedBox(height: 12),
              Text('Bạn chưa tham gia gia đình nào', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              const Text(
                'Nhập mã mời để tham gia gia đình và đồng bộ dữ liệu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.joinFamily),
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Nhập mã mời'),
              ),
            ],
          ),
        ),
      );
    }

    final membersAsync = ref.watch(familyMembersProvider);
    final fundsAsync = ref.watch(familyFundsProvider);
    final debtsAsync = ref.watch(familyDebtsProvider);

    if (membersAsync.isLoading || fundsAsync.isLoading || debtsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (membersAsync.hasError || fundsAsync.hasError || debtsAsync.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Không tải được dữ liệu gia đình.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                ref.invalidate(familyMembersProvider);
                ref.invalidate(familyFundsProvider);
                ref.invalidate(familyDebtsProvider);
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final members = membersAsync.valueOrNull ?? const [];
    final funds = fundsAsync.valueOrNull ?? const [];
    final debts = debtsAsync.valueOrNull ?? const [];
    final anniversariesAsync = ref.watch(familyAnniversariesProvider(familyId));
    final anniversaries = anniversariesAsync.valueOrNull ?? const [];
    final photosAsync = ref.watch(familyPhotosProvider(familyId));
    final photos = photosAsync.valueOrNull ?? const [];
    final uid = ref.watch(authControllerProvider).user?.uid ?? '';

    return ListView(
      padding: AppSpace.screen,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Thành viên', style: Theme.of(context).textTheme.titleLarge),
            RoleGuard(
              roleRequired: const [UserRole.fatherAdmin],
              child: FilledButton.tonal(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMemberScreen(familyId: familyId),
                  ),
                ),
                child: const Text('+ Thêm thành viên'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...members.map((member) {
          return Card(
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              leading: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(member.name.characters.first.toUpperCase()),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.income,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ],
              ),
              title: Text(member.name),
              subtitle: Text(member.role),
              trailing: SecureMoneyText(amount: member.balance),
            ),
          );
        }),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ảnh kỷ niệm', style: Theme.of(context).textTheme.titleMedium),
                    FilledButton.tonal(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => PhotoUploadDialog(
                          familyId: familyId,
                          uid: uid,
                          onSuccess: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ảnh được tải lên thành công')),
                          ),
                        ),
                      ),
                      child: const Text('+ Thêm'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (photosAsync.isLoading)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                    itemCount: 6,
                    itemBuilder: (_, __) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.border,
                      ),
                    ),
                  )
                else if (photosAsync.hasError)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.broken_image_outlined, color: AppColors.expense),
                      title: const Text('Không tải được ảnh kỷ niệm'),
                      subtitle: Text('${photosAsync.error}'),
                      trailing: TextButton(
                        onPressed: () => ref.invalidate(familyPhotosProvider(familyId)),
                        child: const Text('Thử lại'),
                      ),
                    ),
                  )
                else if (photos.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text('Chưa có ảnh', style: Theme.of(context).textTheme.bodyMedium)),
                    ),
                  )
                else
                  SizedBox(
                    height: 118,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final photo = photos[index];
                        final canDelete = photo.uploadedBy == uid || members.any((m) => m.uid == uid && (m.role == 'fatherAdmin' || m.role == 'motherManager'));
                        return SizedBox(
                          width: 150,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PhotoViewerScreen(
                                  photos: photos,
                                  initialIndex: index,
                                ),
                              ),
                            ),
                            onLongPress: canDelete
                                ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (_) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: ListTile(
                                          leading: const Icon(Icons.delete, color: Colors.red),
                                          title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            try {
                                              await ref.read(photoUploadServiceProvider).deletePhoto(familyId, photo.id);
                                              ref.invalidate(familyPhotosProvider(familyId));
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Ảnh đã xóa')),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi: $e')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Colors.grey[200]),
                                child: CachedNetworkImage(
                                  imageUrl: photo.thumbnailUrl.isNotEmpty ? photo.thumbnailUrl : photo.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  errorWidget: (_, __, ___) => const Center(
                                    child: Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kỷ niệm', style: Theme.of(context).textTheme.titleMedium),
            RoleGuard(
              roleRequired: const [UserRole.fatherAdmin, UserRole.motherManager],
              child: anniversariesAsync.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : FilledButton.tonal(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AddAnniversaryDialog(
                          familyId: familyId,
                          uid: uid,
                          members: members,
                          onSuccess: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kỷ niệm được tạo thành công')),
                          ),
                        ),
                      ),
                      child: const Text('+ Thêm'),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (anniversariesAsync.hasError)
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: AppColors.expense),
              title: const Text('Không tải được kỷ niệm'),
              subtitle: Text('${anniversariesAsync.error}'),
              trailing: TextButton(
                onPressed: () => ref.invalidate(familyAnniversariesProvider(familyId)),
                child: const Text('Thử lại'),
              ),
            ),
          )
        else if (anniversariesAsync.isLoading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (anniversaries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('Chưa có kỷ niệm', style: Theme.of(context).textTheme.bodyMedium)),
            ),
          )
        else
          ...anniversaries.map((anniversary) {
            final daysUntil = anniversary.daysUntil();
            final isToday = daysUntil == 0;
            final isSoon = daysUntil <= 3 && daysUntil > 0;
            return Card(
              color: isToday ? Colors.amber.withValues(alpha: 0.15) : (isSoon ? Colors.orange.withValues(alpha: 0.1) : null),
              child: ListTile(
                title: Text(
                  anniversary.title,
                  style: isToday ? const TextStyle(fontWeight: FontWeight.w700, color: Colors.amber) : null,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(anniversary.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isToday)
                      const Chip(label: Text('Hôm nay!', style: TextStyle(fontSize: 12, color: Colors.white)), backgroundColor: Colors.amber)
                    else
                      Text(
                        '$daysUntil ngày nữa',
                        style: TextStyle(fontWeight: FontWeight.w600, color: isSoon ? Colors.orange : null),
                      ),
                  ],
                ),
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                            onTap: () async {
                              Navigator.pop(context);
                              try {
                                await ref
                                    .read(anniversaryServiceProvider)
                                    .deleteAnniversary(familyId, anniversary.id);
                                ref.invalidate(familyAnniversariesProvider(familyId));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kỷ niệm đã xóa')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        const SizedBox(height: 10),
        Text('Quỹ gia đình', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...funds.map((fund) {
          return Card(
            child: ListTile(
              title: Text(fund.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: fund.progress,
                    borderRadius: BorderRadius.circular(12),
                    minHeight: 6,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ],
              ),
              trailing: Text('${(fund.progress * 100).toStringAsFixed(0)}%'),
            ),
          );
        }),
        const SizedBox(height: 10),
        RoleGuard(
          roleRequired: const [UserRole.fatherAdmin, UserRole.motherManager],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Công nợ', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...debts.map((debt) {
                final color = debt.status == 'done' ? AppColors.income : AppColors.expense;
                final due = DateFormat('dd/MM/yyyy').format(debt.dueDate);
                return Card(
                  child: ListTile(
                    title: Text('${debt.fromName} nợ ${debt.toName}'),
                    subtitle: Text('Hạn trả: $due · ${debt.status}'),
                    trailing: Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(debt.amount),
                      style: TextStyle(color: color, fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
