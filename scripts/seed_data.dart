import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

Future<void> main() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await seedDataIfNeeded();
    print('✅ Seed dữ liệu hoàn tất!');
    exit(0);
  } catch (e) {
    print('❌ Lỗi seed dữ liệu: $e');
    exit(1);
  }
}

Future<void> seedDataIfNeeded() async {
  final db = FirebaseFirestore.instance;

  const familyId = 'family_main';
  const baUid = 'seed_ba_admin';
  const meUid = 'seed_me_manager';
  const conUid = 'seed_con_child';

  final seedRef = db.collection('families').doc(familyId).collection('meta').doc('seed');
  final seeded = await seedRef.get();
  if (seeded.exists && seeded.data()?['done'] == true) {
    return;
  }

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);

  final batch = db.batch();

  batch.set(
    db.collection('users').doc(baUid),
    {
      'email': 'ba@family.finance',
      'displayName': 'Ba',
      'role': 'admin',
      'familyId': familyId,
    },
    SetOptions(merge: true),
  );

  batch.set(
    db.collection('users').doc(meUid),
    {
      'email': 'me@family.finance',
      'displayName': 'Mẹ',
      'role': 'manager',
      'familyId': familyId,
    },
    SetOptions(merge: true),
  );

  batch.set(
    db.collection('users').doc(conUid),
    {
      'email': 'con@family.finance',
      'displayName': 'Con',
      'role': 'child',
      'familyId': familyId,
    },
    SetOptions(merge: true),
  );

  final members = {
    baUid: {'name': 'Ba', 'role': 'admin', 'balance': 18500000},
    meUid: {'name': 'Mẹ', 'role': 'manager', 'balance': 15000000},
    conUid: {'name': 'Con', 'role': 'child', 'balance': 800000},
  };

  members.forEach((uid, data) {
    batch.set(db.collection('families').doc(familyId).collection('members').doc(uid), data, SetOptions(merge: true));
  });

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

  for (int i = 0; i < 10; i++) {
    final txDate = monthStart.add(Duration(days: i * 2, hours: 8 + i));
    final isIncome = i % 4 == 0;

    final txRef = db.collection('users').doc(baUid).collection('transactions').doc('seed_tx_$i');
    batch.set(
      txRef,
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

  batch.set(
    seedRef,
    {
      'done': true,
      'seededAt': FieldValue.serverTimestamp(),
      'familyId': familyId,
    },
    SetOptions(merge: true),
  );

  await batch.commit();
}
