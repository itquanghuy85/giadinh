import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String name;
  final String code;
  final String createdBy;
  final List<String> members;
  final DateTime createdAt;

  Family({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    required this.members,
    required this.createdAt,
  });

  factory Family.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Family(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      createdBy: data['createdBy'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'createdBy': createdBy,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
