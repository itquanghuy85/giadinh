import 'package:cloud_firestore/cloud_firestore.dart';

class LocationData {
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double batteryLevel;
  final DateTime timestamp;

  LocationData({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.batteryLevel = 100,
    required this.timestamp,
  });

  factory LocationData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationData(
      userId: data['userId'] ?? doc.id,
      latitude: (data['lat'] ?? 0).toDouble(),
      longitude: (data['lng'] ?? 0).toDouble(),
      accuracy: data['accuracy']?.toDouble(),
      speed: data['speed']?.toDouble(),
      batteryLevel: (data['batteryLevel'] ?? 100).toDouble(),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory LocationData.fromMap(Map<String, dynamic> data) {
    return LocationData(
      userId: data['userId'] ?? '',
      latitude: (data['lat'] ?? 0).toDouble(),
      longitude: (data['lng'] ?? 0).toDouble(),
      accuracy: data['accuracy']?.toDouble(),
      speed: data['speed']?.toDouble(),
      batteryLevel: (data['batteryLevel'] ?? 100).toDouble(),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'lat': latitude,
      'lng': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'batteryLevel': batteryLevel,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
