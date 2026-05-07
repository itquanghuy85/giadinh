import 'package:cloud_firestore/cloud_firestore.dart';

/// [THÊM MỚI] Service quản lý chỉnh sửa ví
class WalletEditService {
  WalletEditService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Cập nhật số dư ví
  Future<void> updateBalance(String uid, String walletId, double newBalance) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('wallets')
          .doc(walletId)
          .update({'balance': newBalance});
    } catch (e) {
      throw Exception('Cập nhật số dư thất bại: $e');
    }
  }

  /// Cập nhật tên ví
  Future<void> updateName(String uid, String walletId, String newName) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('wallets')
          .doc(walletId)
          .update({'name': newName});
    } catch (e) {
      throw Exception('Cập nhật tên ví thất bại: $e');
    }
  }

  /// Cập nhật màu ví (hex format)
  Future<void> updateColor(String uid, String walletId, String colorHex) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('wallets')
          .doc(walletId)
          .update({'colorHex': colorHex});
    } catch (e) {
      throw Exception('Cập nhật màu ví thất bại: $e');
    }
  }

  /// Xóa ví
  Future<void> deleteWallet(String uid, String walletId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('wallets')
          .doc(walletId)
          .delete();
    } catch (e) {
      throw Exception('Xóa ví thất bại: $e');
    }
  }

  /// [THÊM MỚI] Tạo ví mới
  Future<void> createWallet({
    required String uid,
    required String name,
    required double balance,
    required String colorHex,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('wallets')
          .add({
        'name': name,
        'balance': balance,
        'colorHex': colorHex,
        'ownerUid': uid,
      });
    } catch (e) {
      throw Exception('Tạo ví thất bại: $e');
    }
  }
}
