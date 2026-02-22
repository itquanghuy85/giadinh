import 'package:cloud_firestore/cloud_firestore.dart';

class SosAlert {
  final String id;
  final String childId;
  final String childName;
  final String familyId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isResolved;

  SosAlert({
    required this.id,
    required this.childId,
    required this.childName,
    required this.familyId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isResolved = false,
  });

  factory SosAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SosAlert(
      id: doc.id,
      childId: data['childId'] ?? '',
      childName: data['childName'] ?? '',
      familyId: data['familyId'] ?? '',
      latitude: (data['lat'] ?? 0).toDouble(),
      longitude: (data['lng'] ?? 0).toDouble(),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isResolved: data['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'childName': childName,
      'familyId': familyId,
      'lat': latitude,
      'lng': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'isResolved': isResolved,
    };
  }
}
