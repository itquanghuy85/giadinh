import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:family_finance/firebase_options.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/shared/models/invite_code.dart';
import 'package:family_finance/shared/services/invite_code_service.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';

/// Provide InviteCodeService
final _inviteCodeServiceProvider = Provider((ref) => InviteCodeService());

/// [THÊM MỚI] Screen thêm thành viên mới vào gia đình
class AddMemberScreen extends ConsumerStatefulWidget {
  final String familyId;

  const AddMemberScreen({required this.familyId, super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _selectedRole = 'manager'; // manager hoặc child
  bool _createAccountMode = false;
  bool _isLoading = false;
  InviteCode? _generatedCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _generateInviteCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập email');
      return;
    }

    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Email không hợp lệ');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(_inviteCodeServiceProvider);
      final uid = ref.read(authControllerProvider).user?.uid ?? '';
      
      final code = await service.createInviteCode(
        familyId: widget.familyId,
        invitedEmail: email,
        role: _selectedRole,
        createdBy: uid,
      );

      setState(() => _generatedCode = code);
    } catch (e) {
      setState(() => _errorMessage = 'Tạo mã mời thất bại: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createMemberAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên thành viên');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Email không hợp lệ');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải từ 6 ký tự');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    FirebaseApp? secondaryApp;
    try {
      try {
        secondaryApp = Firebase.app('secondary-auth');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'secondary-auth',
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);

      final memberUid = credential.user?.uid;
      if (memberUid == null) throw Exception('Không tạo được user uid.');

      final db = FirebaseFirestore.instance;
      await db.collection('users').doc(memberUid).set({
        'name': name,
        'displayName': name,
        'email': email,
        'role': _selectedRole,
        'familyId': widget.familyId,
      }, SetOptions(merge: true));

      await db.collection('families').doc(widget.familyId).collection('members').doc(memberUid).set({
        'uid': memberUid,
        'name': name,
        'role': _selectedRole,
        'balance': 0,
      }, SetOptions(merge: true));

      await secondaryAuth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo tài khoản hộ thành công.')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = 'Tạo tài khoản thất bại: ${e.message ?? e.code}');
    } catch (e) {
      setState(() => _errorMessage = 'Tạo tài khoản thất bại: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm thành viên'),
        leading: const AppBackButton(),
      ),
      body: _generatedCode == null ? _buildForm() : _buildCodeDisplay(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('Gửi invite code')),
              ButtonSegment<bool>(value: true, label: Text('Tạo tài khoản hộ')),
            ],
            selected: {_createAccountMode},
            onSelectionChanged: (value) => setState(() => _createAccountMode = value.first),
          ),
          const SizedBox(height: 12),
          const Text('Tên thành viên', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Nhập tên',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Nhập email',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          if (_createAccountMode) ...[
            const Text('Mật khẩu tạm', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu cho người thân',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedRole,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: 'manager', child: Text('Chồng/Vợ (manager)')),
              DropdownMenuItem(value: 'child', child: Text('Con (child)')),
            ],
            onChanged: (value) => setState(() => _selectedRole = value ?? 'manager'),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_createAccountMode ? _createMemberAccount : _generateInviteCode),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_createAccountMode ? 'Tạo tài khoản hộ' : 'Tạo mã mời'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeDisplay() {
    final code = _generatedCode!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Mã mời được tạo thành công!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Chia sẻ mã này với:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(code.invitedEmail, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const Text('Mã mời:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  code.code,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hết hạn: ${code.expiresAt.day}/${code.expiresAt.month}/${code.expiresAt.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Copy to clipboard action
                final text = code.code;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mã mời: $text')),
                );
              },
              child: const Text('Sao chép mã'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại'),
            ),
          ),
        ],
      ),
    );
  }
}
