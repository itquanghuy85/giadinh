import 'dart:async';

import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accessibleOwnerIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final uid = auth.user?.uid;
  final role = auth.profile?.role;
  final familyId = auth.profile?.familyId;

  if (uid == null) {
    return Stream.value(const []);
  }

  if (role == null || role == UserRole.childLimited || familyId == null || familyId.isEmpty) {
    return Stream.value([uid]);
  }

  return ref.watch(firestoreServiceProvider).streamFamilyMembers(familyId).map((members) {
    final ids = members.map((e) => e.uid).toSet();
    ids.add(uid);
    return ids.toList();
  });
});

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authControllerProvider).profile?.role;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).user?.uid;
});
