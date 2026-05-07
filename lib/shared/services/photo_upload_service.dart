import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:family_finance/shared/models/family_photo.dart';

/// [THÊM MỚI] Service quản lý upload và lưu ảnh kỷ niệm
class PhotoUploadService {
  PhotoUploadService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  /// Upload ảnh và lưu metadata vào Firestore
  Future<FamilyPhoto> uploadPhoto({
    required String familyId,
    required File imageFile,
    required String uploadedBy,
    String? caption,
  }) async {
    if (familyId.isEmpty) throw Exception('familyId không hợp lệ');
    if (uploadedBy.isEmpty) throw Exception('Chưa đăng nhập');
    if (!await imageFile.exists()) throw Exception('File ảnh không tồn tại');
    try {
      // Compress ảnh
      final compressed = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${imageFile.absolute.path}_compressed.jpg',
        quality: 80,
        minHeight: 1080,
        minWidth: 1080,
      );

      if (compressed == null) throw Exception('Nén ảnh thất bại');

      // Upload lên Firebase Storage
      final photoId = const Uuid().v4();
      final storageRef = _storage.ref('families/$familyId/photos/$photoId.jpg');
      
      await storageRef.putFile(
        File(compressed.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await storageRef.getDownloadURL();

      // Lưu metadata vào Firestore
      final photoRef = _db
          .collection('families')
          .doc(familyId)
          .collection('photos')
          .doc(photoId);

      final photo = FamilyPhoto(
        id: photoId,
        imageUrl: downloadUrl,
        thumbnailUrl: downloadUrl,
        uploadedBy: uploadedBy,
        caption: caption,
        takenAt: DateTime.now(),
          uploadedAt: DateTime.now(),
        familyId: familyId,
      );

      await photoRef.set(photo.toMap());

      // Clean up compressed file
      await File(compressed.path).delete();

      return photo;
    } catch (e) {
      throw Exception('Upload ảnh thất bại: $e');
    }
  }

  /// Stream danh sách ảnh của gia đình (mới nhất trước)
  Stream<List<FamilyPhoto>> streamPhotos(String familyId, {int limit = 20}) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('photos')
        .orderBy('uploadedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FamilyPhoto.fromMap(doc.id, doc.data())).toList());
  }

  /// Xóa ảnh từ Storage và Firestore
  Future<void> deletePhoto(String familyId, String photoId) async {
    try {
      // Xóa từ Storage
      final storageRef = _storage.ref('families/$familyId/photos/$photoId.jpg');
      await storageRef.delete();

      // Xóa metadata từ Firestore
      await _db
          .collection('families')
          .doc(familyId)
          .collection('photos')
          .doc(photoId)
          .delete();
    } catch (e) {
      throw Exception('Xóa ảnh thất bại: $e');
    }
  }
}
