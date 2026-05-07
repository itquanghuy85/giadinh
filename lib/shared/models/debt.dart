import 'package:cloud_firestore/cloud_firestore.dart';

/// direction: 'lend' = cho vay (cần thu), 'borrow' = đi vay (cần trả)
/// status: 'pending' | 'paid' | 'overdue'
class DebtModel {
  const DebtModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.dueDate,
    required this.direction,
    required this.status,
    required this.note,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String personName;
  final double amount;
  final DateTime dueDate;
  final String direction; // 'lend' | 'borrow'
  final String status;    // 'pending' | 'paid'
  final String note;
  final String createdBy;
  final DateTime createdAt;

  bool get isLend => direction == 'lend';
  bool get isPaid => status == 'paid';
  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());

  // Kept for backward-compat with old seed data
  String get fromName => isLend ? createdBy : personName;
  String get toName   => isLend ? personName : createdBy;

  factory DebtModel.fromMap(String id, Map<String, dynamic> map) {
    return DebtModel(
      id: id,
      personName: (map['personName'] as String?)
              ?? (map['toName'] as String?)
              ?? (map['fromName'] as String?)
              ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      direction: map['direction'] as String? ?? 'lend',
      status: map['status'] as String? ?? 'pending',
      note: map['note'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'personName': personName,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'direction': direction,
        'status': status,
        'note': note,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  DebtModel copyWith({
    String? personName,
    double? amount,
    DateTime? dueDate,
    String? direction,
    String? status,
    String? note,
  }) {
    return DebtModel(
      id: id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      note: note ?? this.note,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
