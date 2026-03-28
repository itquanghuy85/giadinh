import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6), Color(0xFFAB8DF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Language toggle at top
                Align(
                  alignment: Alignment.centerRight,
                  child: Consumer<LocaleProvider>(
                    builder: (context, localeProv, _) {
                      final isVi = localeProv.locale.languageCode == 'vi';
                      return GestureDetector(
                        onTap: () => localeProv.toggleLanguage(),
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                isVi ? '🇻🇳 Tiếng Việt' : '🇺🇸 English',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Spacer(flex: 2),

                // Logo / Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 64,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  t('sign_in_title'),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  t('sign_in_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 2),

                // Error message
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Google Sign-In Button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return _SignInButton(
                      icon: Icons.g_mobiledata,
                      iconSize: 28,
                      label: t('sign_in_google'),
                      isLoading: auth.isLoading,
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textPrimary,
                      onPressed: () => _handleGoogleSignIn(context),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Apple Sign-In Button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return _SignInButton(
                      icon: Icons.apple_rounded,
                      iconSize: 24,
                      label: t('sign_in_apple'),
                      isLoading: auth.isLoading,
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      onPressed: () => _handleAppleSignIn(context),
                    );
                  },
                ),

                const SizedBox(height: 16),

                Text(
                  t('sign_in_agree'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final success = await auth.signInWithGoogle();
    if (!context.mounted) return;
    if (!success && auth.error != null) {
      // Error is shown via Consumer above; no manual navigation needed.
      // AuthGate handles navigation on success.
    }
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final success = await auth.signInWithApple();
    if (!context.mounted) return;
    if (!success && auth.error != null) {
      // Error shown via Consumer; AuthGate handles navigation.
    }
  }
}

class _SignInButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final bool isLoading;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _SignInButton({
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.isLoading,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
