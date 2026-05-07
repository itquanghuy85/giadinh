import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_finance/shared/models/family_photo.dart';
import 'package:family_finance/shared/services/photo_upload_service.dart';

/// [THÊM MỚI] Provider cho PhotoUploadService
final photoUploadServiceProvider = Provider((ref) => PhotoUploadService());

/// [THÊM MỚI] Provider stream danh sách ảnh gia đình
final familyPhotosProvider =
    StreamProvider.autoDispose.family<List<FamilyPhoto>, String>((ref, familyId) {
  final service = ref.watch(photoUploadServiceProvider);
  return service.streamPhotos(familyId);
});
