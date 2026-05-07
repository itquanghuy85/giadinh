import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/shared/models/live_location.dart';

/// Repository để đọc/ghi vị trí realtime từ Firestore.
/// Collection: live_locations/{userId}
class LocationRepository {
  LocationRepository({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;

  /// Stream tất cả vị trí thành viên trong cùng familyId.
  Stream<List<LiveLocation>> streamFamilyLocations(String familyId) {
    return _db
        .collection('live_locations')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => LiveLocation.fromMap(doc.id, doc.data())).toList();
    }).handleError((error, stackTrace) {
      developer.log(
        '[LocationRepo] streamFamilyLocations error: $error',
        stackTrace: stackTrace,
      );
    });
  }

  /// Tạo hoặc cập nhật vị trí của một user.
  Future<void> updateLocation(LiveLocation location) async {
    try {
      await _db.collection('live_locations').doc(location.userId).set(
            location.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      developer.log('[LocationRepo] updateLocation error: $e');
      rethrow;
    }
  }

  /// Đánh dấu user offline khi dừng tracking.
  Future<void> setOffline(String userId) async {
    try {
      await _db.collection('live_locations').doc(userId).update({
        'isOnline': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('[LocationRepo] setOffline error: $e');
      // Không rethrow — offline update thất bại không nên crash app
    }
  }

  /// Xóa vị trí khi user đăng xuất.
  Future<void> deleteLocation(String userId) async {
    try {
      await _db.collection('live_locations').doc(userId).delete();
    } catch (e) {
      developer.log('[LocationRepo] deleteLocation error: $e');
    }
  }
}
