import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tiện ích xóa toàn bộ dữ liệu người dùng (chỉ dùng khi cần reset)
class ClearTestData {
  ClearTestData._();

  static final _db = FirebaseFirestore.instance;

  /// Xóa toàn bộ dữ liệu của uid: wallets, transactions, sharedLocation
  static Future<void> clearAllUserData(String uid) async {
    debugPrint('ClearTestData: Bắt đầu xóa dữ liệu uid=$uid');

    final batch = _db.batch();

    // Xóa wallets
    final wallets = await _db.collection('users').doc(uid).collection('wallets').get();
    for (final doc in wallets.docs) {
      batch.delete(doc.reference);
    }
    debugPrint('ClearTestData: Đã xếp ${wallets.size} wallets vào batch');

    // Xóa transactions
    final txs = await _db.collection('users').doc(uid).collection('transactions').get();
    for (final doc in txs.docs) {
      batch.delete(doc.reference);
    }
    debugPrint('ClearTestData: Đã xếp ${txs.size} transactions vào batch');

    // Xóa sharedLocation
    batch.update(_db.collection('users').doc(uid), {
      'sharedLocation': FieldValue.delete(),
    });

    await batch.commit();
    debugPrint('ClearTestData: Hoàn thành xóa dữ liệu uid=$uid');
  }

  /// Xóa toàn bộ sự kiện lịch của familyId
  static Future<void> clearFamilyEvents(String familyId) async {
    final events = await _db.collection('families').doc(familyId).collection('events').get();
    final batch = _db.batch();
    for (final doc in events.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    debugPrint('ClearTestData: Đã xóa ${events.size} sự kiện của family $familyId');
  }
}
