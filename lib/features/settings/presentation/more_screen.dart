import 'package:family_finance/app/routes/app_routes.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).profile?.role ?? UserRole.childLimited;

    final items = <_MoreItem>[
      if (role != UserRole.childLimited)
        _MoreItem(
          icon: Icons.analytics_outlined,
          title: 'Báo cáo tài chính',
          subtitle: 'Phân tích thu chi, xu hướng và danh mục',
          onTap: () => Navigator.pushNamed(context, AppRoutes.report),
        ),
      _MoreItem(
        icon: Icons.groups_2_outlined,
        title: 'Gia đình',
        subtitle: 'Thành viên, ảnh kỷ niệm, công nợ, quỹ',
        onTap: () => Navigator.pushNamed(context, AppRoutes.family),
      ),
      _MoreItem(
        icon: Icons.map_outlined,
        title: 'Bản đồ gia đình',
        subtitle: 'Theo dõi vị trí realtime và dẫn đường',
        onTap: () => Navigator.pushNamed(context, AppRoutes.familyMap),
      ),
      _MoreItem(
        icon: Icons.settings_outlined,
        title: 'Cài đặt',
        subtitle: 'Tài khoản, bảo mật, giao diện',
        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              child: Icon(item.icon, size: 16),
            ),
            title: Text(item.title),
            subtitle: Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: item.onTap,
          ),
        );
      },
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
