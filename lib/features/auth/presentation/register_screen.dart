import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/invite_code.dart';
import 'package:family_finance/shared/services/invite_code_service.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  bool _loading = false;
  int _step = 1;
  String _selectedFamilyRole = 'chồng';
  bool _joinByInvite = false;
  String? _error;
  InviteCode? _validatedInvite;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _goNextStep() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập họ tên.');
      return;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      setState(() => _error = 'Email không hợp lệ.');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Mật khẩu tối thiểu 6 ký tự.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Xác nhận mật khẩu chưa khớp.');
      return;
    }

    setState(() {
      _error = null;
      _step = 2;
    });
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _validateInvite() async {
    final code = _inviteCodeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Invite code phải gồm 6 ký tự.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final inviteService = InviteCodeService();
      final invite = await inviteService.validateInviteCode(code);
      if (invite == null) {
        setState(() => _error = 'Invite code không hợp lệ hoặc đã hết hạn.');
        return;
      }
      setState(() => _validatedInvite = invite);
    } catch (e) {
      setState(() => _error = 'Không thể kiểm tra invite code: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishRegister() async {
    if (_joinByInvite) {
      if (_validatedInvite == null) {
        setState(() => _error = 'Vui lòng kiểm tra invite code trước khi hoàn tất.');
        return;
      }
    } else {
      if (_familyNameController.text.trim().isEmpty) {
        setState(() => _error = 'Vui lòng nhập tên gia đình.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final credential = await authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Không lấy được uid.');

      final db = FirebaseFirestore.instance;
        final userRole = _joinByInvite ? 'manager' : 'admin';

      String familyId;
      if (_joinByInvite) {
        familyId = _validatedInvite!.familyId;
      } else {
        familyId = 'family_$uid';
      }

      await db.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': userRole,
        'familyId': familyId,
      }, SetOptions(merge: true));

      if (_joinByInvite) {
        await db.collection('families').doc(familyId).collection('members').doc(uid).set({
          'uid': uid,
          'name': _nameController.text.trim(),
          'role': 'manager',
          'balance': 0,
        }, SetOptions(merge: true));

        await InviteCodeService().redeemInviteCode(
          familyId: familyId,
          inviteCodeId: _validatedInvite!.id,
          userId: uid,
        );
      } else {
        await db.collection('families').doc(familyId).set({
          'name': _familyNameController.text.trim(),
          'createdBy': uid,
          'ownerUid': uid,
          'members': [uid],
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await db.collection('families').doc(familyId).collection('members').doc(uid).set({
          'uid': uid,
          'name': _nameController.text.trim(),
          'role': 'admin',
          'balance': 0,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Đăng ký thất bại: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Đăng ký tài khoản'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _step == 1 ? _buildStepOne() : _buildStepTwo(),
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bước 1 - Thông tin cá nhân', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Họ tên'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mật khẩu'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _loading ? null : _registerWithGoogle,
          icon: const Icon(Icons.account_circle_outlined),
          label: const Text('Đăng ký bằng Google'),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _goNextStep,
            child: const Text('Tiếp theo'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bước 2 - Thông tin gia đình', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        const Text('Bạn là ai trong gia đình?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _roleCard('chồng'),
            _roleCard('vợ'),
            _roleCard('bố'),
            _roleCard('mẹ'),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          value: _joinByInvite,
          onChanged: (v) => setState(() {
            _joinByInvite = v;
            _validatedInvite = null;
            _error = null;
          }),
          title: const Text('Tôi muốn tham gia gia đình có sẵn'),
        ),
        if (_joinByInvite) ...[
          TextField(
            controller: _inviteCodeController,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Invite code 6 số',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loading ? null : _validateInvite,
            child: const Text('Kiểm tra mã'),
          ),
          if (_validatedInvite != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Mã hợp lệ, có thể hoàn tất đăng ký.', style: TextStyle(color: Colors.green)),
            ),
        ] else ...[
          TextField(
            controller: _familyNameController,
            decoration: const InputDecoration(labelText: 'Tên gia đình bạn (vd: Gia đình Nguyễn)'),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => setState(() => _step = 1),
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _loading ? null : _finishRegister,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Hoàn tất'),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _roleCard(String role) {
    final selected = _selectedFamilyRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedFamilyRole = role),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.white,
        ),
        child: Text(
          role[0].toUpperCase() + role.substring(1),
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}
