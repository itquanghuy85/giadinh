import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/shared/models/transaction.dart';
import 'package:family_finance/shared/models/wallet.dart';

class HomeStatsData {
  const HomeStatsData({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.weeklySpending,
  });

  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final List<double> weeklySpending;
}

class MonthlyReportData {
  const MonthlyReportData({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.byCategory,
  });

  final List<TransactionModel> transactions;
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> byCategory;

  double get balance => totalIncome - totalExpense;
}

class FinanceRepository {
  FinanceRepository({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;

  Stream<List<WalletModel>> streamWalletsByOwners(List<String> ownerIds) {
    if (ownerIds.isEmpty) {
      return Stream.value(const []);
    }

    final controller = StreamController<List<WalletModel>>();
    final dataByOwner = <String, List<WalletModel>>{};
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emit() {
      final merged = dataByOwner.values.expand((e) => e).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      controller.add(merged);
    }

    for (final ownerId in ownerIds) {
      final sub = _db
          .collection('users')
          .doc(ownerId)
          .collection('wallets')
          .orderBy('name')
          .snapshots()
          .listen(
        (snapshot) {
          dataByOwner[ownerId] =
              snapshot.docs.map((doc) => WalletModel.fromMap(doc.id, doc.data())).toList();
          emit();
        },
        onError: (_) {
          dataByOwner[ownerId] = const [];
          emit();
        },
      );
      subs.add(sub);
    }

    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  Stream<HomeStatsData> streamHomeStats(List<String> ownerIds) {
    if (ownerIds.isEmpty) {
      return Stream.value(
        const HomeStatsData(
          totalBalance: 0,
          monthlyIncome: 0,
          monthlyExpense: 0,
          weeklySpending: [0, 0, 0, 0, 0, 0, 0],
        ),
      );
    }

    final controller = StreamController<HomeStatsData>();
    final walletData = <String, List<WalletModel>>{};
    final txData = <String, List<TransactionModel>>{};
    final subs = <StreamSubscription<dynamic>>[];

    void emit() {
      final wallets = walletData.values.expand((e) => e);
      final txs = txData.values.expand((e) => e).toList();

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);
      final nextMonth = DateTime(now.year, now.month + 1);

      double income = 0;
      double expense = 0;
      final dayBuckets = List<double>.filled(7, 0);
      final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final weekEnd = DateTime(now.year, now.month, now.day);

      for (final tx in txs) {
        if (!tx.createdAt.isBefore(monthStart) && tx.createdAt.isBefore(nextMonth)) {
          if (tx.type == TransactionType.income) {
            income += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            expense += tx.amount;
          }
        }

        if (tx.type == TransactionType.expense) {
          final day = DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);
          if (!day.isBefore(weekStart) && !day.isAfter(weekEnd)) {
            final index = day.difference(weekStart).inDays;
            if (index >= 0 && index < 7) {
              dayBuckets[index] += tx.amount;
            }
          }
        }
      }

      controller.add(
        HomeStatsData(
          totalBalance: wallets.fold<double>(0, (sum, w) => sum + w.balance),
          monthlyIncome: income,
          monthlyExpense: expense,
          weeklySpending: dayBuckets,
        ),
      );
    }

    for (final ownerId in ownerIds) {
      final walletSub = _db
          .collection('users')
          .doc(ownerId)
          .collection('wallets')
          .orderBy('name')
          .snapshots()
          .listen(
        (snapshot) {
          walletData[ownerId] =
              snapshot.docs.map((doc) => WalletModel.fromMap(doc.id, doc.data())).toList();
          emit();
        },
        onError: (_) {
          walletData[ownerId] = const [];
          emit();
        },
      );

      final txSub = _db
          .collection('users')
          .doc(ownerId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots()
          .listen(
        (snapshot) {
          txData[ownerId] = snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.id, {...doc.data(), 'ownerUid': ownerId}))
              .toList();
          emit();
        },
        onError: (_) {
          txData[ownerId] = const [];
          emit();
        },
      );

      subs.add(walletSub);
      subs.add(txSub);
    }

    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  Stream<MonthlyReportData> streamMonthlyReport({
    required String ownerId,
    required DateTime month,
  }) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _db
        .collection('users')
        .doc(ownerId)
        .collection('transactions')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final txs = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, {...doc.data(), 'ownerUid': ownerId}))
          .toList();

      double totalIn = 0;
      double totalOut = 0;
      final byCategory = <String, double>{};

      for (final tx in txs) {
        if (tx.type == TransactionType.income) {
          totalIn += tx.amount;
        }
        if (tx.type == TransactionType.expense) {
          totalOut += tx.amount;
          byCategory[tx.category] = (byCategory[tx.category] ?? 0) + tx.amount;
        }
      }

      return MonthlyReportData(
        transactions: txs,
        totalIncome: totalIn,
        totalExpense: totalOut,
        byCategory: byCategory,
      );
    });
  }
}
