import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense, transfer }

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.ownerUid,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String ownerUid;
  final String walletId;
  final double amount;
  final TransactionType type;
  final String category;
  final String note;
  final DateTime createdAt;
  final String createdBy;

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      ownerUid: map['ownerUid'] as String? ?? map['uid'] as String? ?? map['createdBy'] as String? ?? '',
      walletId: map['walletId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: _typeFromString(map['type'] as String? ?? 'expense'),
      category: map['category'] as String? ?? 'Khác',
      note: map['note'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'walletId': walletId,
        'ownerUid': ownerUid,
        'uid': ownerUid,
        'amount': amount,
        'type': type.name,
        'category': category,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };

  static TransactionType _typeFromString(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }
}
