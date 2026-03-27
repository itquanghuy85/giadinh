import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/sos_provider.dart';
import 'parent_dashboard_screen.dart';
import 'parent_map_screen.dart';
import 'parent_members_screen.dart';
import 'parent_geofence_screen.dart';
import 'reports_screen.dart';
import 'parent_settings_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;

  /// Tracks which tabs have been visited so they stay alive after first use.
  final Set<int> _loadedTabs = {0};

  static const _pageBuilders = <Widget Function()>[
    ParentDashboardScreen.new,
    ParentMapScreen.new,
    ParentMembersScreen.new,
    ParentGeofenceScreen.new,
    ReportsScreen.new,
    ParentSettingsScreen.new,
  ];

  @override
  void initState() {
    super.initState();
    // Defer heavy listener setup to after the first frame so the UI renders fast.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initListeners());
  }

  void _initListeners() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.currentUser?.familyId != null) {
      final familyId = auth.currentUser!.familyId!;
      final loc = context.read<LocationProvider>();
      final fam = context.read<FamilyProvider>();

      // Critical listeners first
      fam.listenToMembers(familyId);
      fam.listenToChildren(familyId);
      loc.listenToGeofences(familyId);
      loc.listenToFamilyEvents(familyId);
      context.read<SosProvider>().listenToAlerts(familyId);

      // Defer secondary listeners slightly so critical data loads first
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        loc.listenToDangerZones(familyId);
        loc.listenToScheduleConfig(familyId);
        loc.loadEventReminderSettings();
        loc.listenToSecurityEvents(familyId);
        loc.loadNightAlertSettings();
        loc.startDisconnectionMonitor();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: t('home'),
                    isActive: _currentIndex == 0,
                    onTap: () => _switchTab(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map,
                    label: t('map'),
                    isActive: _currentIndex == 1,
                    onTap: () => _switchTab(1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: t('members'),
                    isActive: _currentIndex == 2,
                    onTap: () => _switchTab(2),
                    badge: context.watch<SosProvider>().alerts.length,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.radar_outlined,
                    activeIcon: Icons.radar,
                    label: t('zones'),
                    isActive: _currentIndex == 3,
                    onTap: () => _switchTab(3),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.assessment_outlined,
                    activeIcon: Icons.assessment,
                    label: t('reports'),
                    isActive: _currentIndex == 4,
                    onTap: () => _switchTab(4),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: t('settings'),
                    isActive: _currentIndex == 5,
                    onTap: () => _switchTab(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  /// Lazy IndexedStack: only builds tabs that have been visited at least once.
  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: List.generate(_pageBuilders.length, (i) {
        if (_loadedTabs.contains(i)) {
          return _pageBuilders[i]();
        }
        return const SizedBox.shrink();
      }),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppTheme.primaryColor : AppTheme.textHint,
                  size: 22,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.sosColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryColor : AppTheme.textHint,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
