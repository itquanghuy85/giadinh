import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    super.key,
    required this.roleRequired,
    required this.child,
    this.fallback,
  });

  final List<UserRole> roleRequired;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).profile?.role;
    if (role != null && roleRequired.contains(role)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
