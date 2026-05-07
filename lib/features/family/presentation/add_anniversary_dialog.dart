import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_finance/shared/models/family_member.dart';
import 'package:family_finance/shared/models/anniversary.dart';
import 'package:family_finance/features/family/providers/anniversary_provider.dart';
import 'package:family_finance/shared/services/anniversary_reminder_handler.dart';
import 'package:intl/intl.dart';

/// [THÊM MỚI] Dialog thêm ngày kỷ niệm mới
class AddAnniversaryDialog extends StatefulWidget {
  final String familyId;
  final String uid;
  final List<FamilyMember> members;
  final VoidCallback onSuccess;

  const AddAnniversaryDialog({
    required this.familyId,
    required this.uid,
    required this.members,
    required this.onSuccess,
    super.key,
  });

  @override
  State<AddAnniversaryDialog> createState() => _AddAnniversaryDialogState();
}

class _AddAnniversaryDialogState extends State<AddAnniversaryDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'custom'; // wedding, birthday, custom
  String? _selectedPersonUid;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _createAnniversary(WidgetRef ref) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên không được trống')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(anniversaryServiceProvider);
      await service.createAnniversary(
        familyId: widget.familyId,
        title: _titleController.text.trim(),
        date: _selectedDate,
        type: _selectedType,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
        personUid: _selectedPersonUid,
        createdBy: widget.uid,
      );
      
      // [THÊM MỚI] Schedule reminders for anniversary
      final anniversary = Anniversary(
        id: '', // ID sẽ được generate từ Firestore
        familyId: widget.familyId,
        title: _titleController.text.trim(),
        date: _selectedDate,
        type: _selectedType,
        isAnnual: true,
        createdBy: widget.uid,
        createdAt: DateTime.now(),
      );
      await AnniversaryReminderHandler.scheduleReminder(anniversary);
      await AnniversaryReminderHandler.notifyOnDay(anniversary);
      ref.invalidate(familyAnniversariesProvider(widget.familyId));
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
        return PopScope(
          canPop: !_isLoading,
          child: AlertDialog(
          title: const Text('Thêm kỷ niệm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loại', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'wedding', child: Text('Ngày cưới')),
                    DropdownMenuItem(value: 'birthday', child: Text('Sinh nhật')),
                    DropdownMenuItem(value: 'custom', child: Text('Khác')),
                  ],
                  onChanged: (value) => setState(() => _selectedType = value ?? 'custom'),
                ),
                const SizedBox(height: 12),
                const Text('Tên', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Vd: Ngày cưới, Sinh nhật Mẹ, ...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Ngày', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  onPressed: _selectDate,
                ),
                if (_selectedType == 'birthday') ...[
                  const SizedBox(height: 12),
                  const Text('Người', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedPersonUid,
                    isExpanded: true,
                    hint: const Text('Chọn thành viên'),
                    items: widget.members
                        .map((m) => DropdownMenuItem(value: m.uid, child: Text(m.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPersonUid = value),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Mô tả (không bắt buộc)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            FilledButton(
              onPressed: _isLoading ? null : () => _createAnniversary(ref),
              child: _isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Tạo'),
            ),
          ],
        ),
        );
      },
    );
  }
}
