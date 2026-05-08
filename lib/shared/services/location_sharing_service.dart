import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ chia sẻ vị trí một lần (one-shot) vào Firestore
/// Path: users/{uid}/sharedLocation
class LocationSharingService {
  LocationSharingService._();
  static final LocationSharingService instance = LocationSharingService._();

  final _db = FirebaseFirestore.instance;

  /// Lấy vị trí hiện tại và lưu vào Firestore
  Future<bool> shareMyLocation({required String uid, required String name}) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) return false;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await _db.collection('users').doc(uid).set({
        'sharedLocation': {
          'lat': position.latitude,
          'lng': position.longitude,
          'name': name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('LocationSharingService.shareMyLocation error: $e');
      return false;
    }
  }

  /// Xóa vị trí đã chia sẻ
  Future<void> clearMyLocation({required String uid}) async {
    await _db.collection('users').doc(uid).update({
      'sharedLocation': FieldValue.delete(),
    });
  }

  /// Stream vị trí chia sẻ của thành viên khác (theo uid)
  Stream<Map<String, dynamic>?> watchMemberLocation(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      return data?['sharedLocation'] as Map<String, dynamic>?;
    });
  }
}
