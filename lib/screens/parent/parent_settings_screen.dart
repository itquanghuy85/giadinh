import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../common/user_guide_screen.dart';
import 'danger_zone_screen.dart';
import 'schedule_screen.dart';
import 'family_calendar_screen.dart';
import 'security_alerts_screen.dart';
import 'night_alert_screen.dart';
import 'area_time_screen.dart';
import 'pdf_report_screen.dart';
import 'screen_time_screen.dart';
import 'event_reminder_settings_screen.dart';
import 'app_management_screen.dart';
import 'content_filter_screen.dart';
import 'transactions_screen.dart';

class ParentSettingsScreen extends StatelessWidget {
  const ParentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final family = auth.currentFamily;
    final localeProv = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                t('settings'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                          : null,
                      child: user?.photoUrl == null
                          ? Text(
                              user?.displayName.isNotEmpty == true
                                  ? user!.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? t('default_user'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t('parent'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Family Info
              _SettingsSection(
                title: t('family'),
                children: [
                  _SettingsTile(
                    icon: Icons.family_restroom,
                    title: family?.name ?? t('no_family'),
                    subtitle: t('family_name'),
                  ),
                  _SettingsTile(
                    icon: Icons.vpn_key,
                    title: family?.code ?? t('na'),
                    subtitle: t('family_code_label'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t('code_copied'))),
                        );
                      },
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.people,
                    title: t('family_members_count', ['${family?.members.length ?? 0}']),
                    subtitle: t('family_members'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Features
              _SettingsSection(
                title: t('zones'),
                children: [
                  _SettingsTile(
                    icon: Icons.warning_amber_rounded,
                    title: t('danger_zones'),
                    subtitle: t('danger_zones_desc'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DangerZoneScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.schedule,
                    title: t('smart_schedule'),
                    subtitle: t('schedule_desc'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScheduleScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.calendar_month,
                    title: t('family_calendar'),
                    subtitle: t('tap_add_event'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FamilyCalendarScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_active_rounded,
                    title: t('event_reminder_settings'),
                    subtitle: t('event_reminder_settings_sub'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EventReminderSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    title: t('security_alerts'),
                    subtitle: t('security_events_desc'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SecurityAlertsScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.nightlight_round,
                    title: t('night_alert'),
                    subtitle: t('night_alert_desc'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NightAlertScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.pie_chart_outline,
                    title: t('area_time_analysis'),
                    subtitle: t('time_by_area'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AreaTimeScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.picture_as_pdf,
                    title: t('pdf_report'),
                    subtitle: t('pdf_report_desc'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PdfReportScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.timer,
                    title: t('screen_time'),
                    subtitle: t('screen_time_desc'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScreenTimeScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.apps_rounded,
                    title: t('app_management'),
                    subtitle: t('app_management_desc'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.shield_rounded,
                    title: t('content_filter'),
                    subtitle: t('content_filter_desc'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContentFilterScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.account_balance_wallet,
                    title: t('transactions'),
                    subtitle: t('financial_report'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // App Settings
              _SettingsSection(
                title: t('app'),
                children: [
                  _SettingsTile(
                    icon: Icons.language,
                    title: t('language'),
                    subtitle: localeProv.locale.languageCode == 'en'
                        ? t('english')
                        : t('vietnamese'),
                    trailing: Switch(
                      value: localeProv.locale.languageCode == 'vi',
                      activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                      activeThumbColor: AppTheme.primaryColor,
                      onChanged: (_) => localeProv.toggleLanguage(),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: t('privacy_policy'),
                    subtitle: t('privacy_policy_sub'),
                    onTap: () => launchUrl(
                      Uri.parse('https://family-safety-app.web.app/privacy'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline,
                    title: t('user_guide'),
                    subtitle: t('user_guide_subtitle'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserGuideScreen(),
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: t('about'),
                    subtitle: t('version'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Delete Account
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(t('delete_account')),
                        content: Text(t('delete_account_confirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(t('cancel')),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                            ),
                            child: Text(t('delete')),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t('deleting_account'))),
                        );
                        await auth.deleteAccountAndData();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${t('error')}: $e'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever,
                      color: AppTheme.errorColor),
                  label: Text(
                    t('delete_data'),
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Sign Out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(t('sign_out')),
                        content: Text(t('sign_out_confirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(t('cancel')),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                            ),
                            child: Text(t('sign_out')),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                  label: Text(
                    t('sign_out'),
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right,
                  color: AppTheme.textHint, size: 20)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
