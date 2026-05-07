import 'package:cloud_firestore/cloud_firestore.dart';

/// Seed dữ liệu mẫu cho lần đăng nhập đầu tiên.
/// Gọi sau khi user đăng nhập thành công và familyId đã được tạo.
class SeedService {
  SeedService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Trả về true nếu seed thành công, false nếu đã seed rồi.
  Future<bool> seedIfNeeded(String uid, String familyId) async {
    try {
      final userRef = _db.collection('users').doc(uid);
      final userDoc = await userRef.get();
      final data = userDoc.data() ?? {};

      if (data['isSeeded'] == true) {
        return false; // Đã seed rồi, bỏ qua
      }

      await _seedAll(uid, familyId);

      await userRef.set({'isSeeded': true}, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _seedAll(String uid, String familyId) async {
    final now = DateTime.now();
    final bootstrapBatch = _db.batch();

    // ── 0. Bootstrap family/member trước để vượt qua security rules ─────
    bootstrapBatch.set(
      _db.collection('families').doc(familyId),
      {
        'name': 'Gia đình',
        'ownerUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    bootstrapBatch.set(
      _db.collection('families').doc(familyId).collection('members').doc(uid),
      {
        'uid': uid,
        'name': 'Tôi',
        'role': 'admin',
        'balance': 18500000,
      },
      SetOptions(merge: true),
    );
    await bootstrapBatch.commit();

    final batch = _db.batch();

    // ── 1. Tạo 3 ví mặc định ──────────────────────────────────────────────
    final walletRef = _db.collection('users').doc(uid).collection('wallets');
    final walletCash = walletRef.doc();
    final walletBank = walletRef.doc();
    final walletMomo = walletRef.doc();

    batch.set(walletCash, {
      'name': 'Tiền mặt',
      'balance': 3000000,
      'colorHex': 'FF534AB7',
      'ownerUid': uid,
    });
    batch.set(walletBank, {
      'name': 'Ngân hàng',
      'balance': 15000000,
      'colorHex': 'FF1D9E75',
      'ownerUid': uid,
    });
    batch.set(walletMomo, {
      'name': 'Momo',
      'balance': 500000,
      'colorHex': 'FF378ADD',
      'ownerUid': uid,
    });

    // ── 2. Tạo 10 giao dịch mẫu trong tháng này ──────────────────────────
    final txRef = _db.collection('users').doc(uid).collection('transactions');
    final monthStart = DateTime(now.year, now.month, 1);

    final txList = [
      _tx(uid, walletCash.id, 85000, 'expense', 'Ăn uống', 'Ăn sáng gia đình', monthStart.add(const Duration(days: 0, hours: 7))),
      _tx(uid, walletCash.id, 50000, 'expense', 'Xăng xe', 'Đổ xăng', monthStart.add(const Duration(days: 1, hours: 8))),
      _tx(uid, walletCash.id, 320000, 'expense', 'Đi chợ', 'Chợ tuần', monthStart.add(const Duration(days: 2, hours: 9))),
      _tx(uid, walletBank.id, 450000, 'expense', 'Điện nước', 'Hóa đơn tháng', monthStart.add(const Duration(days: 3, hours: 10))),
      _tx(uid, walletBank.id, 200000, 'expense', 'Mua sắm', 'Đồ dùng nhà', monthStart.add(const Duration(days: 4, hours: 14))),
      _tx(uid, walletBank.id, 18000000, 'income', 'Lương', 'Lương tháng', monthStart.add(const Duration(days: 5, hours: 8))),
      _tx(uid, walletBank.id, 1200000, 'expense', 'Học phí', 'Học phí tháng', monthStart.add(const Duration(days: 6, hours: 9))),
      _tx(uid, walletCash.id, 120000, 'expense', 'Ăn uống', 'Ăn tối ngoài', monthStart.add(const Duration(days: 7, hours: 19))),
      _tx(uid, walletCash.id, 60000, 'expense', 'Xăng xe', 'Đổ xăng', monthStart.add(const Duration(days: 8, hours: 8))),
      _tx(uid, walletBank.id, 500000, 'income', 'Thưởng', 'Thưởng công việc', monthStart.add(const Duration(days: 9, hours: 10))),
    ];

    for (final tx in txList) {
      batch.set(txRef.doc(), tx);
    }

    // ── 3. Tạo 2 sự kiện lịch ────────────────────────────────────────────
    final eventRef = _db.collection('families').doc(familyId).collection('events');

    final today = DateTime(now.year, now.month, now.day);
    batch.set(eventRef.doc(), {
      'title': 'Đưa bé đi học',
      'assignee': 'Ba',
      'startAt': Timestamp.fromDate(today.add(const Duration(hours: 7, minutes: 30))),
      'repeat': 'daily',
      'colorHex': 'FF534AB7',
      'familyId': familyId,
      'createdBy': uid,
    });
    batch.set(eventRef.doc(), {
      'title': 'Đón bé về',
      'assignee': 'Mẹ',
      'startAt': Timestamp.fromDate(today.add(const Duration(hours: 11, minutes: 30))),
      'repeat': 'daily',
      'colorHex': 'FF1D9E75',
      'familyId': familyId,
      'createdBy': uid,
    });

    // ── 4. Tạo quỹ du lịch ───────────────────────────────────────────────
    batch.set(_db.collection('families').doc(familyId).collection('funds').doc(), {
      'name': 'Du lịch hè 2026',
      'currentAmount': 13600000,
      'targetAmount': 20000000,
      'familyId': familyId,
      'createdBy': uid,
    });

    // ── 5. Tạo công nợ ───────────────────────────────────────────────────
    batch.set(_db.collection('families').doc(familyId).collection('debts').doc(), {
      'fromName': 'Anh Tuấn',
      'toName': 'Tôi',
      'amount': 2500000,
      'dueDate': Timestamp.fromDate(DateTime(2026, 5, 20)),
      'status': 'pending',
      'familyId': familyId,
      'createdBy': uid,
    });

    await batch.commit();
  }

  Map<String, dynamic> _tx(
    String uid,
    String walletId,
    double amount,
    String type,
    String category,
    String note,
    DateTime createdAt,
  ) {
    return {
      'walletId': walletId,
      'ownerUid': uid,
      'uid': uid,
      'amount': amount,
      'type': type,
      'category': category,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': uid,
    };
  }
}
