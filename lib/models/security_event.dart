import 'package:cloud_firestore/cloud_firestore.dart';

enum SecurityEventType {
  gpsDisabled,
  gpsEnabled,
  permissionRevoked,
  simChanged,
  connectionLost,
  connectionRestored,
  nightMovement,
}

class SecurityEvent {
  final String id;
  final String userId;
  final String familyId;
  final SecurityEventType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SecurityEvent({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory SecurityEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SecurityEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      familyId: data['familyId'] ?? '',
      type: _parseType(data['type']),
      description: data['description'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'familyId': familyId,
      'type': type.name,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  static SecurityEventType _parseType(String? type) {
    switch (type) {
      case 'gpsDisabled':
        return SecurityEventType.gpsDisabled;
      case 'gpsEnabled':
        return SecurityEventType.gpsEnabled;
      case 'permissionRevoked':
        return SecurityEventType.permissionRevoked;
      case 'simChanged':
        return SecurityEventType.simChanged;
      case 'connectionLost':
        return SecurityEventType.connectionLost;
      case 'connectionRestored':
        return SecurityEventType.connectionRestored;
      case 'nightMovement':
        return SecurityEventType.nightMovement;
      default:
        return SecurityEventType.gpsDisabled;
    }
  }
}
