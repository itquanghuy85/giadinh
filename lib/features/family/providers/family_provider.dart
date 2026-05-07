import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/debt.dart';
import 'package:family_finance/shared/models/family_member.dart';
import 'package:family_finance/shared/models/fund.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final familyMembersProvider = StreamProvider.autoDispose<List<FamilyMember>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final familyId = auth.profile?.familyId;
  debugPrint('[Family] familyMembersProvider: uid=${auth.user?.uid}, familyId=$familyId');
  if (familyId == null || familyId.isEmpty) {
    debugPrint('[Family] ⚠️ familyId is null/empty → return empty members');
    return Stream.value(const []);
  }

  debugPrint('[Family] 🔄 Querying Firestore members for familyId=$familyId');
  return ref.watch(firestoreServiceProvider).streamFamilyMembers(familyId);
});

final familyFundsProvider = StreamProvider.autoDispose<List<FundModel>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final familyId = auth.profile?.familyId;
  debugPrint('[Family] familyFundsProvider: uid=${auth.user?.uid}, familyId=$familyId');
  if (familyId == null || familyId.isEmpty) {
    debugPrint('[Family] ⚠️ familyId is null/empty → return empty funds');
    return Stream.value(const []);
  }

  debugPrint('[Family] 🔄 Querying Firestore funds for familyId=$familyId');
  return ref.watch(firestoreServiceProvider).streamFunds(familyId);
});

final familyDebtsProvider = StreamProvider.autoDispose<List<DebtModel>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final familyId = auth.profile?.familyId;
  debugPrint('[Family] familyDebtsProvider: uid=${auth.user?.uid}, familyId=$familyId');
  if (familyId == null || familyId.isEmpty) {
    debugPrint('[Family] ⚠️ familyId is null/empty → return empty debts');
    return Stream.value(const []);
  }

  debugPrint('[Family] 🔄 Querying Firestore debts for familyId=$familyId');
  return ref.watch(firestoreServiceProvider).streamDebts(familyId);
});
