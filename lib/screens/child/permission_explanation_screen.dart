import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../services/permission_service.dart';
import '../../widgets/common_widgets.dart';

class PermissionExplanationScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionExplanationScreen({
    super.key,
    required this.onPermissionsGranted,
  });

  @override
  State<PermissionExplanationScreen> createState() =>
      _PermissionExplanationScreenState();
}

class _PermissionExplanationScreenState
    extends State<PermissionExplanationScreen> {
  final PermissionService _permissionService = PermissionService();
  int _currentStep = 0;
  bool _locationGranted = false;
  bool _bgLocationGranted = false;
  bool _notificationGranted = false;

  List<_PermissionStep> _buildSteps(String Function(String, [List<String>?]) t) {
    return [
      _PermissionStep(
        icon: Icons.location_on,
        title: t('location_access'),
        description: t('location_access_desc'),
        detail: t('location_access_detail'),
        color: AppTheme.primaryColor,
      ),
      _PermissionStep(
        icon: Icons.location_searching,
        title: t('bg_location'),
        description: t('bg_location_desc'),
        detail: t('bg_location_detail'),
        color: AppTheme.accentColor,
      ),
      _PermissionStep(
        icon: Icons.notifications_active,
        title: t('notifications'),
        description: t('notifications_desc'),
        detail: t('notifications_detail'),
        color: AppTheme.warningColor,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _checkExistingPermissions();
  }

  Future<void> _checkExistingPermissions() async {
    final perms = await _permissionService.checkAllPermissions();
    setState(() {
      _locationGranted = perms['location'] ?? false;
      _bgLocationGranted = perms['backgroundLocation'] ?? false;
      _notificationGranted = perms['notification'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final steps = _buildSteps(t);
    final step = steps[_currentStep];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress
              Row(
                children: List.generate(
                  steps.length,
                  (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _currentStep
                            ? step.color
                            : AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(step.icon, size: 56, color: step.color),
              ),

              const SizedBox(height: 32),

              Text(
                step.title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                step.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Detail card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.05),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: step.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: step.color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.detail,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Grant Permission Button
              GradientButton(
                text: _getButtonText(),
                icon: Icons.check,
                gradient: LinearGradient(
                  colors: [step.color, step.color.withValues(alpha: 0.8)],
                ),
                onPressed: _handlePermission,
              ),

              const SizedBox(height: 12),

              if (_currentStep > 0)
                TextButton(
                  onPressed: () {
                    setState(() => _currentStep--);
                  },
                  child: Text(t('back')),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    final t = AppLocalizations.of(context).t;
    switch (_currentStep) {
      case 0:
        return _locationGranted ? t('already_granted') : t('allow_location');
      case 1:
        return _bgLocationGranted
            ? t('already_granted')
            : t('allow_bg_location');
      case 2:
        return _notificationGranted
            ? t('already_granted_continue')
            : t('allow_notifications');
      default:
        return t('continue_btn');
    }
  }

  Future<void> _handlePermission() async {
    switch (_currentStep) {
      case 0:
        if (!_locationGranted) {
          _locationGranted =
              await _permissionService.requestLocationPermission();
        }
        if (_locationGranted) {
          setState(() => _currentStep = 1);
        }
        break;
      case 1:
        if (!_bgLocationGranted) {
          _bgLocationGranted =
              await _permissionService.requestBackgroundLocationPermission();
        }
        if (_bgLocationGranted || _locationGranted) {
          setState(() => _currentStep = 2);
        }
        break;
      case 2:
        if (!_notificationGranted) {
          _notificationGranted =
              await _permissionService.requestNotificationPermission();
        }
        widget.onPermissionsGranted();
        break;
    }
  }
}

class _PermissionStep {
  final IconData icon;
  final String title;
  final String description;
  final String detail;
  final Color color;

  const _PermissionStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.detail,
    required this.color,
  });
}
