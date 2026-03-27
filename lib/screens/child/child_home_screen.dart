import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/sos_provider.dart';
import '../../services/permission_service.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import 'permission_explanation_screen.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen>
    with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final perms = await _permissionService.checkAllPermissions();
    setState(() {
      _permissionsGranted =
          perms['location'] == true && perms['notification'] == true;
    });

    if (_permissionsGranted) {
      _startTrackingIfNeeded();
    }
  }

  void _startTrackingIfNeeded() {
    final auth = context.read<AuthProvider>();
    final locationProv = context.read<LocationProvider>();
    if (auth.currentUser != null && !locationProv.isTracking) {
      locationProv.startTracking(auth.currentUser!.uid);
    }
  }

  Future<bool> _onWillPop() async {
    final t = AppLocalizations.of(context).t;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('exit_app')),
        content: Text(t('exit_app_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(t('exit')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locationProv = context.watch<LocationProvider>();
    final user = auth.currentUser;

    if (!_permissionsGranted) {
      return PermissionExplanationScreen(
        onPermissionsGranted: () {
          setState(() => _permissionsGranted = true);
          _startTrackingIfNeeded();
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.accentColor,
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
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${user?.displayName ?? 'there'}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          auth.currentFamily?.name ?? '',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'signout') {
                        await locationProv.stopTracking();
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
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'signout',
                        child: Row(
                          children: [
                            Icon(Icons.logout,
                                color: AppTheme.errorColor, size: 20),
                            SizedBox(width: 8),
                            Text('Sign Out'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: locationProv.isTracking
                      ? const LinearGradient(
                          colors: [Color(0xFF00D9A6), Color(0xFF00BFA5)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                        ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: (locationProv.isTracking
                              ? AppTheme.accentColor
                              : AppTheme.offlineColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      locationProv.isTracking
                          ? Icons.location_on
                          : Icons.location_off,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      locationProv.isTracking
                          ? 'Location Sharing Active'
                          : 'Location Sharing Paused',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationProv.isTracking
                          ? 'Your family can see your location'
                          : 'Your family cannot see your location',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (locationProv.isTracking) {
                            locationProv.stopTracking();
                          } else {
                            locationProv.startTracking(user!.uid);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: locationProv.isTracking
                              ? AppTheme.errorColor
                              : AppTheme.accentColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: Text(
                          locationProv.isTracking
                              ? 'Pause Sharing'
                              : 'Start Sharing',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info Row
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      title: 'Status',
                      value: locationProv.isTracking ? 'Active' : 'Paused',
                      icon: locationProv.isTracking
                          ? Icons.check_circle
                          : Icons.pause_circle,
                      iconColor: locationProv.isTracking
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      title: 'Battery',
                      value:
                          '${(locationProv.currentLocation?.batteryLevel ?? user?.batteryLevel ?? 100).toInt()}%',
                      icon: Icons.battery_full,
                      iconColor: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // SOS Button
              _SosButton(
                onPressed: () => _sendSos(context),
              ),

              const SizedBox(height: 16),

              Text(
                'Press and hold for emergency SOS',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _sendSos(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final sosProv = context.read<SosProvider>();
    final user = auth.currentUser!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.sosColor, size: 28),
            const SizedBox(width: 8),
            const Text('Send SOS?'),
          ],
        ),
        content: const Text(
          'This will immediately alert your parents with your current location. Use only in emergencies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sosColor,
            ),
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await sosProv.sendSosAlert(
        childId: user.uid,
        childName: user.displayName,
        familyId: user.familyId!,
      );

      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'SOS alert sent to your parents!'
                : 'Failed to send SOS. Try again.',
          ),
          backgroundColor:
              success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }
}

class _SosButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _SosButton({required this.onPressed});

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onLongPress: widget.onPressed,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.sosGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.sosColor.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber, color: Colors.white, size: 40),
                  SizedBox(height: 4),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
