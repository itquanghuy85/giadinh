import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/family_event.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedCalendarDayProvider = StateProvider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final familyEventsProvider = StreamProvider.autoDispose<List<FamilyEvent>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final familyId = auth.profile?.familyId;
  debugPrint('[Calendar] familyEventsProvider: uid=${auth.user?.uid}, familyId=$familyId');

  if (familyId == null || familyId.isEmpty) {
    debugPrint('[Calendar] ⚠️ familyId is null/empty → return empty events');
    return Stream.value(const []);
  }

  debugPrint('[Calendar] 🔄 Querying Firestore events for familyId=$familyId');
  return ref.watch(firestoreServiceProvider).streamEvents(familyId);
});

final selectedDayEventsProvider = Provider.autoDispose<List<FamilyEvent>>((ref) {
  final selected = ref.watch(selectedCalendarDayProvider);
  final events = ref.watch(familyEventsProvider).valueOrNull ?? const <FamilyEvent>[];

  return events.where((event) {
    final d = event.startAt;
    return d.year == selected.year && d.month == selected.month && d.day == selected.day;
  }).toList();
});
