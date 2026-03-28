import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../child/child_home_screen.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreed = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('join_family')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: AppTheme.accentColor,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  t('join_family_title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 8),

                Text(
                  t('join_family_desc'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // Family Code Input
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: t('enter_code'),
                    prefixIcon:
                        const Icon(Icons.vpn_key, color: AppTheme.accentColor),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return t('invalid_code');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Consent Checkbox
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: _agreed
                          ? AppTheme.accentColor
                          : AppTheme.dividerColor,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _agreed,
                    onChanged: (val) => setState(() => _agreed = val ?? false),
                    activeColor: AppTheme.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    title: Text(
                      t('consent_text'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),

                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    auth.error!,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 14,
                    ),
                  ),
                ],

                const Spacer(),

                GradientButton(
                  text: t('join_family'),
                  icon: Icons.arrow_forward,
                  isLoading: auth.isLoading,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D9A6), Color(0xFF00BFA5)],
                  ),
                  onPressed: _agreed ? () => _joinFamily(auth) : null,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _joinFamily(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await auth.setupAsChild(_codeController.text.trim().toUpperCase());

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ChildHomeScreen()),
        (route) => false,
      );
    }
  }
}
