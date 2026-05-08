import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/app/theme/app_space.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/family/providers/family_provider.dart';
import 'package:family_finance/shared/services/location_sharing_service.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'family_map_view_screen.dart';

class FamilyMapMembersScreen extends ConsumerStatefulWidget {
  const FamilyMapMembersScreen({super.key});

  @override
  ConsumerState<FamilyMapMembersScreen> createState() => _FamilyMapMembersScreenState();
}

class _FamilyMapMembersScreenState extends ConsumerState<FamilyMapMembersScreen> {
  bool _sharing = false;
  bool _isShared = false;

  Future<void> _toggleShare() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.user?.uid;
    final name = auth.profile?.displayName ?? 'Bạn';
    if (uid == null) return;

    setState(() => _sharing = true);
    try {
      if (_isShared) {
        await LocationSharingService.instance.clearMyLocation(uid: uid);
        setState(() => _isShared = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tắt chia sẻ vị trí')),
          );
        }
      } else {
        final ok = await LocationSharingService.instance.shareMyLocation(uid: uid, name: name);
        if (ok) {
          setState(() => _isShared = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã chia sẻ vị trí của bạn')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể lấy vị trí. Vui lòng cấp quyền.')),
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);
    final myUid = ref.watch(authControllerProvider).user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Bản đồ gia đình'),
        actions: [
          if (_sharing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                onPressed: _toggleShare,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isShared ? Icons.location_off_outlined : Icons.my_location,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(_isShared ? 'Tắt vị trí' : 'Chia sẻ vị trí'),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('Chưa có thành viên nào'));
          }
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isShared
                      ? AppColors.income.withValues(alpha: 0.1)
                      : AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _isShared ? AppColors.income : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isShared ? Icons.location_on : Icons.location_off_outlined,
                      color: _isShared ? AppColors.income : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isShared
                          ? 'Vị trí của bạn đang được chia sẻ'
                          : 'Nhấn "Chia sẻ vị trí" để các thành viên thấy bạn',
                      style: TextStyle(
                        color: _isShared ? AppColors.income : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isMe = member.uid == myUid;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            member.name.isNotEmpty
                                ? member.name.characters.first.toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(member.name),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Bạn',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(member.role, style: const TextStyle(fontSize: 12)),
                        trailing: isMe
                            ? null
                            : TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FamilyMapViewScreen(
                                      memberUid: member.uid,
                                      memberName: member.name,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.map_outlined, size: 16),
                                label: const Text('Xem'),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
