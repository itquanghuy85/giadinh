import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:family_finance/features/family/providers/photo_provider.dart';

/// [THÊM MỚI] Dialog upload ảnh kỷ niệm
class PhotoUploadDialog extends StatefulWidget {
  final String familyId;
  final String uid;
  final VoidCallback onSuccess;

  const PhotoUploadDialog({
    required this.familyId,
    required this.uid,
    required this.onSuccess,
    super.key,
  });

  @override
  State<PhotoUploadDialog> createState() => _PhotoUploadDialogState();
}

class _PhotoUploadDialogState extends State<PhotoUploadDialog> {
  late TextEditingController _captionController;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp ảnh: $e')),
        );
      }
    }
  }

  Future<void> _uploadPhoto(WidgetRef ref) async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hoặc chụp ảnh')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(photoUploadServiceProvider);
      await service.uploadPhoto(
        familyId: widget.familyId,
        imageFile: _selectedImage!,
        uploadedBy: widget.uid,
        caption: _captionController.text.isEmpty ? null : _captionController.text.trim(),
      );

      ref.invalidate(familyPhotosProvider(widget.familyId));
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return AlertDialog(
          title: const Text('Thêm ảnh'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview
                if (_selectedImage != null) ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      child: const Text('Thay đổi ảnh'),
                    ),
                  ),
                ] else ...[
                  // Selection buttons
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Chụp ảnh'),
                          onPressed: _capturePhoto,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text('Chọn từ thư viện'),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Mô tả (không bắt buộc)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Kỷ niệm ngày cưới...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            FilledButton(
              onPressed: (_isLoading || _selectedImage == null) ? null : () => _uploadPhoto(ref),
              child: _isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Upload'),
            ),
          ],
        );
      },
    );
  }
}
