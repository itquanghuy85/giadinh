import 'package:cloud_firestore/cloud_firestore.dart';

/// Vị trí realtime của một thành viên gia đình.
/// Lưu tại Firestore: live_locations/{userId}
class LiveLocation {
  const LiveLocation({
    required this.userId,
    required this.familyId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.batteryLevel,
    required this.isMoving,
    required this.isOnline,
    required this.updatedAt,
    this.deviceModel = '',
    this.displayName = 'Thành viên',
    this.photoUrl,
  });

  final String userId;
  final String familyId;
  final double latitude;
  final double longitude;

  /// Độ chính xác GPS (mét)
  final double accuracy;

  /// Tốc độ di chuyển (m/s)
  final double speed;

  /// Hướng đi (0-360 độ)
  final double heading;

  /// Pin thiết bị (0-100, -1 nếu không lấy được)
  final int batteryLevel;

  final bool isMoving;
  final bool isOnline;
  final DateTime updatedAt;
  final String deviceModel;
  final String displayName;
  final String? photoUrl;

  factory LiveLocation.fromMap(String userId, Map<String, dynamic> map) {
    DateTime updatedAt;
    final raw = map['updatedAt'];
    if (raw is Timestamp) {
      updatedAt = raw.toDate();
    } else {
      updatedAt = DateTime.now();
    }

    return LiveLocation(
      userId: userId,
      familyId: map['familyId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      batteryLevel: (map['batteryLevel'] as num?)?.toInt() ?? -1,
      isMoving: map['isMoving'] as bool? ?? false,
      isOnline: map['isOnline'] as bool? ?? false,
      updatedAt: updatedAt,
      deviceModel: map['deviceModel'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Thành viên',
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'familyId': familyId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'batteryLevel': batteryLevel,
        'isMoving': isMoving,
        'isOnline': isOnline,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'deviceModel': deviceModel,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

  /// Vị trí được coi là cũ nếu không cập nhật trong 10 phút
  bool get isStale => DateTime.now().difference(updatedAt).inMinutes > 10;

  /// Chuỗi trạng thái online thân thiện
  String get onlineStatusText {
    if (!isOnline) return 'Offline';
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inSeconds < 60) return 'Vừa hoạt động';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  /// Chuỗi mô tả pin
  String get batteryText {
    if (batteryLevel < 0) return 'N/A';
    return '$batteryLevel%';
  }

  /// Màu pin
  bool get batteryLow => batteryLevel >= 0 && batteryLevel <= 20;
}
