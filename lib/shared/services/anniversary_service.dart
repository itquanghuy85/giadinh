import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/shared/models/anniversary.dart';

/// [THÊM MỚI] Service quản lý ngày kỷ niệm gia đình
class AnniversaryService {
  AnniversaryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Tạo ngày kỷ niệm mới
  Future<void> createAnniversary({
    required String familyId,
    required String title,
    required DateTime date,
    required String type, // wedding, birthday, custom
    String? description,
    String? personUid,
    required String createdBy,
  }) async {
    if (familyId.isEmpty) throw Exception('familyId không hợp lệ — chưa tham gia gia đình');
    if (title.isEmpty) throw Exception('Tên kỷ niệm không được trống');
    try {
      await _db.collection('families').doc(familyId).collection('anniversaries').add({
        'familyId': familyId,
        'title': title,
        'date': Timestamp.fromDate(date),
        'type': type,
        'description': description,
        'personUid': personUid,
        'isAnnual': true,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Tạo kỷ niệm thất bại: $e');
    }
  }

  /// Stream danh sách kỷ niệm của gia đình
  Stream<List<Anniversary>> streamAnniversaries(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('anniversaries')
        .orderBy('date')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Anniversary.fromMap(doc.id, doc.data())).toList());
  }

  /// Xóa kỷ niệm
  Future<void> deleteAnniversary(String familyId, String anniversaryId) async {
    try {
      await _db
          .collection('families')
          .doc(familyId)
          .collection('anniversaries')
          .doc(anniversaryId)
          .delete();
    } catch (e) {
      throw Exception('Xóa kỷ niệm thất bại: $e');
    }
  }
}
