import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_finance/shared/models/wallet.dart';
import 'package:family_finance/features/wallet/providers/wallet_edit_provider.dart';
import 'package:family_finance/features/wallet/providers/wallet_provider.dart';

/// Danh sách màu có sẵn cho ví
const _presetColors = [
  'FF534AB7', // Purple
  'FF1D9E75', // Green  
  'FF378ADD', // Blue
  'FFFF6B6B', // Red
  'FFF59E0B', // Amber
  'FF8B5CF6', // Violet
];

/// [THÊM MỚI] Dialog sửa số dư ví
class EditBalanceDialog extends StatefulWidget {
  final WalletModel wallet;
  final String uid;
  final VoidCallback onSuccess;

  const EditBalanceDialog({
    required this.wallet,
    required this.uid,
    required this.onSuccess,
    super.key,
  });

  @override
  State<EditBalanceDialog> createState() => _EditBalanceDialogState();
}

class _EditBalanceDialogState extends State<EditBalanceDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.wallet.balance.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateBalance(WidgetRef ref) async {
    final amount = double.tryParse(_controller.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền không hợp lệ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(walletEditServiceProvider);
      await service.updateBalance(widget.uid, widget.wallet.id, amount);
      ref.invalidate(walletsProvider);
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
          title: const Text('Sửa số dư'),
          content: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Nhập số tiền mới'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            FilledButton(
              onPressed: _isLoading ? null : () => _updateBalance(ref),
              child: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}

/// [THÊM MỚI] Dialog đổi tên ví
class EditNameDialog extends StatefulWidget {
  final WalletModel wallet;
  final String uid;
  final VoidCallback onSuccess;

  const EditNameDialog({
    required this.wallet,
    required this.uid,
    required this.onSuccess,
    super.key,
  });

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.wallet.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateName(WidgetRef ref) async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên không được trống')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(walletEditServiceProvider);
      await service.updateName(widget.uid, widget.wallet.id, _controller.text);
      ref.invalidate(walletsProvider);
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
          title: const Text('Đổi tên ví'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Nhập tên mới'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            FilledButton(
              onPressed: _isLoading ? null : () => _updateName(ref),
              child: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}

/// [THÊM MỚI] Dialog xóa ví
class DeleteWalletDialog extends ConsumerStatefulWidget {
  final WalletModel wallet;
  final String uid;
  final VoidCallback onSuccess;

  const DeleteWalletDialog({
    required this.wallet,
    required this.uid,
    required this.onSuccess,
    super.key,
  });

  @override
  ConsumerState<DeleteWalletDialog> createState() => _DeleteWalletDialogState();
}

class _DeleteWalletDialogState extends ConsumerState<DeleteWalletDialog> {
  bool _isDeleting = false;

  Future<void> _deleteWallet() async {
    if (_isDeleting) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isDeleting = true);
    try {
      final service = ref.read(walletEditServiceProvider);
      await service.deleteWallet(widget.uid, widget.wallet.id);
      ref.invalidate(walletsProvider);
      if (!mounted) return;
      navigator.pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xóa ví'),
      content: Text('Bạn chắc chắn muốn xóa ví "${widget.wallet.name}" không? Không thể hoàn tác.'),
      actions: [
        TextButton(onPressed: _isDeleting ? null : () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _isDeleting ? null : _deleteWallet,
          child: _isDeleting
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Xóa'),
        ),
      ],
    );
  }
}

/// [THÊM MỚI] Dialog thêm ví mới
class AddWalletDialog extends StatefulWidget {
  final String uid;
  final VoidCallback onSuccess;

  const AddWalletDialog({
    required this.uid,
    required this.onSuccess,
    super.key,
  });

  @override
  State<AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends State<AddWalletDialog> {
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  String _selectedColor = _presetColors[0];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _createWallet(WidgetRef ref) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên ví không được trống')),
      );
      return;
    }

    final balance = double.tryParse(_balanceController.text) ?? 0;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(walletEditServiceProvider);
      await service.createWallet(
        uid: widget.uid,
        name: _nameController.text.trim(),
        balance: balance,
        colorHex: _selectedColor,
      );
      ref.invalidate(walletsProvider);
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
          title: const Text('Thêm ví mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tên ví', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Ví tiền mặt, Ngân hàng, ...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Số dư ban đầu', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _balanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Chọn màu', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _presetColors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(int.parse('0x$color')),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            FilledButton(
              onPressed: _isLoading ? null : () => _createWallet(ref),
              child: _isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }
}
