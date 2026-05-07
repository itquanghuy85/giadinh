/// Model đại diện cho ngày kỷ niệm gia đình
class Anniversary {
  final String id; // Document ID từ Firestore
  final String familyId;
  final String title; // Tên kỷ niệm (Ngày cưới, Sinh nhật...)
  final DateTime date; // Ngày kỷ niệm (lưu toàn bộ ngày để so sánh)
  final String type; // 'wedding', 'birthday', 'custom'
  final String? description;
  final String? personUid; // Người liên quan (nếu sinh nhật)
  final bool isAnnual; // Lặp hàng năm
  final String createdBy;
  final DateTime createdAt;

  Anniversary({
    required this.id,
    required this.familyId,
    required this.title,
    required this.date,
    required this.type,
    this.description,
    this.personUid,
    required this.isAnnual,
    required this.createdBy,
    required this.createdAt,
  });

  /// Số ngày còn lại đến kỷ niệm tiếp theo
  int daysUntil() {
    final now = DateTime.now();
    final nextDate = DateTime(now.year, date.month, date.day);
    
    if (nextDate.isBefore(now)) {
      return DateTime(now.year + 1, date.month, date.day).difference(now).inDays;
    }
    return nextDate.difference(now).inDays;
  }

  Map<String, dynamic> toMap() => {
        'familyId': familyId,
        'title': title,
        'date': date,
        'type': type,
        'description': description,
        'personUid': personUid,
        'isAnnual': isAnnual,
        'createdBy': createdBy,
        'createdAt': createdAt,
      };

  factory Anniversary.fromMap(String id, Map<String, dynamic> map) {
    return Anniversary(
      id: id,
      familyId: map['familyId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      date: (map['date'] as dynamic)?.toDate() ?? DateTime.now(),
      type: map['type'] as String? ?? 'custom',
      description: map['description'] as String?,
      personUid: map['personUid'] as String?,
      isAnnual: map['isAnnual'] as bool? ?? true,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
