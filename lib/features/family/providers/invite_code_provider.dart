import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_finance/shared/models/invite_code.dart';
import 'package:family_finance/shared/services/invite_code_service.dart';

/// Provider cho InviteCodeService
final inviteCodeServiceProvider = Provider((ref) => InviteCodeService());

/// Provider để kiểm tra mã mời hợp lệ
final validateInviteCodeProvider =
    FutureProvider.family<InviteCode?, String>((ref, code) async {
  final service = ref.watch(inviteCodeServiceProvider);
  return service.validateInviteCode(code);
});

/// Provider để stream mã mời của một gia đình
final familyInviteCodesProvider =
    StreamProvider.autoDispose.family<List<InviteCode>, String>((ref, familyId) {
  final service = ref.watch(inviteCodeServiceProvider);
  return service.streamInviteCodes(familyId);
});
