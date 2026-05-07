const admin = require('firebase-admin');

// Initialize Firebase
admin.initializeApp({
  projectId: 'giadinh-ca079',
  databaseURL: 'https://giadinh-ca079.firebaseio.com'
});

const db = admin.firestore();
const familyId = 'family_main';
const baUid = 'seed_ba_admin';
const meUid = 'seed_me_manager';
const conUid = 'seed_con_child';

async function seedData() {
  try {
    console.log('🔄 Kiểm tra seed status...');
    const seedRef = db.collection('families').doc(familyId).collection('meta').doc('seed');
    const seeded = await seedRef.get();
    
    if (seeded.exists && seeded.data()?.done) {
      console.log('⏭️  Dữ liệu đã seed rồi, bỏ qua');
      process.exit(0);
    }

    console.log('📝 Bắt đầu seed dữ liệu...');
    const batch = db.batch();
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    // Create users
    console.log('👤 Tạo users...');
    batch.set(db.collection('users').doc(baUid), {
      email: 'ba@family.finance',
      displayName: 'Ba',
      role: 'fatherAdmin',
      familyId: familyId,
    }, { merge: true });

    batch.set(db.collection('users').doc(meUid), {
      email: 'me@family.finance',
      displayName: 'Mẹ',
      role: 'motherManager',
      familyId: familyId,
    }, { merge: true });

    batch.set(db.collection('users').doc(conUid), {
      email: 'con@family.finance',
      displayName: 'Con',
      role: 'childLimited',
      familyId: familyId,
    }, { merge: true });

    // Create members
    console.log('👨‍👩‍👧 Tạo family members...');
    const members = {
      [baUid]: { name: 'Ba', role: 'fatherAdmin', balance: 18500000 },
      [meUid]: { name: 'Mẹ', role: 'motherManager', balance: 15000000 },
      [conUid]: { name: 'Con', role: 'childLimited', balance: 800000 },
    };

    for (const [uid, data] of Object.entries(members)) {
      batch.set(
        db.collection('families').doc(familyId).collection('members').doc(uid),
        data,
        { merge: true }
      );
    }

    // Create wallets
    console.log('💰 Tạo wallets...');
    const wallets = [
      { id: 'wallet_cash', name: 'Tiền mặt', balance: 3000000, colorHex: 'FF534AB7' },
      { id: 'wallet_bank', name: 'Ngân hàng', balance: 15000000, colorHex: 'FF1D9E75' },
      { id: 'wallet_momo', name: 'Momo', balance: 500000, colorHex: 'FF378ADD' },
    ];

    for (const w of wallets) {
      batch.set(
        db.collection('users').doc(baUid).collection('wallets').doc(w.id),
        {
          name: w.name,
          balance: w.balance,
          colorHex: w.colorHex,
          ownerUid: baUid,
        },
        { merge: true }
      );
    }

    // Create transactions
    console.log('💳 Tạo transactions...');
    for (let i = 0; i < 10; i++) {
      const txDate = new Date(monthStart);
      txDate.setDate(txDate.getDate() + i * 2);
      txDate.setHours(8 + i);
      
      const isIncome = i % 4 === 0;
      
      batch.set(
        db.collection('users').doc(baUid).collection('transactions').doc(`seed_tx_${i}`),
        {
          walletId: i % 2 === 0 ? 'wallet_bank' : 'wallet_cash',
          ownerUid: baUid,
          uid: baUid,
          amount: isIncome ? 1800000 + i * 100000 : 120000 + i * 25000,
          type: isIncome ? 'income' : 'expense',
          category: isIncome ? 'Lương' : 'Ăn uống',
          note: isIncome ? 'Thu nhập tháng' : 'Chi tiêu sinh hoạt',
          createdAt: admin.firestore.Timestamp.fromDate(txDate),
          createdBy: baUid,
        },
        { merge: true }
      );
    }

    // Create events
    console.log('📅 Tạo events...');
    const event1Time = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 7, 30);
    const event2Time = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 11, 30);

    batch.set(
      db.collection('families').doc(familyId).collection('events').doc('seed_event_morning'),
      {
        title: 'Đưa bé đi học',
        assignee: 'Ba',
        startAt: admin.firestore.Timestamp.fromDate(event1Time),
        repeat: 'ngày',
        colorHex: 'FF534AB7',
        familyId: familyId,
      },
      { merge: true }
    );

    batch.set(
      db.collection('families').doc(familyId).collection('events').doc('seed_event_noon'),
      {
        title: 'Đón bé về',
        assignee: 'Mẹ',
        startAt: admin.firestore.Timestamp.fromDate(event2Time),
        repeat: 'ngày',
        colorHex: 'FF1D9E75',
        familyId: familyId,
      },
      { merge: true }
    );

    // Create funds
    console.log('🏦 Tạo funds...');
    batch.set(
      db.collection('families').doc(familyId).collection('funds').doc('seed_fund_travel'),
      {
        name: 'Quỹ du lịch',
        currentAmount: 13600000,
        targetAmount: 20000000,
        familyId: familyId,
      },
      { merge: true }
    );

    // Create debts
    console.log('💸 Tạo debts...');
    const dueDate = new Date(now);
    dueDate.setDate(dueDate.getDate() + 12);

    batch.set(
      db.collection('families').doc(familyId).collection('debts').doc('seed_debt_1'),
      {
        fromName: 'Anh Minh',
        toName: 'Ba',
        amount: 2500000,
        dueDate: admin.firestore.Timestamp.fromDate(dueDate),
        status: 'pending',
        familyId: familyId,
      },
      { merge: true }
    );

    // Mark as seeded
    batch.set(
      seedRef,
      {
        done: true,
        seededAt: admin.firestore.FieldValue.serverTimestamp(),
        familyId: familyId,
      },
      { merge: true }
    );

    console.log('📤 Commit batch...');
    await batch.commit();
    console.log('✅ Seed dữ liệu hoàn tất!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Lỗi:', error);
    process.exit(1);
  }
}

seedData();
