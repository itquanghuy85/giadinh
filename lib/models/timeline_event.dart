import 'package:cloud_firestore/cloud_firestore.dart';

enum TimelineEventType { stop, move, arrival, departure }

class TimelineEvent {
  final String id;
  final String userId;
  final String date; // yyyy-MM-dd
  final TimelineEventType type;
  final String? placeName;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;

  TimelineEvent({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    this.placeName,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
  });

  factory TimelineEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimelineEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      type: _parseType(data['type']),
      placeName: data['placeName'],
      latitude: (data['lat'] ?? 0).toDouble(),
      longitude: (data['lng'] ?? 0).toDouble(),
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      durationMinutes: data['durationMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date,
      'type': type.name,
      'placeName': placeName,
      'lat': latitude,
      'lng': longitude,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationMinutes': durationMinutes,
    };
  }

  static TimelineEventType _parseType(String? type) {
    switch (type) {
      case 'stop':
        return TimelineEventType.stop;
      case 'move':
        return TimelineEventType.move;
      case 'arrival':
        return TimelineEventType.arrival;
      case 'departure':
        return TimelineEventType.departure;
      default:
        return TimelineEventType.stop;
    }
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return '${hours}h ${mins}m';
  }
}
