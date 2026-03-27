import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class FinancialTransaction {
  final String id;
  final String familyId;
  final String createdBy;
  final TransactionType type;
  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  FinancialTransaction({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
  });

  factory FinancialTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinancialTransaction(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      type: (data['type'] ?? 'expense') == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'other',
      note: data['note'],
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'createdBy': createdBy,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
