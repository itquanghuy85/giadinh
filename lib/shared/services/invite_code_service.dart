import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/shared/models/invite_code.dart';
import 'dart:math';

/// Service quản lý mã mời gia đình
class InviteCodeService {
  InviteCodeService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Generate mã 6 số duy nhất
  String _generateCode() {
    const chars = '0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Tạo mã mời mới
  /// expires: số ngày mã có hiệu lực (default: 30 ngày)
  Future<InviteCode> createInviteCode({
    required String familyId,
    required String invitedEmail,
    required String role,
    required String createdBy,
    int expiresInDays = 30,
  }) async {
    try {
      final code = _generateCode();
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: expiresInDays));

      final docRef = await _db.collection('families').doc(familyId).collection('invite_codes').add({
        'code': code,
        'familyId': familyId,
        'invitedEmail': invitedEmail,
        'role': role,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'usedBy': null,
        'usedAt': null,
      });

      return InviteCode(
        id: docRef.id,
        code: code,
        familyId: familyId,
        invitedEmail: invitedEmail,
        role: role,
        createdBy: createdBy,
        createdAt: now,
        expiresAt: expiresAt,
      );
    } catch (e) {
      throw Exception('Tạo mã mời thất bại: $e');
    }
  }

  /// Kiểm tra mã mời có hợp lệ không
  Future<InviteCode?> validateInviteCode(String code) async {
    try {
      // Tìm trong tất cả families (hoặc có thể query tập trung)
      final snapshot = await _db
          .collectionGroup('invite_codes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final inviteCode = InviteCode.fromMap(doc.id, doc.data());

      // Kiểm tra mã còn hợp lệ không
      if (!inviteCode.isValid) {
        return null;
      }

      return inviteCode;
    } catch (e) {
      throw Exception('Kiểm tra mã mời thất bại: $e');
    }
  }

  /// Sử dụng mã mời (ghi nhận người đã dùng)
  Future<void> redeemInviteCode({
    required String familyId,
    required String inviteCodeId,
    required String userId,
  }) async {
    try {
      await _db
          .collection('families')
          .doc(familyId)
          .collection('invite_codes')
          .doc(inviteCodeId)
          .update({
            'usedBy': userId,
            'usedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Sử dụng mã mời thất bại: $e');
    }
  }

  /// Lấy danh sách mã mời của một gia đình (chỉ admin xem được)
  Stream<List<InviteCode>> streamInviteCodes(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('invite_codes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => InviteCode.fromMap(doc.id, doc.data())).toList());
  }

  /// Xóa mã mời (admin only)
  Future<void> deleteInviteCode(String familyId, String inviteCodeId) async {
    try {
      await _db
          .collection('families')
          .doc(familyId)
          .collection('invite_codes')
          .doc(inviteCodeId)
          .delete();
    } catch (e) {
      throw Exception('Xóa mã mời thất bại: $e');
    }
  }
}
