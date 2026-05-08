import 'dart:convert';
import 'package:family_finance/app/app.dart';
import 'package:family_finance/app/routes/app_routes.dart';
import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/scripts/clear_test_data.dart';
import 'package:family_finance/shared/models/app_user.dart';
import 'package:family_finance/shared/services/service_providers.dart';
import 'package:family_finance/shared/widgets/app_back_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _linkingGoogle = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = '${info.version}+${info.buildNumber}');
  }

  Future<void> _changePassword() async {
    final pwCtrl1 = TextEditingController();
    final pwCtrl2 = TextEditingController();
    final pwCtrl3 = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pwCtrl1,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pwCtrl2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pwCtrl3,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đổi')),
        ],
      ),
    );
    if (ok != true) return;
    if (pwCtrl2.text != pwCtrl3.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu xác nhận không khớp')));
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;
      final cred = EmailAuthProvider.credential(email: user.email!, password: pwCtrl1.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(pwCtrl2.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.code == 'wrong-password' ? 'Mật khẩu hiện tại không đúng' : 'Lỗi: ${e.message}')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final auth = ref.read(authControllerProvider);
    final uid = auth.user?.uid ?? '';
    final familyId = auth.profile?.familyId ?? '';
    final isAdmin = auth.profile?.role.isAdmin ?? false;

    if (isAdmin) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Bạn là Admin'),
          content: const Text('Xóa tài khoản sẽ giải tán gia đình. Tất cả thành viên sẽ bị ảnh hưởng. Bạn có chắc?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vẫn xóa'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final pwCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản', style: TextStyle(color: AppColors.expense)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập mật khẩu để xác nhận. Hành động không thể hoàn tác.'),
            const SizedBox(height: 12),
            TextField(
              controller: pwCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );
    if (confirm != true || uid.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;
      final cred = EmailAuthProvider.credential(email: user.email!, password: pwCtrl.text);
      await user.reauthenticateWithCredential(cred);

      // Xóa data Firestore
      final svc = ref.read(firestoreServiceProvider);
      final db = svc.db;
      final batch = db.batch();
      // Xóa wallets
      final wallets = await db.collection('users').doc(uid).collection('wallets').get();
      for (final d in wallets.docs) {
        batch.delete(d.reference);
      }
      // Xóa transactions
      final txs = await db.collection('users').doc(uid).collection('transactions').get();
      for (final d in txs.docs) {
        batch.delete(d.reference);
      }
      // Xóa khỏi family
      if (familyId.isNotEmpty) {
        batch.delete(db.collection('families').doc(familyId).collection('members').doc(uid));
      }
      batch.delete(db.collection('users').doc(uid));
      await batch.commit();

      // Xóa Auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.code == 'wrong-password' ? 'Mật khẩu không đúng' : 'Lỗi: ${e.message}')),
      );
    }
  }

  Future<void> _clearAllData() async {
    final uid = ref.read(authControllerProvider).user?.uid ?? '';
    if (uid.isEmpty) return;

    // Bước 1: Xác nhận
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Xóa dữ liệu & Reset app'),
        content: const Text(
          'Hành động này sẽ xóa toàn bộ ví và giao dịch của bạn. Không thể hoàn tác.\n\nBạn có chắc chắn?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    if (step1 != true) return;

    // Bước 2: Gõ "XÓA" để xác nhận
    final confirmCtrl = TextEditingController();
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận lần cuối', style: TextStyle(color: AppColors.expense)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gõ "XÓA" để xác nhận xóa toàn bộ dữ liệu:'),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(labelText: 'Gõ XÓA tại đây'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, confirmCtrl.text.trim() == 'XÓA'),
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
    if (step2 != true) return;

    try {
      await ClearTestData.clearAllUserData(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa toàn bộ dữ liệu thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e')),
      );
    }
  }

  Future<void> _backupData() async {    final uid = ref.read(authControllerProvider).user?.uid ?? '';
    if (uid.isEmpty) return;
    final svc = ref.read(firestoreServiceProvider);
    final db = svc.db;
    final wallets = await db.collection('users').doc(uid).collection('wallets').get();
    final txs    = await db.collection('users').doc(uid).collection('transactions').get();
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'uid': uid,
      'wallets': wallets.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      'transactions': txs.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
    };
    final json = JsonEncoder.withIndent('  ').convert(data);
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    await Share.share(
      json,
      subject: 'family_finance_backup_$dateStr.json',
    );
  }

  Future<void> _linkGoogleAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final linked = user.providerData.any((p) => p.providerId == 'google.com');
    if (linked) {
      final googleEmail = user.providerData
          .where((p) => p.providerId == 'google.com')
          .map((p) => p.email)
          .whereType<String>()
          .firstWhere((_) => true, orElse: () => user.email ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã liên kết: $googleEmail')),
      );
      return;
    }

    setState(() => _linkingGoogle = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await user.linkWithCredential(credential);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liên kết Google thành công.')));
      setState(() {});
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'credential-already-in-use' || e.code == 'email-already-in-use'
          ? 'Tài khoản Google này đã được dùng ở tài khoản khác.'
          : 'Liên kết Google thất bại: ${e.message ?? e.code}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _linkingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile   = authState.profile;
    final user      = authState.user;
    final linkedGoogle = FirebaseAuth.instance.currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        leading: const AppBackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // ── Tài khoản ─────────────────────────────────────
          _SectionHeader(label: 'Tài khoản'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      (profile?.displayName.isNotEmpty == true ? profile!.displayName[0] : 'U').toUpperCase(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.displayName ?? 'Thành viên',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                        Text('Vai trò: ${profile?.role.name ?? '-'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.lock_reset_outlined, size: 20),
                  title: const Text('Đổi mật khẩu'),
                  onTap: _changePassword,
                  trailing: const Icon(Icons.chevron_right, size: 18),
                ),
                const Divider(height: 1, indent: 48),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.link_outlined, size: 20),
                  title: const Text('Liên kết Google'),
                  subtitle: Text(linkedGoogle ? 'Đã liên kết Google' : 'Chưa liên kết',
                      style: const TextStyle(fontSize: 11)),
                  trailing: _linkingGoogle
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right, size: 18),
                  onTap: _linkingGoogle ? null : _linkGoogleAccount,
                ),
              ],
            ),
          ),

          // ── Hiển thị ──────────────────────────────────────
          const SizedBox(height: 12),
          _SectionHeader(label: 'Hiển thị'),
          Card(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.brightness_medium_outlined, size: 20),
              title: const Text('Giao diện'),
              trailing: DropdownButton<ThemeMode>(
                value: currentTheme,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.light,  child: Text('Sáng')),
                  DropdownMenuItem(value: ThemeMode.dark,   child: Text('Tối')),
                  DropdownMenuItem(value: ThemeMode.system, child: Text('Tự động')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  ref.read(themeModeProvider.notifier).state = v;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('themeMode', v.index);
                },
              ),
            ),
          ),

          // ── Dữ liệu ───────────────────────────────────────
          const SizedBox(height: 12),
          _SectionHeader(label: 'Dữ liệu'),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.backup_outlined, size: 20),
                  title: const Text('Sao lưu dữ liệu'),
                  subtitle: const Text('Xuất file JSON qua share sheet', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: _backupData,
                ),
              ],
            ),
          ),

          // ── Ứng dụng ──────────────────────────────────────
          const SizedBox(height: 12),
          _SectionHeader(label: 'Ứng dụng'),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.info_outline, size: 20),
                  title: const Text('Phiên bản'),
                  trailing: Text(_appVersion, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                const Divider(height: 1, indent: 48),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.description_outlined, size: 20),
                  title: const Text('Điều khoản sử dụng'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Điều khoản sử dụng (sẽ được cập nhật)')),
                  ),
                ),
                const Divider(height: 1, indent: 48),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.privacy_tip_outlined, size: 20),
                  title: const Text('Chính sách bảo mật'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chính sách bảo mật (sẽ được cập nhật)')),
                  ),
                ),
              ],
            ),
          ),

          // ── Nguy hiểm ─────────────────────────────────────
          const SizedBox(height: 20),
          if (ref.watch(authControllerProvider).profile?.role.isAdmin ?? false) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expense,
                  side: const BorderSide(color: AppColors.expense),
                ),
                onPressed: _clearAllData,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Xóa dữ liệu & Reset app'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.expense,
                side: const BorderSide(color: AppColors.expense),
              ),
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Xóa tài khoản'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
