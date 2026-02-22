import 'package:cloud_firestore/cloud_firestore.dart';

class DailyReport {
  final String id;
  final String userId;
  final String date; // yyyy-MM-dd
  final double totalDistanceKm;
  final double maxSpeedKmh;
  final int totalMovingTimeMinutes;
  final String? mostVisitedPlace;
  final int mostVisitedCount;
  final DateTime? leftHomeTime;
  final DateTime? arrivedHomeTime;
  final int locationPointsCount;
  final DateTime createdAt;

  DailyReport({
    required this.id,
    required this.userId,
    required this.date,
    this.totalDistanceKm = 0,
    this.maxSpeedKmh = 0,
    this.totalMovingTimeMinutes = 0,
    this.mostVisitedPlace,
    this.mostVisitedCount = 0,
    this.leftHomeTime,
    this.arrivedHomeTime,
    this.locationPointsCount = 0,
    required this.createdAt,
  });

  factory DailyReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyReport(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      totalDistanceKm: (data['totalDistanceKm'] ?? 0).toDouble(),
      maxSpeedKmh: (data['maxSpeedKmh'] ?? 0).toDouble(),
      totalMovingTimeMinutes: data['totalMovingTimeMinutes'] ?? 0,
      mostVisitedPlace: data['mostVisitedPlace'],
      mostVisitedCount: data['mostVisitedCount'] ?? 0,
      leftHomeTime: data['leftHomeTime'] != null
          ? (data['leftHomeTime'] as Timestamp).toDate()
          : null,
      arrivedHomeTime: data['arrivedHomeTime'] != null
          ? (data['arrivedHomeTime'] as Timestamp).toDate()
          : null,
      locationPointsCount: data['locationPointsCount'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date,
      'totalDistanceKm': totalDistanceKm,
      'maxSpeedKmh': maxSpeedKmh,
      'totalMovingTimeMinutes': totalMovingTimeMinutes,
      'mostVisitedPlace': mostVisitedPlace,
      'mostVisitedCount': mostVisitedCount,
      'leftHomeTime':
          leftHomeTime != null ? Timestamp.fromDate(leftHomeTime!) : null,
      'arrivedHomeTime':
          arrivedHomeTime != null ? Timestamp.fromDate(arrivedHomeTime!) : null,
      'locationPointsCount': locationPointsCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get formattedMovingTime {
    if (totalMovingTimeMinutes < 60) {
      return '$totalMovingTimeMinutes min';
    }
    final hours = totalMovingTimeMinutes ~/ 60;
    final mins = totalMovingTimeMinutes % 60;
    return '${hours}h ${mins}m';
  }
}
