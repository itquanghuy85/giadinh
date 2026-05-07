import 'package:family_finance/app/theme/app_colors.dart';
import 'package:family_finance/features/auth/providers/auth_provider.dart';
import 'package:family_finance/features/auth/presentation/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    // Hiển thị SnackBar khi có lỗi mới
    ref.listen(authControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        debugPrint('[LoginScreen] Auth error: ${next.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.expense,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.family_restroom, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 18),
                  Text('Family Finance', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              ref.read(authControllerProvider.notifier).signInWithEmailPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Đăng nhập Google'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            ),
                    child: const Text('Tạo tài khoản mới'),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(state.error!, style: const TextStyle(color: AppColors.expense)),
                  ],
                  const SizedBox(height: 20),
                  const Text('Vai trò: Ba (admin), Mẹ (quản lý), Con (giới hạn)'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
