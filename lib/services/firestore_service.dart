import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/family.dart';
import '../models/location_data.dart';
import '../models/geofence.dart';
import '../models/sos_alert.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── USER OPERATIONS ───

  Future<void> createUser(AppUser user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestore());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> userStream(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update(data);
  }

  Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // ─── FAMILY OPERATIONS ───

  Future<void> createFamily(Family family) async {
    await _db
        .collection(AppConstants.familiesCollection)
        .doc(family.id)
        .set(family.toFirestore());
  }

  Future<Family?> getFamily(String familyId) async {
    final doc = await _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .get();
    if (!doc.exists) return null;
    return Family.fromFirestore(doc);
  }

  Future<Family?> getFamilyByCode(String code) async {
    final query = await _db
        .collection(AppConstants.familiesCollection)
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Family.fromFirestore(query.docs.first);
  }

  Stream<Family?> familyStream(String familyId) {
    return _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .snapshots()
        .map((doc) => doc.exists ? Family.fromFirestore(doc) : null);
  }

  Future<void> addMemberToFamily(String familyId, String userId) async {
    await _db
        .collection(AppConstants.familiesCollection)
        .doc(familyId)
        .update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  // ─── LOCATION OPERATIONS ───

  Future<void> updateLocation(LocationData location) async {
    await _db
        .collection(AppConstants.locationsCollection)
        .doc(location.userId)
        .set(location.toFirestore());
  }

  Future<void> addLocationHistory(LocationData location) async {
    await _db
        .collection(AppConstants.locationsCollection)
        .doc(location.userId)
        .collection('history')
        .add(location.toFirestore());
  }

  Stream<LocationData?> locationStream(String userId) {
    return _db
        .collection(AppConstants.locationsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? LocationData.fromFirestore(doc) : null);
  }

  Stream<List<LocationData>> locationHistoryStream(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _db
        .collection(AppConstants.locationsCollection)
        .doc(userId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(100);

    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => LocationData.fromFirestore(doc)).toList());
  }

  // ─── GEOFENCE OPERATIONS ───

  Future<void> createGeofence(Geofence geofence) async {
    await _db
        .collection(AppConstants.geofencesCollection)
        .doc(geofence.id)
        .set(geofence.toFirestore());
  }

  Future<void> deleteGeofence(String geofenceId) async {
    await _db
        .collection(AppConstants.geofencesCollection)
        .doc(geofenceId)
        .delete();
  }

  Stream<List<Geofence>> geofencesStream(String familyId) {
    return _db
        .collection(AppConstants.geofencesCollection)
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Geofence.fromFirestore(doc)).toList());
  }

  // ─── SOS OPERATIONS ───

  Future<void> createSosAlert(SosAlert alert) async {
    await _db
        .collection(AppConstants.sosAlertsCollection)
        .doc(alert.id)
        .set(alert.toFirestore());
  }

  Future<void> resolveSosAlert(String alertId) async {
    await _db
        .collection(AppConstants.sosAlertsCollection)
        .doc(alertId)
        .update({'isResolved': true});
  }

  Stream<List<SosAlert>> sosAlertsStream(String familyId) {
    return _db
        .collection(AppConstants.sosAlertsCollection)
        .where('familyId', isEqualTo: familyId)
        .where('isResolved', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SosAlert.fromFirestore(doc)).toList());
  }

  // ─── FAMILY MEMBERS ───

  Stream<List<AppUser>> familyMembersStream(String familyId) {
    return _db
        .collection(AppConstants.usersCollection)
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  Stream<List<AppUser>> familyChildrenStream(String familyId) {
    return _db
        .collection(AppConstants.usersCollection)
        .where('familyId', isEqualTo: familyId)
        .where('role', isEqualTo: 'child')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }
}
