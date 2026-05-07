import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Màn nhập mã mời 6 chữ số để tham gia gia đình
class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  // 6 ô chữ số riêng biệt
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focuses = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _join() async {
    final code = _code;
    if (code.length < 6) {
      setState(() => _error = 'Vui lòng nhập đủ 6 chữ số');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final svc = ref.read(firestoreServiceProvider);
      final data = await svc.validateInviteCode(code);
      if (data == null) {
        setState(() => _error = 'Mã không hợp lệ hoặc đã hết hạn. Nhờ admin tạo mã mới.');
        return;
      }
      final auth = ref.read(authControllerProvider);
      final uid = auth.user?.uid ?? '';
      final displayName = auth.profile?.displayName ?? 'Thành viên';
      final email = auth.user?.email ?? '';
      final familyId = data['familyId'] as String? ?? '';
      final role = data['role'] as String? ?? 'child';
      if (familyId.isEmpty || uid.isEmpty) {
        setState(() => _error = 'Không thể xác định gia đình. Thử lại sau.');
        return;
      }
      await svc.joinFamily(
        familyId: familyId,
        uid: uid,
        displayName: displayName,
        email: email,
        role: role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tham gia gia đình thành công! 🎉')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Nhập mã mời'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_add, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Nhập mã mời 6 chữ số',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhờ admin của gia đình tạo mã mời và chia sẻ cho bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              // OTP-style 6 boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 44, height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _focuses[i].hasFocus ? AppColors.primary : AppColors.border,
                        width: _focuses[i].hasFocus ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.surface,
                    ),
                    child: TextField(
                      controller: _ctrls[i],
                      focusNode: _focuses[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 5) {
                          _focuses[i + 1].requestFocus();
                        } else if (v.isEmpty && i > 0) {
                          _focuses[i - 1].requestFocus();
                        }
                        setState(() {});
                      },
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.expense, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _join,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Tham gia gia đình', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
