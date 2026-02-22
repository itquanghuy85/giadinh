import 'package:cloud_firestore/cloud_firestore.dart';

class DangerZone {
  final String id;
  final String familyId;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String createdBy;
  final DateTime createdAt;

  DangerZone({
    required this.id,
    required this.familyId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.createdBy,
    required this.createdAt,
  });

  factory DangerZone.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DangerZone(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      name: data['name'] ?? '',
      latitude: (data['lat'] ?? 0).toDouble(),
      longitude: (data['lng'] ?? 0).toDouble(),
      radius: (data['radius'] ?? 200).toDouble(),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'name': name,
      'lat': latitude,
      'lng': longitude,
      'radius': radius,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
