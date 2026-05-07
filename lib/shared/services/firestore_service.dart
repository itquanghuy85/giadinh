import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:family_finance/shared/models/debt.dart';
import 'package:family_finance/shared/models/family_event.dart';
import 'package:family_finance/shared/models/family_member.dart';
import 'package:family_finance/shared/models/fund.dart';
import 'package:family_finance/shared/models/transaction.dart';
import 'package:family_finance/shared/models/wallet.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Expose raw db for batch operations from UI layer
  FirebaseFirestore get db => _db;

  /// Wrap stream to handle Firestore errors silently (return empty list instead of error)
  Stream<T> _safeStream<T>(Stream<T> stream, {required String context}) {
    return stream.handleError(
      (error, stackTrace) {
        developer.log('[Firestore] $context error: $error', stackTrace: stackTrace);
        // Don't rethrow - just let stream close gracefully
      },
      test: (e) => true, // Handle all errors
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: (sink) {
        developer.log('[Firestore] $context timeout after 15s');
        sink.close(); // Close stream on timeout
      },
    );
  }

  Future<List<WalletModel>> getWallets(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).collection('wallets').orderBy('name').get();
    return snapshot.docs.map((doc) => WalletModel.fromMap(doc.id, doc.data())).toList();
  }

  Stream<List<WalletModel>> streamWallets(String uid) {
    return _safeStream(
      _db
          .collection('users')
          .doc(uid)
          .collection('wallets')
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => WalletModel.fromMap(doc.id, doc.data())).toList()),
      context: 'streamWallets($uid)',
    ).handleError((_) => const <WalletModel>[], test: (_) => true);
  }

  Future<({List<TransactionModel> data, DocumentSnapshot<Map<String, dynamic>>? lastDoc})> getTransactionsPaginated(
    String uid, {
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final data = snapshot.docs.map((doc) => TransactionModel.fromMap(doc.id, doc.data())).toList();

    return (
      data: data,
      lastDoc: snapshot.docs.isEmpty ? null : snapshot.docs.last,
    );
  }

  Future<void> addTransaction(String uid, TransactionModel transaction) {
    return _db.collection('users').doc(uid).collection('transactions').add(transaction.toMap());
  }

  Future<void> deleteTransaction(String uid, String transactionId) {
    return _db.collection('users').doc(uid).collection('transactions').doc(transactionId).delete();
  }

  Future<void> updateTransaction(String uid, TransactionModel updated) {
    return _db.collection('users').doc(uid).collection('transactions').doc(updated.id).update(updated.toMap());
  }

  /// Batch: Chuyển tiền giữa 2 ví cùng user
  Future<void> transferBetweenWallets({
    required String uid,
    required String sourceWalletId,
    required String destWalletId,
    required double amount,
    required String note,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now();

    final sourceRef = _db.collection('users').doc(uid).collection('wallets').doc(sourceWalletId);
    final destRef   = _db.collection('users').doc(uid).collection('wallets').doc(destWalletId);
    final txColRef  = _db.collection('users').doc(uid).collection('transactions');

    batch.update(sourceRef, {'balance': FieldValue.increment(-amount)});
    batch.update(destRef,   {'balance': FieldValue.increment(amount)});

    final outDoc = txColRef.doc();
    batch.set(outDoc, {
      'walletId': sourceWalletId,
      'destWalletId': destWalletId,
      'ownerUid': uid,
      'uid': uid,
      'amount': amount,
      'type': 'transfer',
      'category': 'Chuyển khoản',
      'note': note.isEmpty ? 'Chuyển từ ví' : note,
      'createdAt': Timestamp.fromDate(now),
      'createdBy': uid,
    });

    final inDoc = txColRef.doc();
    batch.set(inDoc, {
      'walletId': destWalletId,
      'sourceWalletId': sourceWalletId,
      'ownerUid': uid,
      'uid': uid,
      'amount': amount,
      'type': 'income',
      'category': 'Nhận chuyển khoản',
      'note': note.isEmpty ? 'Nhận từ ví' : note,
      'createdAt': Timestamp.fromDate(now),
      'createdBy': uid,
    });

    await batch.commit();
  }

  Stream<List<TransactionModel>> streamWalletTransactions(
    String uid,
    String walletId, {
    int? month,
    int? year,
    String? type, // 'income' | 'expense' | 'transfer' | null = all
    String? category,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('walletId', isEqualTo: walletId)
        .orderBy('createdAt', descending: true);

    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return _safeStream(
      query.snapshots().map((snap) {
        var list = snap.docs.map((d) => TransactionModel.fromMap(d.id, {...d.data(), 'ownerUid': uid})).toList();
        if (month != null && year != null) {
          list = list.where((t) => t.createdAt.month == month && t.createdAt.year == year).toList();
        }
        return list;
      }),
      context: 'streamWalletTransactions',
    ).handleError((_) => const <TransactionModel>[], test: (_) => true);
  }

  Stream<List<TransactionModel>> streamTransactions(
    String uid, {
    int limit = 20,
  }) {
    return _safeStream(
      _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => TransactionModel.fromMap(
                    doc.id,
                    {
                      ...doc.data(),
                      'ownerUid': uid,
                    },
                  ),
                )
                .toList(),
          ),
      context: 'streamTransactions($uid)',
    ).handleError((_) => const <TransactionModel>[], test: (_) => true);
  }

  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    final snapshot = await _db.collection('families').doc(familyId).collection('members').get();
    return snapshot.docs.map((doc) => FamilyMember.fromMap(doc.id, doc.data())).toList();
  }

  Stream<List<FamilyMember>> streamFamilyMembers(String familyId) {
    return _safeStream(
      _db
          .collection('families')
          .doc(familyId)
          .collection('members')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => FamilyMember.fromMap(doc.id, doc.data())).toList()),
      context: 'streamFamilyMembers($familyId)',
    ).handleError(
      (e) => const <FamilyMember>[],
      test: (e) => true,
    );
  }

  Future<List<DebtModel>> getDebts(String familyId) async {
    final snapshot = await _db.collection('families').doc(familyId).collection('debts').orderBy('dueDate').get();
    return snapshot.docs.map((doc) => DebtModel.fromMap(doc.id, doc.data())).toList();
  }

  Stream<List<DebtModel>> streamDebts(String familyId) {
    return _safeStream(
      _db
          .collection('families')
          .doc(familyId)
          .collection('debts')
          .orderBy('dueDate')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => DebtModel.fromMap(doc.id, doc.data())).toList()),
      context: 'streamDebts($familyId)',
    ).handleError(
      (e) => const <DebtModel>[],
      test: (e) => true,
    );
  }

  Future<void> addDebt(String familyId, DebtModel debt) {
    return _db.collection('families').doc(familyId).collection('debts').add(debt.toMap());
  }

  Future<void> updateDebt(String familyId, DebtModel debt) {
    return _db.collection('families').doc(familyId).collection('debts').doc(debt.id).update(debt.toMap());
  }

  Future<void> deleteDebt(String familyId, String debtId) {
    return _db.collection('families').doc(familyId).collection('debts').doc(debtId).delete();
  }

  /// Đánh dấu đã trả + cập nhật balance ví (batch write)
  Future<void> markDebtPaid({
    required String familyId,
    required DebtModel debt,
    required String uid,
    String? walletId,
    double? walletDelta, // dương = cộng vào ví, âm = trừ khỏi ví
  }) async {
    final batch = _db.batch();
    final debtRef = _db.collection('families').doc(familyId).collection('debts').doc(debt.id);
    batch.update(debtRef, {'status': 'paid'});

    if (walletId != null && walletDelta != null && walletDelta != 0) {
      final walletRef = _db.collection('users').doc(uid).collection('wallets').doc(walletId);
      batch.update(walletRef, {'balance': FieldValue.increment(walletDelta)});
    }
    await batch.commit();
  }

  Future<List<FundModel>> getFunds(String familyId) async {
    final snapshot = await _db.collection('families').doc(familyId).collection('funds').get();
    return snapshot.docs.map((doc) => FundModel.fromMap(doc.id, doc.data())).toList();
  }

  Stream<List<FundModel>> streamFunds(String familyId) {
    return _safeStream(
      _db
          .collection('families')
          .doc(familyId)
          .collection('funds')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => FundModel.fromMap(doc.id, doc.data())).toList()),
      context: 'streamFunds($familyId)',
    ).handleError(
      (e) => const <FundModel>[],
      test: (e) => true,
    );
  }

  Future<void> addFund(String familyId, FundModel fund) {
    return _db.collection('families').doc(familyId).collection('funds').add(fund.toMap());
  }

  Future<void> updateFund(String familyId, FundModel fund) {
    return _db.collection('families').doc(familyId).collection('funds').doc(fund.id).update(fund.toMap());
  }

  Future<void> deleteFund(String familyId, String fundId) {
    return _db.collection('families').doc(familyId).collection('funds').doc(fundId).delete();
  }

  /// Nạp tiền vào quỹ: trừ ví + cộng quỹ (batch)
  Future<void> depositToFund({
    required String familyId,
    required String fundId,
    required double amount,
    required String uid,
    required String walletId,
  }) async {
    final batch = _db.batch();
    final fundRef   = _db.collection('families').doc(familyId).collection('funds').doc(fundId);
    final walletRef = _db.collection('users').doc(uid).collection('wallets').doc(walletId);
    batch.update(fundRef,   {'currentAmount': FieldValue.increment(amount)});
    batch.update(walletRef, {'balance':       FieldValue.increment(-amount)});
    await batch.commit();
  }

  /// Rút tiền từ quỹ: trừ quỹ + cộng ví (batch)
  Future<void> withdrawFromFund({
    required String familyId,
    required String fundId,
    required double amount,
    required String uid,
    required String walletId,
  }) async {
    final batch = _db.batch();
    final fundRef   = _db.collection('families').doc(familyId).collection('funds').doc(fundId);
    final walletRef = _db.collection('users').doc(uid).collection('wallets').doc(walletId);
    batch.update(fundRef,   {'currentAmount': FieldValue.increment(-amount)});
    batch.update(walletRef, {'balance':       FieldValue.increment(amount)});
    await batch.commit();
  }

  Future<List<FamilyEvent>> getEventsByDate(String familyId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await _db
        .collection('families')
        .doc(familyId)
        .collection('events')
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('startAt')
        .get();

    return snapshot.docs.map((doc) => FamilyEvent.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> createEvent(String familyId, FamilyEvent event) {
    return _db.collection('families').doc(familyId).collection('events').add(event.toMap());
  }

  Future<void> deleteEvent(String familyId, String eventId) {
    return _db.collection('families').doc(familyId).collection('events').doc(eventId).delete();
  }

  // ── Ví chung gia đình ──────────────────────────────────────
  Stream<List<WalletModel>> streamFamilyWallets(String familyId) {
    return _safeStream(
      _db
          .collection('families')
          .doc(familyId)
          .collection('wallets')
          .orderBy('name')
          .snapshots()
          .map((s) => s.docs.map((d) => WalletModel.fromMap(d.id, d.data())).toList()),
      context: 'streamFamilyWallets',
    ).handleError((_) => const <WalletModel>[], test: (_) => true);
  }

  Future<void> addFamilyWallet({
    required String familyId,
    required String name,
    required double balance,
    required String colorHex,
    required String createdBy,
  }) {
    return _db.collection('families').doc(familyId).collection('wallets').add({
      'name': name,
      'balance': balance,
      'colorHex': colorHex,
      'ownerUid': createdBy,
      'isShared': true,
    });
  }

  // ── Thông báo realtime gia đình ────────────────────────────
  Stream<List<Map<String, dynamic>>> streamFamilyNotifications(String familyId) {
    return _safeStream(
      _db
          .collection('families')
          .doc(familyId)
          .collection('notifications')
          .orderBy('at', descending: true)
          .limit(20)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList()),
      context: 'streamFamilyNotifications',
    ).handleError((_) => const <Map<String, dynamic>>[], test: (_) => true);
  }

  Future<void> addFamilyNotification(String familyId, Map<String, dynamic> data) {
    return _db.collection('families').doc(familyId).collection('notifications').add(data);
  }

  // ── Invite codes ───────────────────────────────────────────
  Future<void> saveInviteCode({
    required String familyId,
    required String code,
    required String role,
    required String createdBy,
  }) {
    final now = DateTime.now();
    return _db.collection('families').doc(familyId).collection('invites').doc(code).set({
      'code': code,
      'role': role,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'familyId': familyId,
    });
  }

  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    // Search across all families
    final query = await _db
        .collectionGroup('invites')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final data = query.docs.first.data();
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) return null;
    return data;
  }

  Future<void> joinFamily({
    required String familyId,
    required String uid,
    required String displayName,
    required String email,
    required String role,
  }) async {
    final batch = _db.batch();
    final userRef = _db.collection('users').doc(uid);
    final memberRef = _db.collection('families').doc(familyId).collection('members').doc(uid);
    batch.update(userRef, {'familyId': familyId, 'role': role});
    batch.set(memberRef, {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'role': role,
      'joinedAt': Timestamp.now(),
    });
    await batch.commit();
  }

  Stream<List<FamilyEvent>> streamEvents(String familyId) {
    return _safeStream(
      _db
          .collection('families')
          .doc(familyId)
          .collection('events')
          .orderBy('startAt')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => FamilyEvent.fromMap(doc.id, doc.data())).toList()),
      context: 'streamEvents($familyId)',
    ).handleError(
      (e) => const <FamilyEvent>[],
      test: (e) => true,
    );
  }
}
