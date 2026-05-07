import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_finance/shared/models/anniversary.dart';
import 'package:family_finance/shared/services/anniversary_service.dart';

/// [THÊM MỚI] Provider cho AnniversaryService
final anniversaryServiceProvider = Provider((ref) => AnniversaryService());

/// [THÊM MỚI] Provider stream danh sách kỷ niệm gia đình
final familyAnniversariesProvider =
    StreamProvider.autoDispose.family<List<Anniversary>, String>((ref, familyId) {
  final service = ref.watch(anniversaryServiceProvider);
  return service.streamAnniversaries(familyId);
});
