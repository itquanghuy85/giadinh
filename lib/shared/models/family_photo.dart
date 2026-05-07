/// Model đại diện cho ảnh kỷ niệm gia đình
class FamilyPhoto {
  final String id; // Document ID từ Firestore
  final String familyId;
  final String imageUrl; // URL từ Firebase Storage
  final String thumbnailUrl;
  final String? caption;
  final String uploadedBy; // uid người upload
  final DateTime uploadedAt;
  final DateTime? takenAt; // Ngày chụp ảnh

  FamilyPhoto({
    required this.id,
    required this.familyId,
    required this.imageUrl,
    this.thumbnailUrl = '',
    this.caption,
    required this.uploadedBy,
    required this.uploadedAt,
    this.takenAt,
  });

  Map<String, dynamic> toMap() => {
        'familyId': familyId,
        'imageUrl': imageUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'uploadedBy': uploadedBy,
        'uploadedAt': uploadedAt,
        'takenAt': takenAt,
      };

  static DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return (value as dynamic).toDate() as DateTime? ?? DateTime.now();
  }

  factory FamilyPhoto.fromMap(String id, Map<String, dynamic> map) {
    final imageUrl = map['imageUrl'] as String? ?? map['url'] as String? ?? map['downloadUrl'] as String? ?? '';
    final thumbnailUrl = map['thumbnailUrl'] as String? ?? map['thumbUrl'] as String? ?? imageUrl;
    return FamilyPhoto(
      id: id,
      familyId: map['familyId'] as String? ?? '',
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      caption: map['caption'] as String?,
      uploadedBy: map['uploadedBy'] as String? ?? '',
      uploadedAt: _toDate(map['uploadedAt']),
      takenAt: map['takenAt'] == null ? null : _toDate(map['takenAt']),
    );
  }
}
