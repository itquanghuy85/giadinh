import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_finance/shared/models/family_member.dart';
import 'package:family_finance/features/calendar/providers/event_edit_provider.dart';
import 'package:family_finance/features/calendar/providers/calendar_provider.dart';
import 'package:family_finance/shared/services/event_notification_handler.dart';
import 'package:intl/intl.dart';

/// [THÊM MỚI] Dialog thêm sự kiện lịch gia đình
class AddEventDialog extends StatefulWidget {
  final String familyId;
  final String uid;
  final List<FamilyMember> members;
  final VoidCallback onSuccess;

  const AddEventDialog({
    required this.familyId,
    required this.uid,
    required this.members,
    required this.onSuccess,
    super.key,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedAssignee = '';
  String _selectedRepeat = 'none';
  String _selectedEventType = 'regular';
  bool _hasReminder = true;
  int _reminderMinutes = 30;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    if (widget.members.isNotEmpty) {
      _selectedAssignee = widget.members[0].name;
    }
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
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _createEvent(WidgetRef ref) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên sự kiện không được trống')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final service = ref.read(eventEditServiceProvider);
      final event = await service.createEvent(
        familyId: widget.familyId,
        title: _titleController.text.trim(),
        assignee: _selectedAssignee,
        startAt: startAt,
        repeat: _selectedRepeat,
        colorHex: _getColorForEventType(_selectedEventType),
        eventType: _selectedEventType,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
        createdBy: widget.uid,
        hasReminder: _hasReminder,
        reminderMinutes: _reminderMinutes,
      );
      
      // [THÊM MỚI] Notify all members of new event
      if (event != null) {
        final creatorName = _selectedAssignee.isEmpty ? 'Quản lý' : _selectedAssignee;
        await EventNotificationHandler.notifyEventCreated(event, creatorName);
      }
      
      ref.invalidate(familyEventsProvider);
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

  String _getColorForEventType(String type) {
    switch (type) {
      case 'anniversary':
        return 'FFFF6B6B'; // Red
      case 'birthday':
        return 'FFF59E0B'; // Amber
      default:
        return 'FF534AB7'; // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Dialog(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thêm sự kiện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Tên sự kiện', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Vd: Đưa bé đi học',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Mô tả chi tiết (không bắt buộc)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Ngày & Giờ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                        onPressed: _selectDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTime.format(context)),
                        onPressed: _selectTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nhắc nhở', style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: _hasReminder,
                      onChanged: (value) => setState(() => _hasReminder = value),
                    ),
                  ],
                ),
                if (_hasReminder) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _reminderMinutes,
                    decoration: const InputDecoration(labelText: 'Thời gian nhắc'),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 phút trước')),
                      DropdownMenuItem(value: 10, child: Text('10 phút trước')),
                      DropdownMenuItem(value: 15, child: Text('15 phút trước')),
                      DropdownMenuItem(value: 30, child: Text('30 phút trước')),
                      DropdownMenuItem(value: 60, child: Text('1 tiếng trước')),
                      DropdownMenuItem(value: 1440, child: Text('1 ngày trước')),
                    ],
                    onChanged: (value) => setState(() => _reminderMinutes = value ?? 30),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Người thực hiện', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedAssignee.isEmpty ? null : _selectedAssignee,
                  isExpanded: true,
                  items: widget.members.map((m) => DropdownMenuItem(value: m.name, child: Text(m.name))).toList(),
                  onChanged: (value) => setState(() => _selectedAssignee = value ?? ''),
                ),
                const SizedBox(height: 12),
                const Text('Loại sự kiện', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedEventType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'regular', child: Text('Thường')),
                    DropdownMenuItem(value: 'anniversary', child: Text('Kỷ niệm')),
                    DropdownMenuItem(value: 'birthday', child: Text('Sinh nhật')),
                  ],
                  onChanged: (value) => setState(() => _selectedEventType = value ?? 'regular'),
                ),
                const SizedBox(height: 12),
                const Text('Lặp lại', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedRepeat,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('Không lặp')),
                    DropdownMenuItem(value: 'daily', child: Text('Hàng ngày')),
                    DropdownMenuItem(value: 'weekly', child: Text('Hàng tuần')),
                  ],
                  onChanged: (value) => setState(() => _selectedRepeat = value ?? 'none'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : () => _createEvent(ref),
                      child: _isLoading
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Tạo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
