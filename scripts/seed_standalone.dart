import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

// Điều chỉnh import này cho phù hợp với cấu trúc dự án
// Giả sử firebase_options.dart có thể import từ lib/
import 'package:family_finance/firebase_options.dart';

void main() async {
  try {
    print('🔄 Khởi động Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase khởi động xong');

    print('🔄 Seed dữ liệu...');
    await seedData();
    print('✅ Seed dữ liệu hoàn tất!');
    exit(0);
  } catch (e, st) {
    print('❌ Lỗi: $e');
    print(st);
    exit(1);
  }
}

Future<void> seedData() async {
  final db = FirebaseFirestore.instance;
  const familyId = 'family_main';
  const baUid = 'seed_ba_admin';
  const meUid = 'seed_me_manager';
  const conUid = 'seed_con_child';

  // Kiểm tra đã seed chưa
  final seedRef = db.collection('families').doc(familyId).collection('meta').doc('seed');
  final seeded = await seedRef.get();
  if (seeded.exists && seeded['done'] == true) {
    print('⏭️  Dữ liệu đã seed rồi, bỏ qua');
    return;
  }

  final batch = db.batch();
  final now = DateTime.now();

  // Tạo users
  batch.set(db.collection('users').doc(baUid), {
    'email': 'ba@family.finance',
    'displayName': 'Ba',
    'role': 'fatherAdmin',
    'familyId': familyId,
  }, SetOptions(merge: true));

  batch.set(db.collection('users').doc(meUid), {
    'email': 'me@family.finance',
    'displayName': 'Mẹ',
    'role': 'motherManager',
    'familyId': familyId,
  }, SetOptions(merge: true));

  batch.set(db.collection('users').doc(conUid), {
    'email': 'con@family.finance',
    'displayName': 'Con',
    'role': 'childLimited',
    'familyId': familyId,
  }, SetOptions(merge: true));

  // Tạo members
  final members = {
    baUid: {'name': 'Ba', 'role': 'fatherAdmin', 'balance': 18500000},
    meUid: {'name': 'Mẹ', 'role': 'motherManager', 'balance': 15000000},
    conUid: {'name': 'Con', 'role': 'childLimited', 'balance': 800000},
  };

  members.forEach((uid, data) {
    batch.set(
      db.collection('families').doc(familyId).collection('members').doc(uid),
      data,
      SetOptions(merge: true),
    );
  });

  // Tạo wallets
  final wallets = [
    {'id': 'wallet_cash', 'name': 'Tiền mặt', 'balance': 3000000, 'colorHex': 'FF534AB7'},
    {'id': 'wallet_bank', 'name': 'Ngân hàng', 'balance': 15000000, 'colorHex': 'FF1D9E75'},
    {'id': 'wallet_momo', 'name': 'Momo', 'balance': 500000, 'colorHex': 'FF378ADD'},
  ];

  for (final w in wallets) {
    batch.set(
      db.collection('users').doc(baUid).collection('wallets').doc(w['id'] as String),
      {
        'name': w['name'],
        'balance': w['balance'],
        'colorHex': w['colorHex'],
        'ownerUid': baUid,
      },
      SetOptions(merge: true),
    );
  }

  // Tạo transactions
  final monthStart = DateTime(now.year, now.month, 1);
  for (int i = 0; i < 10; i++) {
    final txDate = monthStart.add(Duration(days: i * 2, hours: 8 + i));
    final isIncome = i % 4 == 0;

    batch.set(
      db.collection('users').doc(baUid).collection('transactions').doc('seed_tx_$i'),
      {
        'walletId': i % 2 == 0 ? 'wallet_bank' : 'wallet_cash',
        'ownerUid': baUid,
        'uid': baUid,
        'amount': isIncome ? 1800000 + i * 100000 : 120000 + i * 25000,
        'type': isIncome ? 'income' : 'expense',
        'category': isIncome ? 'Lương' : 'Ăn uống',
        'note': isIncome ? 'Thu nhập tháng' : 'Chi tiêu sinh hoạt',
        'createdAt': Timestamp.fromDate(txDate),
        'createdBy': baUid,
      },
      SetOptions(merge: true),
    );
  }

  // Tạo events
  final event1Time = DateTime(now.year, now.month, now.day, 7, 30);
  final event2Time = DateTime(now.year, now.month, now.day, 11, 30);

  batch.set(
    db.collection('families').doc(familyId).collection('events').doc('seed_event_morning'),
    {
      'title': 'Đưa bé đi học',
      'assignee': 'Ba',
      'startAt': Timestamp.fromDate(event1Time),
      'repeat': 'ngày',
      'colorHex': 'FF534AB7',
      'familyId': familyId,
    },
    SetOptions(merge: true),
  );

  batch.set(
    db.collection('families').doc(familyId).collection('events').doc('seed_event_noon'),
    {
      'title': 'Đón bé về',
      'assignee': 'Mẹ',
      'startAt': Timestamp.fromDate(event2Time),
      'repeat': 'ngày',
      'colorHex': 'FF1D9E75',
      'familyId': familyId,
    },
    SetOptions(merge: true),
  );

  // Tạo funds
  batch.set(
    db.collection('families').doc(familyId).collection('funds').doc('seed_fund_travel'),
    {
      'name': 'Quỹ du lịch',
      'currentAmount': 13600000,
      'targetAmount': 20000000,
      'familyId': familyId,
    },
    SetOptions(merge: true),
  );

  // Tạo debts
  batch.set(
    db.collection('families').doc(familyId).collection('debts').doc('seed_debt_1'),
    {
      'fromName': 'Anh Minh',
      'toName': 'Ba',
      'amount': 2500000,
      'dueDate': Timestamp.fromDate(now.add(const Duration(days: 12))),
      'status': 'pending',
      'familyId': familyId,
    },
    SetOptions(merge: true),
  );

  // Mark as seeded
  batch.set(
    seedRef,
    {
      'done': true,
      'seededAt': FieldValue.serverTimestamp(),
      'familyId': familyId,
    },
    SetOptions(merge: true),
  );

  print('📝 Commit batch...');
  await batch.commit();
  print('✅ Batch committed');
}
