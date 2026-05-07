import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/live_location.dart';
import 'package:family_finance/shared/repositories/location_repository.dart';
import 'package:family_finance/shared/services/location_service.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider của LocationRepository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(firestore: ref.watch(firestoreProvider));
});

/// Provider của LocationService — singleton theo phiên đăng nhập.
/// Tự dừng tracking khi dispose (đăng xuất / app close).
final locationServiceProvider = Provider<LocationService?>((ref) {
  final auth = ref.watch(authControllerProvider);
  final userId = auth.user?.uid;
  final familyId = auth.profile?.familyId;
  final displayName = auth.profile?.displayName;

  if (userId == null || familyId == null || familyId.isEmpty || displayName == null) {
    return null;
  }

  final repo = ref.watch(locationRepositoryProvider);
  final service = LocationService(
    userId: userId,
    familyId: familyId,
    displayName: displayName,
    repository: repo,
  );

  // Tự dừng khi provider bị dispose
  ref.onDispose(() => service.stop());

  return service;
});

/// Stream vị trí realtime tất cả thành viên gia đình.
final familyLocationsProvider = StreamProvider.autoDispose<List<LiveLocation>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final familyId = auth.profile?.familyId;

  if (familyId == null || familyId.isEmpty) {
    return Stream.value(const <LiveLocation>[]);
  }

  return ref.watch(locationRepositoryProvider).streamFamilyLocations(familyId);
});

/// Vị trí của một thành viên cụ thể, lấy từ danh sách đã stream.
final memberLocationProvider = Provider.autoDispose.family<LiveLocation?, String>((ref, userId) {
  final locationsAsync = ref.watch(familyLocationsProvider);
  return locationsAsync.valueOrNull?.firstWhere(
    (l) => l.userId == userId,
    orElse: () => LiveLocation(
      userId: userId,
      familyId: '',
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      speed: 0,
      heading: 0,
      batteryLevel: -1,
      isMoving: false,
      isOnline: false,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  );
});
