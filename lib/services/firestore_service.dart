import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/family.dart';
import '../models/location_data.dart';
import '../models/geofence.dart';
import '../models/sos_alert.dart';
import '../models/daily_report.dart';
import '../models/timeline_event.dart';
import '../models/danger_zone.dart';
import '../models/schedule_config.dart';
import '../models/family_event.dart';
import '../models/security_event.dart';
import '../models/screen_time_config.dart';
import '../models/app_management_config.dart';
import '../models/content_filter_config.dart';
import '../models/financial_transaction.dart';

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

  // ─── DAILY REPORT OPERATIONS ───

  Future<void> saveDailyReport(DailyReport report) async {
    await _db
        .collection(AppConstants.dailyReportsCollection)
        .doc(report.id)
        .set(report.toFirestore(), SetOptions(merge: true));
  }

  Future<DailyReport?> getDailyReport(String userId, String date) async {
    final query = await _db
        .collection(AppConstants.dailyReportsCollection)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return DailyReport.fromFirestore(query.docs.first);
  }

  Stream<DailyReport?> dailyReportStream(String userId, String date) {
    return _db
        .collection(AppConstants.dailyReportsCollection)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty
            ? DailyReport.fromFirestore(snapshot.docs.first)
            : null);
  }

  // ─── TIMELINE OPERATIONS ───

  Future<void> saveTimelineEvent(TimelineEvent event) async {
    await _db
        .collection(AppConstants.timelineEventsCollection)
        .doc(event.id)
        .set(event.toFirestore(), SetOptions(merge: true));
  }

  Stream<List<TimelineEvent>> timelineEventsStream(
      String userId, String date) {
    return _db
        .collection(AppConstants.timelineEventsCollection)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TimelineEvent.fromFirestore(doc))
            .toList());
  }

  // ─── DANGER ZONE OPERATIONS ───

  Future<void> createDangerZone(DangerZone zone) async {
    await _db
        .collection(AppConstants.dangerZonesCollection)
        .doc(zone.id)
        .set(zone.toFirestore());
  }

  Future<void> deleteDangerZone(String zoneId) async {
    await _db
        .collection(AppConstants.dangerZonesCollection)
        .doc(zoneId)
        .delete();
  }

  Stream<List<DangerZone>> dangerZonesStream(String familyId) {
    return _db
        .collection(AppConstants.dangerZonesCollection)
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DangerZone.fromFirestore(doc))
            .toList());
  }

  // ─── SCHEDULE CONFIG OPERATIONS ───

  Future<void> saveScheduleConfig(ScheduleConfig config) async {
    await _db
        .collection(AppConstants.scheduleConfigCollection)
        .doc(config.id)
        .set(config.toFirestore(), SetOptions(merge: true));
  }

  Future<ScheduleConfig?> getScheduleConfig(String familyId) async {
    final query = await _db
        .collection(AppConstants.scheduleConfigCollection)
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return ScheduleConfig.fromFirestore(query.docs.first);
  }

  Stream<ScheduleConfig?> scheduleConfigStream(String familyId) {
    return _db
        .collection(AppConstants.scheduleConfigCollection)
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty
            ? ScheduleConfig.fromFirestore(snapshot.docs.first)
            : null);
  }

  // ─── FAMILY EVENT OPERATIONS ───

  Future<void> createFamilyEvent(FamilyEvent event) async {
    await _db
        .collection(AppConstants.familyEventsCollection)
        .doc(event.id)
        .set(event.toFirestore());
  }

  Future<void> deleteFamilyEvent(String eventId) async {
    await _db
        .collection(AppConstants.familyEventsCollection)
        .doc(eventId)
        .delete();
  }

  Future<void> markEventNotified(String eventId) async {
    await _db
        .collection(AppConstants.familyEventsCollection)
        .doc(eventId)
        .update({'notified': true});
  }

  Future<void> markEventReminderStage(String eventId, int minutes) async {
    await _db
        .collection(AppConstants.familyEventsCollection)
        .doc(eventId)
        .update({
      'notified': true,
      'remindedAtMinutes': FieldValue.arrayUnion([minutes]),
    });
  }

  Stream<List<FamilyEvent>> familyEventsStream(String familyId) {
    return _db
        .collection(AppConstants.familyEventsCollection)
        .where('familyId', isEqualTo: familyId)
        .orderBy('eventTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyEvent.fromFirestore(doc))
            .toList());
  }

  // ─── SECURITY EVENT OPERATIONS ───

  Future<void> logSecurityEvent(SecurityEvent event) async {
    await _db
        .collection(AppConstants.securityEventsCollection)
        .doc(event.id)
        .set(event.toFirestore());
  }

  Stream<List<SecurityEvent>> securityEventsStream(String familyId) {
    return _db
        .collection(AppConstants.securityEventsCollection)
        .where('familyId', isEqualTo: familyId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SecurityEvent.fromFirestore(doc))
            .toList());
  }

  // ─── AREA TIME (embedded in daily report) ───

  Future<void> updateDailyReportAreaTime(
    String reportId,
    Map<String, int> areaMinutes,
  ) async {
    await _db
        .collection(AppConstants.dailyReportsCollection)
        .doc(reportId)
        .update({'areaMinutes': areaMinutes});
  }

  // ─── SCREEN TIME CONFIG ───

  Future<void> saveScreenTimeConfig(ScreenTimeConfig config) async {
    await _db
        .collection(AppConstants.screenTimeCollection)
        .doc(config.id)
        .set(config.toFirestore());
  }

  Stream<ScreenTimeConfig?> screenTimeConfigStream(String childId) {
    return _db
        .collection(AppConstants.screenTimeCollection)
        .where('childId', isEqualTo: childId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty
            ? ScreenTimeConfig.fromFirestore(snap.docs.first)
            : null);
  }

  // ─── APP MANAGEMENT CONFIG ───

  Future<void> saveAppManagementConfig(AppManagementConfig config) async {
    await _db
        .collection(AppConstants.appManagementCollection)
        .doc(config.id)
        .set(config.toFirestore());
  }

  Stream<AppManagementConfig?> appManagementConfigStream(String childId) {
    return _db
        .collection(AppConstants.appManagementCollection)
        .where('childId', isEqualTo: childId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty
            ? AppManagementConfig.fromFirestore(snap.docs.first)
            : null);
  }

  // ─── CONTENT FILTER CONFIG ───

  Future<void> saveContentFilterConfig(ContentFilterConfig config) async {
    await _db
        .collection(AppConstants.contentFilterCollection)
        .doc(config.id)
        .set(config.toFirestore());
  }

  Stream<ContentFilterConfig?> contentFilterConfigStream(String childId) {
    return _db
        .collection(AppConstants.contentFilterCollection)
        .where('childId', isEqualTo: childId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty
            ? ContentFilterConfig.fromFirestore(snap.docs.first)
            : null);
  }

  // ─── FINANCIAL TRANSACTIONS ───

  Future<void> createTransaction(FinancialTransaction transaction) async {
    await _db
        .collection(AppConstants.transactionsCollection)
        .doc(transaction.id)
        .set(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _db
        .collection(AppConstants.transactionsCollection)
        .doc(transactionId)
        .delete();
  }

  Stream<List<FinancialTransaction>> transactionsStream(
    String familyId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    Query query = _db
        .collection(AppConstants.transactionsCollection)
        .where('familyId', isEqualTo: familyId)
        .orderBy('date', descending: true);

    if (fromDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }
    if (toDate != null) {
      query = query.where('date',
          isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => FinancialTransaction.fromFirestore(doc))
        .toList());
  }
}
